macro "Main" {
	Initialize();
  	print("\\Clear");
	allParams = initializeAllParams();
	allParams = getTimeSeries(allParams);
	allParams = apply3DMedianFilter(allParams);
	allParams = apply3DMeanFilter(allParams);
	allParams = getWekaThresholds(allParams);
	allParams = apply3DMedianFilterWeka(allParams);
	allParams = setThresholdValues(allParams);
	//allParams = initializeMaskHyperstack(allParams);
	allParams = getMaskHyperstack(allParams);
	allParams = superImposeOriginalAndMask(allParams);
	allParams = superImposeFilteredAndMask(allParams);
	
	//allParams = extractInnerObject(allParams);
	run("Synchronize Windows");
	run("Animation Options...", "speed=1 first=1 last=" + (nSlices));
}

function superImposeOriginalAndMask(allParams) {
	image1 = allParams[1];
	image2 = allParams[24];
	nImages_ = nImages;
	run("Merge Channels...", "c1=[" + image1 + "] c2=[" + image2 + "] create keep");
	while (nImages == nImages_) {
	}
	Stack.setDisplayMode("composite");
	setSlice(floor(nSlices / 2));
	rename_(getTitle(), "Original - Cell");
	run("Set... ", "zoom=200 x=" + (floor(getWidth() / 2)) + " y=" + (floor(getHeight() / 2)));
	
	allParams[25] = "" + getTitle();
	return allParams;
}

function superImposeFilteredAndMask(allParams) {
	image1 = allParams[14];
	image2 = allParams[24];
	nImages_ = nImages;
	run("Merge Channels...", "c1=[" + image1 + "] c2=[" + image2 + "] create keep");
	while (nImages == nImages_) {
	}
	Stack.setDisplayMode("composite");
	setSlice(floor(nSlices / 2));
	rename_(getTitle(), "Filtered - Cell");
	run("Set... ", "zoom=200 x=" + (floor(getWidth() / 2)) + " y=" + (floor(getHeight() / 2)));
	
	allParams[26] = "" + getTitle();
	return allParams;
}

function getWekaThresholds(allParams) {
	originalImageTitle = getTitle();
	typeOf3DFilter = allParams[27];
	
	selectWindow_(imageTitle);
	hyperStackToStack(allParams);
	if (typeOf3DFilter == "3D-stack") {
		nImages_ = nImages;
		run("3D Fast Filters","filter=Median radius_x_pix=" + nMFX + " radius_y_pix=" + nMFY + " radius_z_pix=" + nMFZ + " Nb_cpus=12");
		while (nImages == nImages_) {
		}
	} else if (typeOf3DFilter == "2D") {
		copyImageTitle = duplicateCurrentStack();
		rename_(copyImageTitle, "2D Median");
		run("Median...", "radius=5 stack");
	}






	
	selectWindow_(originalImageTitle);
	run("Enhance Contrast", "saturated=0.0");

	selectWindow_(originalImageTitle);
	hyperStackToStack(allParams);
	run("Trainable Weka Segmentation");
	waitForUser("Please select the LOW- and HIGH-intensities (CLASSES 1 and 2); THEN press OK");
	wait(1);

	call("trainableSegmentation.Weka_Segmentation.trainClassifier");
	nImages_ = nImages;
	call("trainableSegmentation.Weka_Segmentation.getProbability");
	while (nImages == nImages_) {
	}
	wekaMask = getTitle();

	Slices_ = nSlices;
	nSlicesHalf = nSlices / 2;
	selectWindow_(wekaMask);
	run("Slice Remover", "first=2 last=" + Slices_ + " increment=2");
	while (nSlices != nSlicesHalf) {
	}
	stackToHyperStack(allParams);
	selectWindow_(wekaMask);
	//run("8-bit");
	run("Enhance Contrast", "saturated=0.0");
	allParams[23] = wekaMask;

	selectWindow_(originalImageTitle);
	stackToHyperStack(allParams);

	closeWindowStartString("Trainable Weka Segmentation");

	return allParams;
}

function extractInnerObject(allParams) {
	imageTitle = allParams[14];
	nROIs = roiManager("count");

	if (nROIs > 0) {
		allROIs = newArray(nROIs);
		for (cntr = 0; cntr < nROIs; cntr++) {
			allROIs[cntr] = cntr;
		}
		extractedImageTitle = "Extracted cell {" + imageTitle + "}";
		setBatchMode(true);
		selectWindow_(imageTitle);
		roiManager("select", allROIs);
		nImages_ = nImages;
		selectWindow_(imageTitle);
		run("Duplicate...", "title=[" + extractedImageTitle + "] duplicate");
		while (nImages == nImages_) {
		}
		extractedImageTitle = getTitle();
		setBatchMode("exit and display");
		setBatchMode(false);
		allParams[22] = extractedImageTitle;
	}

	return allParams;
}

function getMaskHyperstack(allParams) {
	minArea = allParams[18];
	maxArea = allParams[19];
	minCircularity = allParams[20];
	maxCircularity = allParams[21];
	
	run("Analyze Particles...", "size=" + minArea + "-" + maxArea + " pixel circularity=" + minCircularity + 
		"-" + maxCircularity + " show=Outlines display exclude clear add in_situ stack");
	roiManager("Show All without labels");
	roiManager("Show None");
	return allParams;
}

function initializeMaskHyperstack(allParams) {
	imageTitle = allParams[14];
	lower = parseFloat(allParams[15]);
	maskTitle = "Mask {" + imageTitle + "}";

	selectWindow_(imageTitle);
	resetThreshold();
	nImages_ = nImages;
	run("Duplicate...", "title=[" + maskTitle + "] duplicate");
	while (nImages == nImages_) {
	}
	selectWindow_(maskTitle);
	run("Macro...", "code=[v = 255 * (v < " + lower + ")] stack");

	allParams[17] = maskTitle;
	return allParams;
}

function setThresholdValues(allParams) {
	imageTitle = allParams[24];
	selectWindow_(imageTitle);
	//run("Threshold...");
	//setAutoThreshold("Default dark");
	//waitForUser("Please optimize the (lower) threshold; THEN press OK.");
	//wait(1);
	setThreshold(0.40, 1.0);
	selectWindow_(imageTitle);
	getThreshold(lower, upper);
	allParams[15] = "" + lower;
	allParams[16] = "" + upper;
	return allParams;
}

function apply3DMedianFilter(allParams) {
	imageTitle = allParams[1];
	nMFX = parseFloat(allParams[7]);
	nMFY = parseFloat(allParams[8]);
	nMFZ = parseFloat(allParams[9]);
	typeOf3DFilter = allParams[27];
	
	selectWindow_(imageTitle);
	hyperStackToStack(allParams);
	if (typeOf3DFilter == "3D-stack") {
		nImages_ = nImages;
		run("3D Fast Filters","filter=Median radius_x_pix=" + nMFX + " radius_y_pix=" + nMFY + " radius_z_pix=" + nMFZ + " Nb_cpus=12");
		while (nImages == nImages_) {
		}
	} else if (typeOf3DFilter == "2D") {
		copyImageTitle = duplicateCurrentStack();
		rename_(copyImageTitle, "2D Median");
		run("Median...", "radius=5 stack");
	}
	stackToHyperStack(allParams);
	filteredImageTitleOriginal = getTitle();
	filteredImageTitle = filteredImageTitleOriginal + " {" + imageTitle + "}";
	rename_(filteredImageTitleOriginal, filteredImageTitle);
	setHyperStackToMiddle(filteredImageTitle);
	run("Enhance Contrast", "saturated=0.0");
	
	allParams[13] = filteredImageTitle;

	return allParams;
}

function hyperStackToStack(allParams) {
	nSlicesOriginal = parseInt(allParams[5]);
	nFramesOriginal = parseInt(allParams[6]);
	if ((nFramesOriginal > 1) && (nSlicesOriginal > 1)) {
		run("Hyperstack to Stack");
	}
	continueFlag = false;
	while (continueFlag) {
		Stack.getDimensions(width, height, channels, slices, frames);
		continueFlag = ((frames > 1) && (slices > 1));
	}
}

function stackToHyperStack(allParams) {
	nSlicesOriginal = parseInt(allParams[5]);
	nFramesOriginal = parseInt(allParams[6]);
	if ((nFramesOriginal > 1) && (nSlicesOriginal > 1)) {
		run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=" + 
			nSlicesOriginal + " frames=" + nFramesOriginal + " display=Color");
	}
	continueFlag = false;
	while (continueFlag) {
		Stack.getDimensions(width, height, channels, slices, frames);
		continueFlag = ((frames == 1) || (slices == 1));
	}
}

function apply3DMedianFilterWeka(allParams) {
	imageTitle = allParams[23];
	selectWindow_(imageTitle);
	duplicateCurrentStack();
	filteredImageTitleOriginal = getTitle();
	filteredImageTitle = filteredImageTitleOriginal + " {" + imageTitle + "}";
	rename_(filteredImageTitleOriginal, filteredImageTitle);
	run("Median...", "radius=5 stack");
	
	setHyperStackToMiddle(filteredImageTitle);
	run("Enhance Contrast", "saturated=0.0");
	allParams[24] = filteredImageTitle;
	return allParams;
}

function apply3DMeanFilter(allParams) {
	imageTitle = allParams[13];
	nMFX = parseFloat(allParams[10]);
	nMFY = parseFloat(allParams[11]);
	nMFZ = parseFloat(allParams[12]);
	typeOf3DFilter = allParams[27];
	
	selectWindow_(imageTitle);
	hyperStackToStack(allParams);
	if (typeOf3DFilter == "3D-stack") {
		nImages_ = nImages;
		run("3D Fast Filters","filter=Mean radius_x_pix=" + nMFX + " radius_y_pix=" + nMFY + " radius_z_pix=" + nMFZ + " Nb_cpus=12");
		while (nImages == nImages_) {
		}
	} else if (typeOf3DFilter == "2D") {
		copyImageTitle = duplicateCurrentStack();
		rename_(copyImageTitle, "2D Mean");
		run("Mean...", "radius=5 stack");
	}
	stackToHyperStack(allParams);
	filteredImageTitleOriginal = getTitle();
	filteredImageTitle = filteredImageTitleOriginal + " {" + imageTitle + "}";
	rename_(filteredImageTitleOriginal, filteredImageTitle);
	setHyperStackToMiddle(filteredImageTitle);
	run("Enhance Contrast", "saturated=0.0");

	allParams[14] = filteredImageTitle;
	return allParams;
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

function getTimeSeries(allParams) {
	stackPath = File.openDialog("Please select the time-series image.");
	showStatus("Loading the image stack ...");
	stackTitle = openPath(stackPath);
	Stack.getDimensions(width, height, channels, slices, frames);
	run("Enhance Contrast", "saturated=0.0");
	print("The path of the time-series image: " + stackPath);
	print("The title of the time-series image: " + stackTitle);
	print("The dimensions of the time-series image: " + frames + " frames, " +
		slices + " slices, and " + channels + " channels of " + width + "x" + height + " images");

	setHyperStackToMiddle(stackTitle);


	allParams[0] = "" + stackPath;
	allParams[1] = "" + stackTitle;
	allParams[2] = "" + width;
	allParams[3] = "" + height;
	allParams[4] = "" + channels;
	allParams[5] = "" + slices;
	allParams[6] = "" + frames;

	if (frames > 1) {
		allParams = set3DFilterType("2D", allParams);
	}

	return allParams;
}

function duplicateCurrentStack() {
	nImages_ = nImages;
	run("Duplicate...", "duplicate");
	while (nImages_ == nImages) {
	}
	adjustSettings();
	return getTitle();
}

function setHyperStackToMiddle(imageTitle) {
	selectWindow_(imageTitle);
	Stack.getDimensions(width, height, channels, slices, frames);
	slice_ = maxOf(1, floor(slices / 2));
	frame_ = maxOf(1, floor(frames / 2));
	Stack.setPosition(1, slice_, frame_);
}


function duplicateCurrentStack() {
	nImages_ = nImages;
	run("Duplicate...", "duplicate");
	while (nImages_ == nImages) {
	}
	adjustSettings();
	return getTitle();
}

function open_(imagePath) {
	nImages_ = nImages;
	open(imagePath);
	while (nImages_ == nImages) {
	}
	return getTitle();
}

function openPath(imagePath) {
	nImages_ = nImages;
	open(imagePath);
	while (nImages_ == nImages) {
	}
	return getTitle();
}

close_(imageTitle) {
	close(imageTitle);
	while (isOpen(imageTitle)) {
	}
}

function adjustSettings() {
	zoomPercent = 200;
	run("Set... ", "zoom=" + zoomPercent + " x=" + (getWidth / 2) + " y=" + (getHeight / 2));
	setSlice((floor(nSlices / 2)));
	run("Green");
	run("Enhance Contrast", "saturated=0.0");
}

function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while (getTitle != imageTitle) {
	}
}

function Initialize() {
	setBatchMode("exit and display");
	run("Close All");
	while (nImages > 0) {
	}
	wait(1);

	//run("Clear Results");
	//updateResults();

	clearROIManager();
	wait(100);

	closeAllUniqueWindows();
	wait(10);

	tableFileExtension = "txt";
	run("Input/Output...", "jpeg=85 gif=-1 file=" + tableFileExtension + " copy_column save_column");
	run("Set Measurements...", "area integrated stack redirect=None decimal=2");
	run("Colors...", "foreground=white background=black selection=cyan");	
	run("Overlay Options...", "stroke=none width=0 fill=none set");
	wait(1);
}

function closeWindowStartString(startString) {
	wait(1000);
	list = getList("image.titles");
	listLength = list.length;
	if (listLength > 0) {
		for (i = 0; i < listLength; i++) {
			if (startsWith(list[i], startString)) {
				selectWindow(list[i]);
				wait(100);
				run("Close");
				wait(100);
				while (isOpen(list[i])) {
				}
				wait(1);
				print("Window " + list[i] + " was closed.");
			}
		}	
	}
}

function closeAllUniqueWindows() {
	wait(1000);
	list = getList("window.titles");
	listLength = list.length;
	if (listLength > 0) {
		for (i = 0; i < listLength; i++) {
			if (list[i] != "Log") {
				selectWindow(list[i]);
				run("Close");
				wait(100);
				while (isOpen(list[i])) {
				}
				wait(1);
				print("Window " + list[i] + " was closed.");
			}
		}	
	}
}

function clearROIManager() {
	run("ROI Manager...");
	if (roiManager("count") > 0) {
		roiManager("Deselect");
		roiManager("Delete");		
	}
	while (roiManager("count") != 0) {
	}
	wait(10);
}

function initializeAllParams() {
	N = 50;
	allParams = newArray(N);
	for (cntr = 0; cntr < N; cntr++) {
		allParams[cntr] = "" + "NaN";
	}

	allParams[7] = "" + 5;				//nMedFiltX (5)
	allParams[8] = "" + 5;				//nMedFiltY (5)
	allParams[9] = "" + 1;				//nMedFiltZ (3)
	allParams[10] = "" + 5;				//nMeanFiltX (5)
	allParams[11] = "" + 5;				//nMeanFiltY (5)
	allParams[12] = "" + 1;				//nMeanFiltZ (3)
	nMFY = parseFloat(allParams[11]);
	nMFZ = parseFloat(allParams[12]);
	allParams[18] = "" + 10;			//minArea
	allParams[19] = "" + "infinity";	//maxArea
	allParams[20] = "" + 0.1;			//minCirculairy
	allParams[21] = "" + 1.0;			//maxCirculairy
	allParams[27] = "" + "3D-stack";	//typeOf3DFilter: "2D", "3D-stack", "3D-hyperstack"
	return allParams;
}

function set3DFilterType(filterType, allParams) {
	allParams[27] = "" + filterType;
	return allParams;
}



