// Program: roiOverlap.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Determines if two ROIs are within each other, overlapping, or separated.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	testData = getBoolean("Using test data?");
	Initialize(testData);
	wait(1);
	singleImageFlag = loadROIs(testData);
	if (singleImageFlag) {
		determineROIOverlaps();
	}
}

function Initialize(testData) {
	run("Clear Results");
	setBatchMode("exit and display");
	if (testData) {
		run("Close All");
		while (nImages > 0) {
		}
		if (roiManager("count") > 0) {
			roiManager("Deselect");
			roiManager("Delete");
		}
	}
}

function loadROIs(testData) {
	if (testData) {
		nImages_ = nImages;
		url = "http://www.zmbh.uni-heidelberg.de/Central_Services/Imaging_Facility/ijMacrosImages/cellPartition.png";
		open(url);
		while (nImages == nImages_) {
		}
		run("8-bit");
		Dialog.create("Coordinates of the two ROIs");
		Dialog.addNumber("ROI_1_x_upper_left_corner", 10);
		Dialog.addNumber("ROI_1_y_upper_left_corner", 10);
		Dialog.addNumber("ROI_1_x_bottom_right_corner", 80);
		Dialog.addNumber("ROI_1_y_bottom_right_corner", 50);
		Dialog.addNumber("ROI_2_x_upper_left_corner", 30);
		Dialog.addNumber("ROI_2_y_upper_left_corner", 20);
		Dialog.addNumber("ROI_2_x_bottom_right_corner", 60);
		Dialog.addNumber("ROI_2_y_bottom_right_corner", 40);
		Dialog.show;
		ROI_1_x_upper_left_corner = Dialog.getNumber();
		ROI_1_y_upper_left_corner = Dialog.getNumber();
		ROI_1_x_bottom_right_corner = Dialog.getNumber();
		ROI_1_y_bottom_right_corner = Dialog.getNumber();
		ROI_2_x_upper_left_corner = Dialog.getNumber();
		ROI_2_y_upper_left_corner = Dialog.getNumber();
		ROI_2_x_bottom_right_corner = Dialog.getNumber();
		ROI_2_y_bottom_right_corner = Dialog.getNumber();
		makeRectangle(ROI_1_x_upper_left_corner, ROI_1_y_upper_left_corner,
			ROI_1_x_bottom_right_corner, ROI_1_y_bottom_right_corner);
		run("Add Selection...");
		makeRectangle(ROI_2_x_upper_left_corner, ROI_2_y_upper_left_corner,
			ROI_2_x_bottom_right_corner, ROI_2_y_bottom_right_corner);
		run("Add Selection...");
		run("To ROI Manager");
	} else {
		waitForUser("Please load an image; define 2 ROIs; and then click OK.");
		wait(1);
		run("From ROI Manager");
	}
	while (roiManager("count") != 2) {
	}
	if (nSlices > 1) {
		waitForUser("Please select a single-channel image.");
		returnFlag = false;
	} else {
		returnFlag = true;
	}
	return returnFlag;
}

function determineROIOverlaps() {
	originalImageTitle = getTitle();
	run("Set Measurements...", "integrated redirect=None decimal=0");
	areaROI1 = generateROIImage(0, originalImageTitle);
	areaROI2 = generateROIImage(1, originalImageTitle);
	nImages_ = nImages;
	imageCalculator("AND create", "ROI_1","ROI_2");
	while (nImages == nImages_) {
	}
	rename("ROI_Overlap");
	run("Measure");
	areaOverlap = getResult("IntDen", nResults - 1);
	if (areaOverlap == 0) {
		message = "No overlap between ROIs";
	} else if (areaOverlap == minOf(areaROI1, areaROI2)) {
		if (areaROI2 < areaROI1) {
			message = "ROI_2 is inside ROI_1";
		} else {
			message = "ROI_1 is inside ROI_2";
		}
	} else {
		message = "Partial overlap of " + (floor(100 * areaOverlap / minOf(areaROI1, areaROI2))) +"%";
	}
	waitForUser(message);wait(1);
	print("Area_1 = " + areaROI1 + ", Area_2 = " + areaROI2 + ", Area_Overlap = " + areaOverlap);
}


function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while (getTitle != imageTitle) {
	}
}

function generateROIImage(cntr, originalImageTitle) {
	roiManager("Deselect");
	selectWindow_(originalImageTitle);
	run("Select None");
	nImages_ = nImages;
	run("Duplicate...", "duplicate");
	while (nImages == nImages_) {
	}
	image1Title = "ROI_" + (cntr + 1);
	rename(image1Title);
	while (!isOpen(image1Title)) {
	}
	roiManager("select", cntr);
	while (roiManager("index") != cntr) {
	}
	run("Clear Outside");
	run("Fill", "slice");
	roiManager("Deselect");
	while (roiManager("index") > -1) {
	}
	run("Select None");
	run("Measure");
	//waitForUser;wait(1);
	return getResult("IntDen", nResults - 1);
}
