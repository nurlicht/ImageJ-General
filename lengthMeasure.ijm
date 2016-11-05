var colorChannelArray = newArray("RGB", "G", "RG", "GB");

macro "Main" {
	Initialize();
	allParams = initializeAllParams();
	allParams = loadImage(allParams);
	allParams = getUserSettings(allParams);
	allParams = applyUserSettings(allParams);
	allParams = measureCilia(allParams);
}

function applyUserSettings(allParams) {
	imageTitle = "" + allParams[1];						//1. imageTitle
	nChannels = parseInt("" + allParams[2]);			//2. nChannels
	ciliaChannelIndex = parseInt("" + allParams[4]);	//4. ciliaChannelIndex
	ciliaRoiWidth = parseInt("" + allParams[5]);		//5. ciliaRoiWidth
	zoomPercent = parseInt("" + allParams[10]);			//10. zoomPercent
	medianFilterRadius = parseInt("" + allParams[11]);
	colorChannelCode = parseInt("" + allParams[12]);	//12. colorChannelCode: 0/1/2/3:RGB/G/RG/GB

	if (medianFilterRadius > 0) {
		showStatus("Median Filtering ...");
		selectWindow_(imageTitle);
		run("Median...", "radius=" + medianFilterRadius + " stack");
		showStatus("Median filtering completed.");
	}

	//colorChannelArray = newArray("RGB", "G", "RG", "GB");
	if (nChannels > 1) {
		Stack.setDisplayMode("composite");
		if (colorChannelCode == 0) {
		} else if (colorChannelCode == 1) {
			Stack.setDisplayMode("color");
			Stack.setPosition(ciliaChannelIndex, 1, 1);
		} else if (colorChannelCode == 2) {
			Stack.setActiveChannels("110");
		} else if (colorChannelCode == 3) {
			Stack.setActiveChannels("011");
		}
	}
	return allParams;
}

function getUserSettings(allParams) {
	ciliaChannelIndex = parseInt("" + allParams[4]);	//4. ciliaChannelIndex
	ciliaRoiWidth = parseInt("" + allParams[5]);		//5. ciliaRoiWidth
	zoomPercent = parseInt("" + allParams[10]);			//10. zoomPercent
	medianFilterRadius = parseInt("" + allParams[11]);
	colorChannelCode = parseInt("" + allParams[12]);	//12. colorChannelCode: 0/1/2/3:RGB/G/RG/GB

	Dialog.create("Parameters used in Cilia detection");
	Dialog.addNumber("Cilia Channel", ciliaChannelIndex);
	Dialog.addNumber("Median Filter Radius", medianFilterRadius);
	Dialog.addNumber("ROI Width", ciliaRoiWidth);
	Dialog.addNumber("Zoom Percent (ROI Image)", zoomPercent);
	Dialog.addRadioButtonGroup("Color", colorChannelArray, 1, (lengthOf(colorChannelArray)), colorChannelArray[0]);	
	Dialog.show;
	ciliaChannelIndex = Dialog.getNumber();
	medianFilterRadius = Dialog.getNumber();
	ciliaRoiWidth = Dialog.getNumber();
	zoomPercent = Dialog.getNumber();
	selectedColor = Dialog.getRadioButton();

	for (cntr = 0; cntr < lengthOf(colorChannelArray); cntr++) {
		if (selectedColor == colorChannelArray[cntr]) {
			colorChannelCode = cntr;
		}
	}
	
	allParams[4] = "" + ciliaChannelIndex;
	allParams[11] = "" + medianFilterRadius;
	allParams[5] = "" + ciliaRoiWidth;
	allParams[10] = "" + zoomPercent;
	allParams[12] = "" + colorChannelCode;
	
	return allParams;
}

function measureCilia(allParams) {
	imageTitle = "" + allParams[1];						//1. imageTitle
	nChannels = parseInt("" + allParams[2]);			//2. nChannels
	nFrames = parseInt("" + allParams[3]);				//3. nFrames
	ciliaChannelIndex = parseInt("" + allParams[4]);	//4. ciliaChannelIndex
	ciliaRoiWidth = parseInt("" + allParams[5]);		//5. ciliaRoiWidth
	ciliaRoiTitle = "" + allParams[6];					//6. ciliaRoiTitle
	ciliaRoiSkeletonTitle = "" + allParams[7];			//7. ciliaRoiSkeletonTitle
	ciliaRoiDilatedTitle = "" + allParams[8];			//8. ciliaRoiDilatedTitle
	ciliaRoiCombinedTitle = "" + allParams[9];			//9. ciliaRoiCombinedTitle
	zoomPercent = parseInt("" + allParams[10]);			//10. zoomPercent

	Offset = floor(ciliaRoiWidth / 2);
	if (nChannels > 1) {
		Stack.setPosition(ciliaChannelIndex, 1, 1);
	} else {
		Stack.setPosition(1, 1, 1);
	}
	
	continueFlag = true;
	while (continueFlag) {
		//Point specification
		XYShiftCtrl = getPoint(imageTitle);
		
		//Closure of the last ROI image, if any
		close_(ciliaRoiCombinedTitle);

		if (XYShiftCtrl[3] > 0) {
			currentLength = getResult("Estimated Length", nResults -1);
			wait(10);
			setResult("Estimated Length", nResults - 1, - currentLength);
			updateResults();
		} else {
			//New ROI definition
			selectWindow_(imageTitle);
			makeRectangle(XYShiftCtrl[0] - Offset, XYShiftCtrl[1] - Offset, ciliaRoiWidth, ciliaRoiWidth);
			wait(1);		
			
			//Duplication
			setBatchMode(true);
			nImages_ = nImages;
			run("Duplicate...", "title=[" + ciliaRoiTitle + "]");
			while(nImages_ == nImages) {
			}
			selectWindow_(ciliaRoiTitle);
			Stack.getDimensions(width_, height_, channels_, slices_, frames_);
			if (channels_ > 1) {
				run("Split Channels");
				while (isOpen(ciliaRoiTitle)) {
				}
				for (cntr = 1; cntr <= channels_; cntr++) {
					while (!isOpen("C" + cntr + "-" + ciliaRoiTitle)) {
					}
					if (cntr != ciliaChannelIndex) {
						close_("C" + cntr + "-" + ciliaRoiTitle);
					} else {
						rename_("C" + cntr + "-" + ciliaRoiTitle, ciliaRoiTitle);
					}
				}
			}
	
			//Core of the code ...
	
			//Generate the Skeletonized image
			selectWindow_(ciliaRoiTitle);
			nImages_ = nImages;
			run("Duplicate...", "title=[" + ciliaRoiSkeletonTitle + "]");
			while(nImages_ == nImages) {
			}
			setAutoThreshold("Default dark");
			run("Convert to Mask");
			selectWindow_(ciliaRoiSkeletonTitle);
			selectWindow_(ciliaRoiSkeletonTitle);
			while (!is("binary")) {
				selectWindow_(ciliaRoiSkeletonTitle);
			}
			//run("Create Mask");
			resetThreshold();
			getThreshold(lower, upper);
			while (pow(lower + 1, 2) + pow(upper + 1, 2) > 0) {
				getThreshold(lower, upper);
			}
			run("Skeletonize");
	
			//Generate the Dilated image
			selectWindow_(ciliaRoiSkeletonTitle);
			nImages_ = nImages;
			run("Duplicate...", "title=[" + ciliaRoiDilatedTitle + "]");
			while(nImages_ == nImages) {
			}
			run("Dilate");
	
			if (!startsWith(getInfo("os.name"), "Windows")) {
				run("Invert LUT");
			}
			
			setAutoThreshold("Default dark");
			nResults_ = nResults;
			run("Measure");
			resetThreshold();
			while (nResults_ == nResults) {
			}
			setResult("Estimated Length", nResults - 1, getResult("Area", nResults -1) / 3 - 0);
			updateResults();
			
			//Combine all three images of Roi/RoiSkeletonize/RoiDialate
			selectWindow_(ciliaRoiTitle);
			run("8-bit");
			
			nImages_ = nImages;
			run("Combine...", "stack1=[" + ciliaRoiTitle + "] stack2=[" + ciliaRoiSkeletonTitle + "]");
			while (nImages_ == nImages) {
			}
			nImages_ = nImages;
			run("Combine...", "stack1=[" + getTitle() + "] stack2=[" + ciliaRoiDilatedTitle + "]");
			while (nImages_ == nImages) {
			}
			rename_(getTitle(), ciliaRoiCombinedTitle);
			
			//Select the Results Table
			setBatchMode("exit and display");
			selectWindow("Results");
			selectWindow(ciliaRoiCombinedTitle);
	
			//Zooming in
			selectWindow_(ciliaRoiCombinedTitle);
			run("Set... ", "zoom=" + zoomPercent + " x=" + (Offset + ciliaRoiWidth) + " y=" + Offset);
	
			//Checking for termination
			continueFlag = (XYShiftCtrl[2] == 0) && (nImages > 0);
		}
	}
	return allParams;
}

function getPoint(imageTitle) {
  flags = 0;
  x2 = -1;
  y2 = -1;
  flags2 = -1;
  shift = 1;
  ctrl = 2;
  leftButton = 16;
  msDebounceTime = 20;
  XYShiftCtrl = newArray(4);

  selectWindow_(imageTitle);
  run("Select None");

  selectWindow_(imageTitle);
  while ((flags & leftButton) == false) {
      //selectWindow_(imageTitle);
      getCursorLoc(x, y, z, flags);
  }
  XYShiftCtrl[0] = x;
  XYShiftCtrl[1] = y;
  XYShiftCtrl[2] = (flags & shift);
  XYShiftCtrl[3] = (flags & ctrl);
  wait(msDebounceTime);
  selectWindow_(imageTitle);
  while ((flags & leftButton) == true) {
      //selectWindow_(imageTitle);
      getCursorLoc(x, y, z, flags);
  }
  wait(msDebounceTime);
  return XYShiftCtrl;
}

function loadImage(allParams) {
	imagePath = File.openDialog("Please select the Hyperstack of Cilia.");
	showStatus("Loading the hyperstack ...");
	imageTitle = openPath(imagePath);
	showStatus("");
	rename_(imageTitle, "" + allParams[1]);
	imageTitle = getTitle();
	Stack.getDimensions(width, height, channels, slices, frames);

	if (slices > 1) {
		if (frames == 1) {
			frames = slices;
		} else {
			print("Performing Max-Intensity projection on " + slices + " frames");
			waitForUser("Performing Max-Intensity projection on " + slices + " frames");
			wait(1);
			maxProjStackTitle = maxZProj(imageTitle);
			close_(imageTitle);
			rename_(maxProjStackTitle, imageTitle);
		}
		slices_ = 1;
		selectWindow_(imageTitle);
		Stack.setDimensions(channels, slices_, frames);
	}
	
	selectWindow_(imageTitle);
	Stack.getDimensions(width, height, channels, slices, frames);
	if (channels > 1) {
		Stack.setDisplayMode("composite");
	}
	allParams[0] = "" + imagePath;	//0. imagePath
	allParams[1] = "" + imageTitle;	//1. imageTitle
	allParams[2] = "" + channels;	//2. nChannels
	allParams[3] = "" + frames;		//3. nFrames
	
	return allParams;
}

function maxZProj(stackTitle) {
	selectWindow_(stackTitle);
	nImages_ = nImages;
	run("Z Project...", "projection=[Max Intensity]");
	while (nImages_ == nImages) {
	}
	return getTitle();
}

function close_(imageTitle) {
	if (isOpen(imageTitle)) {
		close(imageTitle);
	}
	while (isOpen(imageTitle)) {
	}
}

function rename_(oldTitle, newTitle) {
	while (isOpen(newTitle)) {
	}
	selectWindow_(oldTitle);
	rename(newTitle);
	while (!isOpen(newTitle)) {
	}
	selectWindow_(newTitle);
}

function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while (getTitle != imageTitle) {
	}
}

function openPath(imagePath) {
	nImages_ = nImages;
	open(imagePath);
	while (nImages_ == nImages) {
	}
	return getTitle();
}

function initializeAllParams() {
	nAllParamsMax = 20;
	allParams = newArray(nAllParamsMax);
	Cntr = 0;

	allParams[Cntr++] = "" + "";					//0. imagePath
	allParams[Cntr++] = "" + "Loaded_Image";		//1. imageTitle
	allParams[Cntr++] = "" + 0;						//2. nChannels
	allParams[Cntr++] = "" + 0;						//3. nFrames
	allParams[Cntr++] = "" + 2;						//4. ciliaChannelIndex
	allParams[Cntr++] = "" + 50;					//5. ciliaRoiWidth
	allParams[Cntr++] = "" + "Cilia_Roi";			//6. ciliaRoiTitle
	allParams[Cntr++] = "" + "Cilia_Roi_Skeleton";	//7. ciliaRoiSkeletonTitle
	allParams[Cntr++] = "" + "Cilia_Roi_Dilated";	//8. ciliaRoiDilatedTitle
	allParams[Cntr++] = "" + "Cilia_Roi_Combined";	//9. ciliaRoiCombinedTitle
	allParams[Cntr++] = "" + 400;					//10. zoomPercent
	allParams[Cntr++] = "" + 2;						//11. medianFilterRadius
	allParams[Cntr++] = "" + 1;						//12. colorChannelCode: 0/1/2/3:RGB/G/RG/GB
	
	allParams = Array.slice(allParams, 0, Cntr);
	return allParams;
}

function Initialize() {
	closeAllImages();
	clearResultsTable();
	clearROIManager();
	closeAllUniqueWindows();
	setAllOptions();
}

function clearResultsTable() {
	run("Clear Results");
	updateResults();
}

function closeAllImages() {
	setBatchMode("exit and display");
	run("Close All");
	while (nImages > 0) {
	}
	wait(1);
}

function clearROIManager() {
	if (roiManager("count") > 0) {
		roiManager("Deselect");
		roiManager("Delete");		
	}
	while (roiManager("count") != 0) {
	}
	wait(1);
}

function closeAllUniqueWindows() {
	wait(1);
	list = getList("window.titles");
	listLength = list.length;
	if (listLength > 0) {
		showStatus("Closing all open windows ...");
		for (i = 0; i < listLength; i++) {
			selectWindow(list[i]);
			run("Close");
			wait(200);
			while (isOpen(list[i])) {
			}
		}	
		showStatus("");
	}
	wait(1);
}

function setAllOptions() {
	tableFileExtension = "txt";
	run("Input/Output...", "jpeg=85 gif=-1 file=" + tableFileExtension + " copy_column save_column");
	run("Set Measurements...", "area limit redirect=None decimal=2");
	run("Colors...", "foreground=white background=black selection=cyan");	
	run("Overlay Options...", "stroke=none width=0 fill=none set");
	wait(1);
}
