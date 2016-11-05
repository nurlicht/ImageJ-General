macro "Main" {
	Initialize();
	showInfo();
	allParams = initializeAllParams();
	allParams = getUserParams(allParams);
	allParams = selectHyperstack(allParams);
	allParams = loadHyperstack(allParams);
	allParams = rearrangeOriginalHyperStack(allParams);
	allParams = setHyperStackDimensions(allParams);
	allParams = getYM(allParams);
	allParams = getYM4G(allParams);
	allParams = getGM4R(allParams);
	allParams = getYM4R(allParams);
	allParams = getRS(allParams);
	allParams = getGCRS(allParams);
}

function getGCRS(allParams) {
	RS = "RS";
	maskedR = "Result of " + RS;
	GCRS = "GCRS";
	YM4R = "YM4R";
	GM4R = "GM4R";
	
	imageCalculator("Multiply create 32-bit stack", RS, GM4R);
	while (!isOpen(maskedR)) {
	}

	selectWindow_(maskedR);
	getMinAndMax(min, max);
	selectWindow_(maskedR);
	run("Macro...", "code=[v = " + max + " * (v > 0)] stack");
	selectWindow_(maskedR);
	run("8-bit");
	selectWindow_(maskedR);
	run("Macro...", "code=[v = 255 * (v > 0)] stack");
	selectWindow_(maskedR);
	run("Enhance Contrast", "saturated=0.0");

	selectWindow_(maskedR);
	run("Analyze Particles...", "size=2-1000 pixel circularity=0.10-1.00 show=Masks display exclude clear stack");
	while (!isOpen("Mask of " + maskedR)) {
	}
	run("Invert LUT");
	rename_("Mask of " + maskedR, GCRS);

	while (!isOpen("Results")) {
	}
	print("N(Red & Green) = " + (nResults));
	selectWindow("Results");
	run("Close");
	while (isOpen("Results")) {
	}
	close_(maskedR);

	return allParams;
}

function getRS(allParams) {
	R = "R";
	maskedR = "Result of " + R;
	RS = "RS";
	YM4R = "YM4R";
	
	mainHyperStackTitle = "" + allParams[1];
	selectWindow_(mainHyperStackTitle);
	run("Duplicate...", "title=R duplicate frames=4");
	while (!isOpen(R)) {
	}

	imageCalculator("Multiply create 32-bit stack", R,YM4R);
	while (!isOpen(maskedR)) {
	}
	close_(R);
	

	selectWindow_(maskedR);
	run("Median...", "radius=2 stack");
	selectWindow_(maskedR);
	run("Gaussian Blur...", "sigma=2 stack");

	selectWindow_(maskedR);
	resetThreshold();
	selectWindow_(maskedR);

	getMinAndMax(min, max);
	run("Macro...", "code=[v = " + max + " * (v >= 18305)] stack");
	//run("Macro...", "code=[v = " + max + " * (v >= 50000)] stack");
	selectWindow_(maskedR);
	run("8-bit");
	selectWindow_(maskedR);
	run("Macro...", "code=[v = 255 * (v > 0)] stack");
	selectWindow_(maskedR);
	run("Enhance Contrast", "saturated=0.0");

	selectWindow_(maskedR);
	run("Analyze Particles...", "size=2-1000 pixel circularity=0.00-0.95 show=Masks display exclude clear stack");
	while (!isOpen("Mask of " + maskedR)) {
	}
	run("Invert LUT");
	rename_("Mask of " + maskedR, RS);

	while (!isOpen("Results")) {
	}
	print("N(Red) = " + (nResults));
	selectWindow("Results");
	run("Close");
	while (isOpen("Results")) {
	}
	close_(maskedR);
	return allParams;
}

function getYM4R(allParams) {
	YM = "YM";
	YM4R = "YM4R";

	selectWindow_(YM);
	run("Duplicate...", "title=[" + YM4R + "] duplicate");
	while(!isOpen(YM4R)) {
	}
	nDilations = 5;
	setOption("BlackBackground", true);
	for (cntr = 0; cntr < nDilations; cntr++) {
		selectWindow_(YM4R);
		run("Dilate", "stack");	
	}
	return allParams;
}

function getGM4R(allParams) {
	G = "G";
	maskedG = "Result of " + G;
	GM4R = "GM4R";

	run("Duplicate...", "title=[" + G + "] duplicate frames=2");
	while (!isOpen(G)) {
	}

	imageCalculator("Multiply create 32-bit stack", "G","YM4G");
	while (!isOpen(maskedG)) {
	}
	close_(G);
	
	selectWindow_(maskedG);
	run("Median...", "radius=2 stack");
	selectWindow_(maskedG);
	run("Gaussian Blur...", "sigma=2 stack");
	selectWindow_(maskedG);
	resetThreshold();
	selectWindow_(maskedG);
	run("Macro...", "code=[v = 255 * (v >= 5903)] stack");
	selectWindow_(maskedG);
	run("8-bit");
	selectWindow_(maskedG);
	run("Macro...", "code=[v = 255 * (v > 0)] stack");
	selectWindow_(maskedG);
	run("Enhance Contrast", "saturated=0.0");

	selectWindow_(maskedG);
	run("Analyze Particles...", "size=4-600 pixel circularity=0.60-1.00 show=Masks exclude stack");
	while(!isOpen("Mask of " + maskedG)) {
	}
	run("Invert LUT");
	rename_("Mask of " + maskedG, GM4R);
	close_(maskedG);

	return allParams;
}

function getYM4G(allParams) {
	YM = "YM";
	YM4G = "YM4G";

	selectWindow_(YM);
	run("Duplicate...", "title=[" + YM4G + "] duplicate");
	while(!isOpen(YM4G)) {
	}
	nDilations = 0;
	setOption("BlackBackground", true);
	for (cntr = 0; cntr < nDilations; cntr++) {
		selectWindow_(YM4G);
		run("Dilate", "stack");	
	}
	return allParams;
}

function getYM(allParams) {
	mainHyperStackTitle = "" + allParams[1];
	selectWindow_(mainHyperStackTitle);
	run("Duplicate...", "title=Y duplicate frames=3");
	while (!isOpen("Y")) {
	}
	selectWindow_("Y");
	run("Median...", "radius=2 stack");
	selectWindow_("Y");
	run("Gaussian Blur...", "sigma=2 stack");
	selectWindow_("Y");
	resetThreshold();
	selectWindow_("Y");
	run("Macro...", "code=[v = 65535 * (v >= 447)] stack");
	selectWindow_("Y");
	run("8-bit");
	selectWindow_("Y");
	run("Enhance Contrast", "saturated=0.0");
	selectWindow_("Y");
	run("Analyze Particles...", "size=4-600 pixel circularity=0.60-1.00 show=Masks exclude stack");
	while(!isOpen("Mask of Y")) {
	}
	run("Invert LUT");
	rename_("Mask of Y", "YM");
	close_("Y");
	return allParams;
}

function rearrangeOriginalHyperStack(allParams) {
	originalHyperStackTitle = "" + allParams[1];
	selectWindow_(originalHyperStackTitle);

	Stack.getDimensions(width, height, channels, slices, frames);
	nChannels = channels;
	nSlices_ = maxOf(slices, frames);
	Stack.setDimensions(nChannels, nSlices_, 1);

	run("Split Channels");
	while (!isOpen("C1-" + originalHyperStackTitle)) {
	}
	while (!isOpen("C2-" + originalHyperStackTitle)) {
	}
	while (!isOpen("C3-" + originalHyperStackTitle)) {
	}
	while (!isOpen("C4-" + originalHyperStackTitle)) {
	}
	while (isOpen(originalHyperStackTitle)) {
	}

	mergeTitle = originalHyperStackTitle;
	text = "  title=[" + mergeTitle + "] open ";
	for (cntr = 1; cntr <= nChannels; cntr++) {
		text += "image" + cntr + "=C" + cntr + "-" + originalHyperStackTitle + " ";
	}
	if (isOpen(mergeTitle)) {
		close_(mergeTitle);
	}
	nImages_ = nImages;
	run("Concatenate...", text);
	while (nImages_ == nImages) {
	}
	while (!isOpen(mergeTitle)) {
	}

	run("Grays");
	run("Enhance Contrast", 0);
	
	return allParams;
	
}

function measureHyperstack(allParams) {
	processedHyperStackTitle = "" + allParams[23];
	selectWindow_(processedHyperStackTitle);
	analyzeParticles(allParams);
	roiManager("Show All without labels");
	roiManager("Show None");
	run("Synchronize Windows");
		
	return allParams;


	
	nChannels = getNChannels(allParams);
	nFrames = getNFrames(allParams);
	
	
	for (channelCntr = 2; channelCntr <= 4; channelCntr += 2) {
		for (frameCntr = 1; frameCntr <= nFrames; frameCntr++) {
			allParams = getFrame(frameCntr, channelCntr, allParams);
			thresholdFrame(allParams);
			analyzeParticles(allParams);
			closeFrame(allParams);
			//waitForUser;wait(1);
		}
		allParams = getFrame(-1, channelCntr, allParams);
		
		// To be done for each frame, and the array to be saved as a string in allParams
		// The coordiantes of ROIs (green and red) also to be compared
		allParams = getNSpots(allParams);
	}
	return allParams;
}

function getNSpots(allParams) {
	greenRedBarFlag = (allParams[8] == "");
	nAllSpots = nResults;
	if (greenRedBarFlag) {
		nRedSpots = parseInt(allParams[20]);
		nGreenSpots = nAllSpots - nRedSpots;
		allParams[21] = "" + nGreenSpots;
	} else {
		allParams[20] = "" + nAllSpots;	//nRedSpots
	}
	allParams[21] = "" + 0;	//nGreenSpots
}

function closeFrame(allParams) {
	currentFrameTitle = "" + allParams[9];
	delay1 = parseFloat(allParams[19]);
	wait(delay1);
	close_(currentFrameTitle);
}

function analyzeParticles(allParams) {
	minSizeAP = parseFloat(allParams[13]);
	maxSizeAP = parseFloat(allParams[14]);
	minCircularityAP = parseFloat(allParams[15]);
	maxCircularityAP = parseFloat(allParams[16]);
	run("Analyze Particles...", "size=" + minSizeAP + "-" + maxSizeAP + " pixel circularity=" + minCircularityAP + "-" + maxCircularityAP + " display exclude add stack");
	roiManager("Show All");
	roiManager("Show None");	
}

function thresholdFrame(allParams) {
	greenRedBarFlag = (allParams[8] == "");
	if (greenRedBarFlag) {
		lowerThreshold = parseFloat(allParams[17]);
		upperThreshold = parseFloat(allParams[18]);
	} else {
		lowerThreshold = parseFloat(allParams[10]);
		upperThreshold = parseFloat(allParams[11]);
	}
	currentFrameTitle = "" + allParams[9];
	setThreshold(lowerThreshold, upperThreshold);
}

function getFrame(frameCntr, channelCntr, allParams) {
	greenRedBarFlag = (channelCntr == 2);

	if (frameCntr > -1) {
		selectWindow_("" + allParams[1]);
		sliceCntr = 1;
		Stack.setPosition(channelCntr, sliceCntr, frameCntr);
		nImages_ = nImages;
		run("Duplicate...", "  channels=" + channelCntr + " frames=" + frameCntr);
		while (nImages_ == nImages) {
		}
	
		if (greenRedBarFlag) {
			allParams[7] = "" + getTitle();
			allParams[8] = "";
			allParams[9] = "" + getTitle();
		} else {
			allParams[7] = "";
			allParams[8] = "" + getTitle();
			allParams[9] = "" + getTitle();
		}
	} else {
			allParams[7] = "";
			allParams[8] = "";
			allParams[9] = "";
	}

	return allParams;
}

function getFrameTitle(allParams) {
	greenImageTitle = "" + allParams[7];
	redImageTitle = "" + allParams[8];
	if (lengthOf(greenImageTitle) > lengthOf(redImageTitle)) {
		frameTitle = greenImageTitle;
	} else {
		frameTitle = redImageTitle;
	}
	return frameTitle;
}

function close_(imageTitle) {
	selectWindow_(imageTitle);
	run("Close");
	while (isOpen(imageTitle)) {
	}
}

function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while(getTitle() != imageTitle) {
	}
}

function preProcessHyperStack(allParams) {
	nChannels = getNChannels(allParams);
	originalHyperStackTitle = getImageTitle(allParams);
	channelWekaFlags = getChannelWekaFlags(allParams);
	mapTitles = newArray(nChannels);
	for (cntr = 0; cntr < nChannels; cntr++) {
		currentChannelTitle = "" + getSingleChannel(cntr, allParams);
		selectWindow_(currentChannelTitle);
		if ((channelWekaFlags >> cntr) & 1) {
			print("Channel " + (cntr + 1) + ": Weka segmentation");
			run("Trainable Weka Segmentation");
			wekaTitle = waitForImageWindow("Trainable Weka Segmentation");
			close_(currentChannelTitle);
			selectWindow_(wekaTitle);
			renameClasses(cntr);
			waitForUser("Please select ROIs and THEN press OK.");
			wait(1);
			mapTitles[cntr] = "" + getChannelMap(cntr);
			close_(wekaTitle);
		} else {
			print("Channel " + (cntr + 1) + ": No Weka segmentation");
			medianRadius = parseInt(allParams[12]);
			run("Median...", "radius=" + medianRadius + " stack");
			selectWindow_(currentChannelTitle);
			run("32-bit");
			getMinAndMax(min, max);
			run("Divide...", "value=" + max + " stack");
			mapTitles[cntr] = "Channel" + (cntr + 1) + "_Spot_Prob_Map";
			rename_(currentChannelTitle, "" + mapTitles[cntr]);
		}
		thresholdImage(mapTitles[cntr]);
	}
	if(isOpen("Threshold")) {
		selectWindow("Threshold");
		run("Close");
	}
	processedHyperstackTitle = mergeChannels(mapTitles);
	allParams[23] = "" + processedHyperstackTitle;
	return allParams;
}

function thresholdImage(imageTitle) {
	selectWindow_(imageTitle);
	resetThreshold();
	setAutoThreshold("Default dark");
	run("Threshold...");
	waitForUser("Please threshold the image and THEN press OK.");
	wait(1);
	selectWindow_(imageTitle);
	getThreshold(lower, upper);
	resetThreshold();
	run("Macro...", "code=[v = 255 * (v <= " + upper + ") & (v >= " + lower + ");] stack");
	selectWindow_(imageTitle);
	run("8-bit");
	selectWindow_(imageTitle);
	resetThreshold();
	selectWindow_(imageTitle);
	//waitForUser;wait(1);
}

function renameClasses(cntr) {
	call("trainableSegmentation.Weka_Segmentation.changeClassName", "0", "Dark");
	call("trainableSegmentation.Weka_Segmentation.changeClassName", "1", "Background");
	call("trainableSegmentation.Weka_Segmentation.createNewClass", 	condAssign((cntr == 0), "Nucleous", "Spot"));
}

function getChannelMap(cntr) {
	fullMapTitle = "Probability maps";
	mapTitle = "Channel" + (cntr + 1) + "_Spot_Prob_Map";

	call("trainableSegmentation.Weka_Segmentation.trainClassifier");

	if (isOpen(fullMapTitle)) {
		close_(fullMapTitle);
	}
	nImages_ = nImages;
	call("trainableSegmentation.Weka_Segmentation.getProbability");
	while (nImages_ == nImages) {
	}
	while (!isOpen(fullMapTitle)) {
	}

	selectWindow_(fullMapTitle);
	nFrames = nSlices / 3;
	run("Stack to Hyperstack...", "order=xyczt(default) channels=3 slices=1 frames=" + nFrames + " display=Grayscale");
	channels = 1;
	while (channels != 3) {
		Stack.getDimensions(width, height, channels, slices, frames);
	}
	
	selectWindow_(fullMapTitle);
	run("Split Channels");
	while (!isOpen("C1-" + fullMapTitle)) {
	}
	close_("C1-" + fullMapTitle);
	while (!isOpen("C2-" + fullMapTitle)) {
	}
	close_("C2-" + fullMapTitle);
	while (!isOpen("C3-" + fullMapTitle)) {
	}
	rename_("C3-" + fullMapTitle, mapTitle);
	return mapTitle;
}

function mergeChannels(mapTitles) {
	nChannels = lengthOf(mapTitles);
	mergeTitle = "Processed_Hyperstack";
	colors = newArray("Blue", "Green", "Yellow", "Red", "Grays");

	for (cntr = 0; cntr < nChannels; cntr++) {
		selectWindow_(mapTitles[cntr]);
		Stack.getDimensions(width, height, channels, slices, frames);
		nSlices_ = maxOf(slices, frames);
		Stack.setDimensions(1, nSlices_, 1);
	}

	text = "  title=[" + mergeTitle + "] open ";
	for (cntr = 1; cntr <= nChannels; cntr++) {
		text += "image" + cntr + "=" + mapTitles[cntr - 1] + " ";
	}
	if (isOpen(mergeTitle)) {
		close_(mergeTitle);
	}
	nImages_ = nImages;
	run("Concatenate...", text);
	while (nImages_ == nImages) {
	}
	while (!isOpen(mergeTitle)) {
	}
	
	selectWindow_(mergeTitle);
	for (cntr = 0; cntr < nChannels; cntr++) {
		Stack.setChannel(cntr + 1);
		//run(colors[cntr]);
		run(colors[nChannels]);
	}
	
	selectWindow_(mergeTitle);
	return mergeTitle;
}

function getSingleChannel(cntr, allParams) {
	originalHyperStackTitle = getImageTitle(allParams);
	selectWindow_(originalHyperStackTitle);
	nImages_ = nImages;
	run("Duplicate...", "title=c" + (1 + cntr) + " duplicate channels=" + (1 + cntr));
	while (nImages_ == nImages) {
	}
	currentChannelTitle = getTitle();
	return currentChannelTitle;
}

function loadHyperstack(allParams) {
	imagePath = "" + allParams[0];
	imageTitle = open_(imagePath);
	Stack.getDimensions(width, height, channels, slices, frames);
	allParams[1] = "" + imageTitle;

	for (cntr = 0; cntr < channels; cntr++) {
		Stack.setChannel(cntr + 1);
		run("Grays");
	}
	return allParams;
}

function open_(imagePath) {
	nImages_ = nImages;
	open(imagePath);
	while (nImages_ == nImages) {
	}
	return getTitle();
}

function selectHyperstack(allParams) {
	imagePath = File.openDialog("Please select the TIFF hyperstack");

	allParams[0] = "" + imagePath;
	return allParams;
}

function getUserParams(allParams) {
	return allParams;
}

function initializeAllParams() {
	nAllParams = 40;
	allParams = newArray(nAllParams);

	allParams[0] = "" + "";			//imagePath
	allParams[1] = "" + "";			//imageTitle

	allParams[2] = "" + "";			//imageWidth
	allParams[3] = "" + "";			//imageHeight
	allParams[4] = "" + "";			//imageChannels
	allParams[5] = "" + "";			//imageSlices
	allParams[6] = "" + "";			//imageFrames

	allParams[7] = "" + "4";		//yellowMedianFilterRadius
	allParams[8] = "" + "1";		//yellowLowerThreshold
	allParams[9] = "" + "65535";	//yellowUpperThreshold
	allParams[10] = "" + "4";		//yellowMinSize
	allParams[11] = "" + "400";		//yellowMaxSize
	allParams[12] = "" + "0.4";		//yellowMinCircularity
	allParams[13] = "" + "1.0";		//yellowMaxCircularity
	
	/*
	allParams[] = "" + "";	//
	*/
	
	
	return allParams;
}

function setHyperStackDimensions(allParams) {
	mainHyperStackTitle = "" + allParams[1];
	selectWindow_(mainHyperStackTitle);
	Stack.getDimensions(width, height, channels, slices, frames);
	allParams[2] = "" + width;
	allParams[3] = "" + height;
	allParams[4] = "" + channels;
	allParams[5] = "" + slices;
	allParams[6] = "" + frames;
	return allParams;
}

function Initialize() {
	setBatchMode("exit and display");
	run("Close All");
	while (nImages > 0) {
	}
	wait(1);

	//run("Clear Results");
	//updateResults();

	//clearROIManager();
	//wait(100);

	closeAllWindows();
	wait(10);

	tableFileExtension = "txt";
	run("Input/Output...", "jpeg=85 gif=-1 file=" + tableFileExtension + " copy_column save_column");
	run("Set Measurements...", "area integrated stack redirect=None decimal=2");
	run("Colors...", "foreground=white background=black selection=cyan");	
	run("Overlay Options...", "stroke=none width=0 fill=none set");
	setTool("rectangle");	
	wait(1);
}

function clearLog() {
	print("\\Clear");
}

function closeAllWindows() {
	wait(1000);
	list = getList("window.titles");
	listLength = list.length;
	if (listLength > 0) {
		for (i = 0; i < listLength; i++) {
			while (isOpen(list[i])) {
				selectWindow(list[i]);
				run("Close");
				wait(100);
				//print("Window " + list[i] + " was closed.");
			}
			wait(1);
		}	
	}
}

function clearROIManager() {
	//run("ROI Manager...");
	if (roiManager("count") > 0) {
		roiManager("Deselect");
		roiManager("Delete");		
		while (roiManager("count") != 0) {
		}
	}
	wait(1);
}

function rename_(oldTitle, newTitle) {
	selectWindow_(oldTitle);
	rename(newTitle);
	while (isOpen(oldTitle)) {
	}
	while (!isOpen(newTitle)) {
	}
	selectWindow_(newTitle);
}

function waitForImageWindow(windowLeadingTitle) {
	continueFlag = true;
	while (continueFlag) {
		list = getList("image.titles");
		listLength = list.length;
		if (listLength > 0) {
			for (i = 0; i < listLength; i++) {
				if (startsWith(list[i], windowLeadingTitle)) {
					continueFlag = false;
					wekaTitle = "" + list[i];
				}
			}	
		}
	}
	wait(1);
	return wekaTitle;
}

function condAssign(condition, trueAssign, falseAssign) {
	if (condition) {
		assignedValue = trueAssign;
	} else {
		assignedValue = falseAssign;
	}
	return assignedValue;
}

function showInfo() {
	title = "Overview of Analyses";
	message = 	"<html>" +
				"<font color='red'>Input</font> <br>" +
				"4-channel time-series: Blue (<b><font color='#0000ff'>B</font></b>), Green (<b><font color='#00ff00'>G</font></b>), Yellow (<b><font color='#dddd00'>Y</font></b>), and Red (<b><font color='#ff0000'>R</font></b>)<br>" +
				"<br>" +
				"<br>" +
				"<font color='red'>Non-trivial (biological) constraints</font> <br>" +
				"- Spots within a small neighborhood are counted as one unit (centrosome).<br>" +
				"- Green and Yellow Spots must coincide.<br>" +
				"- Red and Yellow Spots must correspond (be close to each other).<br>" +
				"- After partitioning cells, each Blue object (cell) must contain at most one unit of Spots.<br>" +
				"<br>" +
				"<br>" +
				"<font color='red'>Algorithm</font> <br>" +
				"1. Yellow channel (<b><font color='#dddd00'>Y</font></b>) --> Filtered --> Thresholded --> Detected Yellow Spots --> Yellow Mask (<b><font color='#dddd00'>YM</font></b>)<br>" +
				"<br>" +
				"2.1. Yellow Mask (<b><font color='#dddd00'>YM</font></b>) --> weakly-dialted mask for the Green channel (<b><font color='#dddd00'>YM4G</font></b>)<br>" +
				"2.2. Green Channel (<b><font color='#00ff00'>G</font></b>) --> Multiplied by <b><font color='#dddd00'>YM4G</font></b> --> Filtered --> Thresholded --> Detected Green Spots --> Green Mask (<b><font color='#00ff00'>GM4R</font></b>)<br>" +
				"<br>" +
				"3.1. Yellow Mask (<b><font color='#dddd00'>YM</font></b>) --> moderately-dialted mask for the Red channel (<b><font color='#dddd00'>YM4R</font></b>)<br>" +
				"3.2. Red Channel (<b><font color='#ff0000'>R</font></b>) --> Multiplied by <b><font color='#dddd00'>YM4R</font></b> --> Filtered --> Thresholded --> Detected Red Spots (<b><font color='#ff0000'>RS</font></b>)<br>" +
				"3.3. Counting the number of Detected Red Spots (<b><font color='#ff0000'>RS</font></b>)<br>" +
				"<br>" +
				"4.1. Red Channel (<b><font color='#ff0000'>R</font></b>) --> Multiplied by <b><font color='#dddd00'>YM4R</font></b> --> Multiplied by <b><font color='#00ff00'>GM4R</font></b> --> Filtered --> Thresholded --> Detected (Green-Constrained) Red Spots (<b><font color='#ff0000'>GCRS</font></b>)<br>" +
				"4.2. Counting the number of (Green-Constrained) Red Spots (<b><font color='#ff0000'>GCRS</font></b>)<br>" +
				"<br>" +
				"5.1. Finding the ratio of N(<b><font color='#ff0000'>GCRS</font></b>) / N(<b><font color='#ff0000'>RS</font></b>) <br>" +
				"<br>" +
				"<br>";
	showMessage(title, message);
}

