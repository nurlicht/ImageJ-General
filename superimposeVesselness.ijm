macro "Main" {
	run("Close All");
	while(nImages) {
	}
	wait(1);
	
 	vesselnessDirectoryShort = "Vesselness";
 	vesselnessFileNameAppend = "Vesselness of ";
 	vesselnessFileExtension = ".tif";
 	
 	
 	rawDataPath = File.openDialog("Please select a measurement file");
	rawDataFile = File.name;
	rawDataFileWithoutExtension = File.nameWithoutExtension;
	rawDataDirectory = File.directory;
 	rawDataParent = File.getParent(rawDataPath);
 	rawDataHigherFolderIndex = lastIndexOf(rawDataParent,"\\");
 	rawDataHigherFolder = substring(rawDataDirectory, 0, rawDataHigherFolderIndex + 1);

 	vesselnessDirectory = rawDataHigherFolder + vesselnessDirectoryShort + "\\";
 	vesselnessFile = vesselnessFileNameAppend + rawDataFileWithoutExtension + vesselnessFileExtension;
 	vesselnessPath = vesselnessDirectory + vesselnessFile;
 	
	open(rawDataPath);
	while (!isOpen(rawDataFile)) {
	}
	wait(1);
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Split Channels");
	wait(1);
	close("C2-" + rawDataFile);
	wait(1);
	selectWindow("C1-" + rawDataFile);
	wait(1);
	rename(rawDataFile);
	while (!isOpen(rawDataFile)) {
	}
	wait(1);

	open(vesselnessPath);
	while (!isOpen(vesselnessFile)) {
	}
	wait(1);
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

	run("3D Viewer");
	wait(200);
	call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
	wait(10);
	call("ij3d.ImageJ3DViewer.add", rawDataFile, "None", rawDataFile, "0", "true", "true", "true", "1", "0");
	call("ij3d.ImageJ3DViewer.add", vesselnessFile, "None", vesselnessFile, "0", "true", "true", "true", "1", "0");
}
