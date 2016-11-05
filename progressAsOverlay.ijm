// Program: progressAsOverlay.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Displays the action (to be performed) as an overlay to inform the user. It is a more visible and less distracting alternative for the ShowMessage windows and showStatus messages.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	testProcess();
}

function Initialize() {
  	setBatchMode(false);
	print("\\Clear");
	if (nImages > 0) {
		run("Close All");
		while (nImages > 0) {
		}
		wait(1);
	}
	if (nResults > 0) {
		run("Clear Results");
	}
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}
	wait(1);
}

function doWithAnnouncement(Message, PositionX, PositionY, Command, Delay, animationFlag, imageTitle) {
	run("Remove Overlay");
	Overlay.drawString(Message,PositionX,PositionY);
	Overlay.show();
	wait(Delay);
	eval(Command);
	wait(Delay);
	if (animationFlag) {
		run("Flatten", "stack");
		selectWindow(imageTitle);
		wait(1);
	}
	run("Remove Overlay");
}

function testProcess() {
	Delay = 1000;
	DQ=fromCharCode(0x22);
	imageTitle = "twoChannelCells.tif";
	imageURLFolder = "http://www.zmbh.uni-heidelberg.de/Central_Services/Imaging_Facility/ijMacrosImages/";
	open(imageURLFolder + imageTitle);
	while (!isOpen(imageTitle)) {
	}
	wait(1);
	run("Split Channels");
	channel2Title = "C2-" + imageTitle;
	while(!isOpen(channel2Title)) {
	}
	wait(1);
	close(channel2Title);
	wait(1);
	rename(imageTitle);
	wait(1);

	setColor(0xff, 0x22, 0xff);
	setFont("Serif", 24, "antialiased");
	X = floor(getWidth * 0.07);
	Y = floor(getHeight * 0.25);

	animationFlag = true;

	Command = "";
	doWithAnnouncement("Original Image", X, Y, Command, Delay, animationFlag, imageTitle);

	Command = "run(" + DQ + "Median..." + DQ + "," + DQ + "radius=3 stack" + DQ + ");";
	doWithAnnouncement("Median Filtering ...", X, Y, Command, Delay, animationFlag, imageTitle);

	Command = "run(" + DQ + "Invert LUT" + DQ + ");";
	doWithAnnouncement("Inverting LUT ...", X, Y, Command, Delay, animationFlag, imageTitle);

	Command = "run(" + DQ + "Invert LUT" + DQ + ");";
	doWithAnnouncement("Retrieveing original LUT ...", X, Y, Command, Delay, animationFlag, imageTitle);

	Command = "run(" + DQ + "Enhance Contrast" + DQ + "," + DQ + "saturated=0" + DQ + ");";
	doWithAnnouncement("Enhancing Contrast ...", X, Y, Command, Delay, animationFlag, imageTitle);

	Command = "";
	doWithAnnouncement("Thank You!", X, Y, Command, Delay, animationFlag, imageTitle);

	if (animationFlag) {
		close(imageTitle);
		while(isOpen(imageTitle)) {
		}
		wait(1);
		run("Images to Stack", "name=Animation title=[] use");
	}
}
