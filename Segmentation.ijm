macro "Main" {
	run("Close All");
	while(nImages) {
	}
	wait(1);
	
 	folderName = getDirectory("Please choose the folder containing (only 2-channel) images");
	fileList = getFileList(folderName);
	nFolderImages = lengthOf(fileList);
	//nFolderImages_ = 1;

	setBatchMode(true);
	wait(1);
	for (cntr = (nFolderImages - 1); cntr > -1; cntr--) {
		fileName = fileList[cntr];
		pathName = folderName + fileName;
		open(pathName);
		while (!isOpen(fileName)) {
		}
		wait(1);
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		run("Split Channels");
		wait(1);
		close("C2-" + fileName);
		wait(1);
		selectWindow("C1-" + fileName);
		wait(1);
		rename(fileName);
		while (!isOpen(fileName)) {
		}
		wait(1);
		run("FeatureJ Hessian", "largest middle smallest smoothing=1.0");
		hessianWindows = renameEigenimages(fileName);
		vesselness = evaluateVesselness(hessianWindows, fileName, folderName);
		close(fileName);
		while (isOpen(fileName)) {
		}
		wait(1);
	}
	setBatchMode("display and exit");
}

function renameEigenimages(fileName) {
	indexName = newArray("largest", "middle", "smallest");
	outputName = newArray("L1", "L2", "L3");
	for (cntr = 0; cntr < 3; cntr++) {
		imageName = fileName + " " + indexName[cntr] +" Hessian eigenvalues";
		while (!isOpen(imageName)) {
		}
		wait(1);
		selectWindow(imageName);
		wait(1);
		rename(outputName[cntr]);
		wait(1);
	}
	return outputName;
}

function evaluateVesselness(hessianWindows, fileName, folderName) {
	vesselnessThreshold = 28;
	selectWindow(hessianWindows[0]);
	wait(1);
	Stack.getDimensions(width, height, channels, slices, frames);
	if (channels > 1) {
		print("Error: " channels + " channels in Hessian Hyper-stack");
		return -1;
	} else if (frames > 1) {
		if (slices == 1) {
			slices = frames;
			frames = 1;
			Stack.setDimensions(channels, slices, frames);
		} else {
			print("Error: " frames + " frames in Hessian Hyper-stack");
			return -1;
		}
	}
	wait(1);
	n3D = width * height * slices;
	n3D_2 = n3D * 2;
	n3D_3 = n3D * 3;

	showStatus("Computing Vesselness (1/2)");
	L = newArray(n3D * 3);
	Cntr = 0;
	for (cntr = 0; cntr < 3; cntr++) {
		while (!isOpen(hessianWindows[cntr])) {
		}
		selectWindow(hessianWindows[cntr]);
		wait(1);
		for (z = 0; z < slices; z++) {
			Stack.setSlice(1 + z);
			for (y = 0; y < height; y++) {
				for (x = 0; x < width; x++) {
					L[Cntr++] = getPixel(x,y);
				}
			}
		}
		showProgress(cntr + 1, 3);
	}


	newTitle = "Vesselness of " + fileName;
	newImage(newTitle, "32-bit black", width, height, slices);
	while (!isOpen(newTitle)) {
	}
	selectWindow(newTitle);
	wait(1);

	Alpha = 0.5;
	Beta = 0.5;
	Array.getStatistics(L, min, max, mean, stdDev);
	C = max * 0.50;
	Alpha_ = 2 * pow(Alpha, 2);
	Beta_ = 2 * pow(Beta, 2);
	C_ = 2 * pow(C, 2);
	
	
	showStatus("Computing Vesselness (2/2)");
	Cntr = 0;
	for (z = 0; z < slices; z++) {
		setSlice(1 + z);
		for (y = 0; y < height; y++) {
			for (x = 0; x < width; x++) {
				L3 = L[Cntr + n3D_2];
				if (L3 > 0) {
					vesselness = 0;
				} else {
					L2 = L[Cntr + n3D];
					if (L2 > 0) {
						vesselness = 0;
					} else {
						L1 = L[Cntr];
						RA = L2 / L3;
						RB = L1 / sqrt(abs(L2 * L3));
						S = sqrt(pow(L1, 2) + pow(L2, 2) + pow(3, 2));
						vesselness = (1 - exp(-pow(RA, 2) / Alpha_)) * exp(-pow(RB, 2) / Beta_) *
									 (1 - exp(-pow(S, 2) / C_));
					}
				}
				setPixel(x, y, vesselness);
				Cntr++;
			}
		}
		showProgress(z + 1, slices);
	}
	run("8-bit");
	run("Enhance Contrast", "saturated=0");
	setThreshold(vesselnessThreshold, 255);
	wait(1);
	saveAs(".tif", folderName + newTitle);

	closeLFlag = true;
	if (closeLFlag) {
		for (cntr = 0; cntr < 3; cntr++) {
			close(hessianWindows[cntr]);
			while (isOpen(hessianWindows[cntr])) {
			}
		}
	}
	wait(10);
	showStatus("Vesselness file saved.");
	return newTitle;
}
