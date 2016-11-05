// Program: flexibleZoomIn.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Replaces the exhaustive iterations of {zoom-in, zoom-out} with auxilary zoomed-in image(s). By simply clicking at arbitrary points (ROI centers in the original image), a zoomed-in version of the ROI will show up as a different image. Such new ROI images can be closed automatically upon a new zoom-in action.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	//Parameters
	closePreviousROIsFlag = true;
	selectionWidth = 40;
	zoomPercent = 500;

	//Identifying the main image
	while (nImages != 1) {
		waitForUser("Please open ONE image and then press OK");
		wait(1);
	}
	waitForUser("Click to specify ROI Centers; Shift+Click for the last one");
	wait(1);
	originalTitle = getTitle();
	roiTitle = "-1 ROI";
	Offset = selectionWidth / 2;
	setTool("rectangle");
	run("Select None");

	//Main loop
	continueFlag = true;
	cntr = 1;
	while (continueFlag) {
		//Point specification
		selectWindow_(originalTitle);
		run("Select None");
		pointXYShift = getPoint();

		//Closure of the last ROI image, if any
		if (closePreviousROIsFlag) {
			if (isOpen(roiTitle)) {
				close(roiTitle);
				while (isOpen(roiTitle)) {
				}
			}
		}

		//New ROI definition
		selectWindow_(originalTitle);
		makeRectangle(pointXYShift[0] - Offset, pointXYShift[1] - Offset, selectionWidth, selectionWidth);
		wait(1);
		
		//Duplication
		nImages_ = nImages;
		roiTitle = "ROI Image " + (cntr++);
		run("Duplicate...", "title=[" + roiTitle + "]");
		while(nImages_ == nImages) {
		}
		selectWindow_(roiTitle);
		run("Set... ", "zoom=" + zoomPercent + " x=" + Offset + " y=" + Offset);

		//Check for termination
		if (pointXYShift[2] != 0) {
			continueFlag = false;
		}
		if (nImages == 0) {
			continueFlag = false;
		}
	}
	if (isOpen(originalTitle)) {
		selectWindow_(originalTitle);
		run("Select None");
	}
}

function getPoint() {
  flags = 0;
  x2 = -1;
  y2 = -1;
  flags2 = -1;
  shift = 1;
  leftButton = 16;
  msDebounceTime = 10;
  pointXYShift = newArray(3);
  while ((flags & leftButton) == false) {
      getCursorLoc(x, y, z, flags);
  }
  pointXYShift[0] = x;
  pointXYShift[1] = y;
  pointXYShift[2] = (flags & shift);
  wait(msDebounceTime);
  while ((flags & leftButton) == true) {
      getCursorLoc(x, y, z, flags);
  }
  wait(msDebounceTime);
  return pointXYShift;
}

function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while (getTitle != imageTitle) {
	}
	//wait(1);
}

