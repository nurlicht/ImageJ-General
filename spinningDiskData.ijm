// projected image
macro "Main" {
	Initialize();
	groupDir = getGroupDirectory();
	print("groupDir = " + groupDir);

	tMin = 1;
	tMax = 31;
	tStep = 1;
	sMin = 1;
	sMax = 7;
	cMin = 1;
	cMax = 2;
	projectName = "CenpB-Ska1_w";
	saveFolder = "zStacks";
	siRNA = "UNS";
	doZProj = true;
	
	Dialog.create("Hyperstack Parameters                 ");
	Dialog.addNumber("tMin", tMin);
	Dialog.addNumber("tMax", tMax);
	Dialog.addNumber("tStep", tStep);
	Dialog.addNumber("sMin", sMin);
	Dialog.addNumber("sMax", sMax);
	Dialog.addString("projectName", projectName);
	Dialog.addString("saveFolder", saveFolder);
	Dialog.addString("siRNA", siRNA);
	Dialog.addCheckbox("doZProj", doZProj);
	Dialog.show();
	tMin = Dialog.getNumber();
	tMax = Dialog.getNumber();
	tStep = Dialog.getNumber();
	sMin = Dialog.getNumber();
	sMax = Dialog.getNumber();
	projectName = Dialog.getString();
	saveFolder = Dialog.getString();
	siRNA = Dialog.getString();
	doZProj = Dialog.getCheckbox();
	

	
	subName = initializeSubName(projectName);
	nSubName = lengthOf(subName);
	Lambda = newArray(561, 488);
	hyperStackTitles = newArray((cMax - cMin + 1) * (sMax - sMin + 1));
	
	tNumber = 0;
	for (tCntr = tMin; tCntr <= tMax; tCntr += tStep) {
		tNumber++;
	}
	nameBuffer = newArray(tNumber);
	
	showStatus("Synthesizing images ...");
	hyperStackCntr = 0;
	allCntr = 0;
	allN = (sMax - sMin + 1) * (cMax - cMin + 1) * tNumber;
	for (sCntr = sMin; sCntr <= sMax; sCntr++) {
		subName[5] = "" + sCntr;
		for (cCntr = cMin; cCntr <= cMax; cCntr++) {
			subName[1] = "" + cCntr;
			subName[3] = "" + Lambda[cCntr - cMin];
			newTitle = "s_" + sCntr + "___Channel_" + cCntr;
			hyperStackTitles[hyperStackCntr] = newTitle;
			setBatchMode(true);
			nameCntr = 0;
			for (tCntr = tMin; tCntr <= tMax; tCntr += tStep) {
				showProgress(allCntr, allN);
				subName[7] = "" + tCntr;
				fullName = "";
				for (nCntr = 0; nCntr < nSubName; nCntr++) {
					fullName += subName[nCntr];
				}
				//print("nameCntr = " + nameCntr + ", tCntr = " + tCntr);
				nameBuffer[nameCntr++] = "" + fullName;
				print(fullName);
				nImages_ = nImages;
				open(fullName);
				while(nImages_ == nImages) {
				}


				if (doZProj) {
					newTitle_ = getTitle();
					zProjTitle = "MAX_" + newTitle_;
					nImages_ = nImages;
					run("Z Project...", "projection=[Max Intensity] all");
					while(nImages_ == nImages) {
					}
					close_(newTitle_);
					rename_(zProjTitle, newTitle_);
				}

				
				allCntr++;
			}

			nameCommand = "";
			for (nameCntr = 1; nameCntr <= tNumber; nameCntr++) {
				nameCommand += "image" + nameCntr + "=" + nameBuffer[nameCntr - 1] + " ";
			}
			run("Concatenate...", "  title=[" + newTitle + "] open " + nameCommand);
			while (!isOpen(newTitle)) {
			}
			wait(100);
			setBatchMode("exit and display");
			//waitForUser;wait(1);
			hyperStackCntr++;
		}
		run("Merge Channels...", "c1=[" + hyperStackTitles[hyperStackCntr - 2] + "] c2=[" + hyperStackTitles[hyperStackCntr - 1] + "] create");
		mergedTitle ="Merged";
		while (!isOpen(mergedTitle)) {
		}
		print("5D Hyperstack was created.");
		newTitle = "" + siRNA + "_" + sCntr;
		rename_(mergedTitle, newTitle);
		print("5D Hyperstack was renamed to " + newTitle + ".");
		selectWindow_(newTitle);
		print("Saving the image " + newTitle + " at " + groupDir);


		/*
		if (doZProj) {
			zProjTitle = "MAX_" + newTitle;
			nImages_ = nImages;
			run("Z Project...", "projection=[Max Intensity] all");
			while(nImages_ == nImages) {
			}
			close_(newTitle);
			rename_(zProjTitle, newTitle);
		}
		*/

		
		saveAs("tiff", groupDir + saveFolder + "\\" + newTitle);
		//saveAs("tiff", "./" + newTitle);
		print("Image " + newTitle + " was saved at " + groupDir + ".");
		Delay = 1000;
		wait(Delay);
		//waitForUser;wait(1);
		closeAll();
		collectGarbage();
	}
}

function Initialize() {
	print("\\Clear");
	setBatchMode("exit and display");
	closeAll();
	//run("Monitor Memory...");
	collectGarbage();
}

function rename_(oldTitle, newTitle) {
	selectWindow_(oldTitle);
	rename(newTitle);
	while (isOpen(oldTitle)) {
	}
	while (!isOpen(newTitle)) {
	}
}

function selectWindow_(title) {
	selectWindow(title);
	while (getTitle() != title) {
	}
	//wait(1);
}

function closeAll() {
	setBatchMode("exit and display");
	run("Close All");
	while (nImages) {
	}
}

function collectGarbage() {
	return;
	nGarbageCollector = 3;
	for (cntr = 0; cntr < nGarbageCollector; cntr++) {
		call("java.lang.System.gc");
	}
}

function getGroupDirectory() {
	groupDir = getDirectory("Please choose the directory containing single images");
	return groupDir;

	
	showStatus("Getting the file list ...");
	entitiesList = getFileList(groupDir);
	showStatus("Analyzing the file list ...");
	nEntities = lengthOf(entitiesList);
	nImageFiles = 0;
	imageList = newArray(nEntities);
	for (cntr = 0; cntr < nEntities; cntr++) {
		showProgress(cntr, nEntities);
		currentEntitty = entitiesList[cntr];
		nCurrentEntity = lengthOf(currentEntitty);
		currentExtension = substring(currentEntitty, nCurrentEntity - 4, nCurrentEntity);
		if (toLowerCase(currentExtension) == ".tif") {
			imageList[nImageFiles++] = currentEntitty;
		}
	}
	showStatus("");
	imageList = Array.slice(imageList, 0, nImageFiles);
	print("" + nImageFiles + " image files with extension '.TIF' were detected.");

	//Possible use of imageList ...

	return groupDir;
}

function close_(title) {
	selectWindow_(title);
	run("Close");
	while (isOpen(title)) {
	}
}

function initializeSubName(projectName) {
	nSubName = 9;
	subName = newArray(nSubName);

	subName[0] = "" + projectName;
	subName[1] = "1/2";
	subName[2] = "SD-";
	subName[3] = "561/488";
	subName[4] = "_s";
	subName[5] = "1:1:32";
	subName[6] = "_t";
	subName[7] = "1:3:170";
	subName[8] = ".TIF";

	return subName;
}

