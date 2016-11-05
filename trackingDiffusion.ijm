macro "Main" {
	Initialize();
	clearLog();
	allParams = initializeAllParams();
	allParams = getLagMaxFromUser(allParams);
	allParams = decideDataType(allParams);
	XYTN = getTracksXYTN(allParams);
	allParams = setTracksInfo(XYTN, allParams);
	nSpotsPerTrackArray = getNTrackArray(XYTN);
	
	showCurvature = false; // true or false
	if (showCurvature) {
		allParams = correlationAnalysisAll(XYTN, allParams);
		allParams = PlotAllFitParams(allParams);
		allParams = PlotAllFitParamsHists(allParams);
	}
	
	PQTSJ = getPQTSJ(XYTN, allParams);
	allParams = PlotPQs(PQTSJ, allParams);
	allParams = getGroupBoundaries(PQTSJ, allParams);
	allParams = PlotPQs(PQTSJ, allParams);

	allParams = getSubTrajectories(PQTSJ, allParams);
	//allParams = visualizeTracksSubTrajectories(XYTN, allParams);
	allParams = getMSD_t(XYTN, PQTSJ, allParams);
	allParams = PlotMSD_t(allParams);
}

function isSameGroup(P1, P2, xMouse) {
	return (getGroup(P1, xMouse) == getGroup(P2, xMouse));
}

function getGroup(P, xMouse) {
	nMouse = lengthOf(xMouse);
	nGroups = nMouse + 2;
	pGroup = - 1;
	for (groupCntr = nGroups; (groupCntr > 1) && (pGroup < 0); groupCntr--) {
		if (groupCntr == nGroups) {
			minP = xMouse[groupCntr - 3];
			//maxP = maxP_;
			maxP = minP * 1e10;
		} else if (groupCntr == 2) {
			//minP = minP_;
			minP = 0;
			maxP = xMouse[groupCntr - 2];
		} else {
			minP = xMouse[groupCntr - 3];
			maxP = xMouse[groupCntr - 2];
		}
		if ((P >= minP) && (P <= maxP)) {
			pGroup = groupCntr;
		}
		//print("P = " + P + ", minP = " + minP + ", maxP = " + maxP + ", pGroup = " + pGroup);
	}
	//print("P = " + P + ", pGroup = " + pGroup);
	return pGroup;
}

function string2ArrayNumeric(s) {
	sArray = string2Array("" + s);
	nArray = lengthOf(sArray);
	dArray = newArray(nArray);
	for (cntr = 0; cntr < nArray; cntr++) {
		dArray[cntr] = parseFloat(sArray[cntr]);
	}
	return dArray;
}

function getSubTrajectories(PQTSJ, allParams) {
	nSSCan = parseInt(allParams[15]);
	if (nSSCan != 1) {
		print("Error: Only one value of 's' should be used.");
		return -1;
	}

	nSpotsPerTrackArray = string2Array("" + allParams[6]);
	nTracks = lengthOf(nSpotsPerTrackArray);

	xMouseArray = string2Array("" + allParams[11]);
	nMouse = lengthOf(xMouseArray);
	nGroups = nMouse + 2;
	xMouse = newArray(nMouse);
	for (cntr = 0; cntr < nMouse; cntr++) {
		xMouse[cntr] = parseFloat(xMouseArray[cntr]);
	}

	nP = lengthOf(PQTSJ) / 5;
	P = Array.slice(PQTSJ, 0 * nP, 1 * nP);
	T = Array.slice(PQTSJ, 2 * nP, 3 * nP);
	S = Array.slice(PQTSJ, 3 * nP, 4 * nP);
	s = S[0];
	minS = 6;
	maxS = minS;

	nSubTrajArray = newArray(nTracks);
	subTrajStartAll = newArray(0);
	subTrajEndAll = newArray(0);
	subTrajGroupAll = newArray(0);
	showStatus("Calculating Sub-trajectories");
	Cntr = 0;
	for (trackIndex = 0; trackIndex < nTracks; trackIndex++) {
		showProgress(trackIndex, nTracks);
		nCurrentTrack = nSpotsPerTrackArray[trackIndex];
		//XYT = getSingleTrackXYT(XYTN, nSpotsPerTrackArray, trackIndex);
		maxJ = floor(nCurrentTrack / s);
		subTrajStart = newArray(nCurrentTrack);
		subTrajEnd = newArray(nCurrentTrack);
		subTrajGroup = newArray(nCurrentTrack);
		for (j = 1; j <= maxJ; j++) {
			index1 = s * (j - 1);
			index2 = s * j - 1;
			if (j == 1) {
				subTraj = newArray(nCurrentTrack);
				nSubTrajs = 0;
				startPoint = index1;
				endPoint = index2;
				sameGroupFlag = true;
			} else {
				sameGroupFlag = isSameGroup(P[Cntr], P[Cntr - 1], xMouse);
				if (sameGroupFlag) {
					endPoint += s;
				} else {
					subTrajStart[nSubTrajs] = "" + startPoint;
					subTrajEnd[nSubTrajs] = "" + (endPoint - 1);
					subTrajGroup[nSubTrajs] = "" + getGroup(P[Cntr], xMouse);
					startPoint = endPoint;
					nSubTrajs++;
				}
				//print("trackIndex = " + trackIndex + ", j = " + j + ", Cntr = " + Cntr + ", P[Cntr] = " + (P[Cntr]) + ", sameGroupFlag = " + sameGroupFlag + ", nSubTrajs = " + nSubTrajs);
			}
			Cntr++;
		}
		if (sameGroupFlag) {
			subTrajStart[nSubTrajs] = "" + startPoint;
			subTrajEnd[nSubTrajs] = "" + endPoint;
			subTrajGroup[nSubTrajs] = "" + getGroup(P[Cntr - 1], xMouse);
			//print("trackIndex = " + trackIndex + ", j = " + j + ", Cntr = " + Cntr + ", P[Cntr - 1] = " + (P[Cntr - 1]) + ", sameGroupFlag = " + sameGroupFlag + ", nSubTrajs = " + nSubTrajs);
			nSubTrajs++;
		} else {
			//print("trackIndex = " + trackIndex + ", j = " + j + ", Cntr = " + Cntr + ", P[Cntr] = " + (P[Cntr]) + ", sameGroupFlag = " + sameGroupFlag + ", nSubTrajs = " + nSubTrajs);
		}
		//print("subTrajGroup array:");
		//Array.print(subTrajGroup);
		
		subTrajStart = Array.slice(subTrajStart, 0, nSubTrajs);
		subTrajEnd = Array.slice(subTrajEnd, 0, nSubTrajs);
		subTrajGroup = Array.slice(subTrajGroup, 0, nSubTrajs);
		
		//print("subTrajGroup array:");
		//Array.print(subTrajGroup);

		subTrajStartAll = Array.concat(subTrajStartAll, subTrajStart);
		subTrajEndAll = Array.concat(subTrajEndAll, subTrajEnd);
		subTrajGroupAll = Array.concat(subTrajGroupAll, subTrajGroup);
		
		//print("subTrajGroupAll array:");
		//Array.print(subTrajGroupAll);

		nSubTrajArray[trackIndex] = "" + nSubTrajs;
	}

	//waitForUser;wait(1);

	//print("In getSubTrajectories(): subTrajGroupAll = ");
	//Array.print(subTrajGroupAll ); 
	
	allParams[13] = "" + array2String(nSubTrajArray);
	allParams[14] = "" + array2String(subTrajStartAll);
	allParams[16] = "" + array2String(subTrajEndAll);
	allParams[21] = "" + array2String(subTrajGroupAll);

	//print("In getSubTrajectories(): allParams[21] = ");
	//print("" + allParams[21]); 
	
	return allParams;
}

function PlotMSD_t(allParams) {
	nSSCan = parseInt(allParams[15]);
	if (nSSCan != 1) {
		print("Error: Only one value of 's' should be used.");
		return -1;
	}

	tMin = parseInt(allParams[17]);
	tMax = parseInt(allParams[18]);
	tN = parseInt(allParams[19]);
	MSD = string2ArrayNumeric(allParams[20]);

	Array.getStatistics(MSD, min, max, mean, stdDev);

	tArray = newArray(tN);
	for (tCntr = tMin; tCntr <= tMax; tCntr++) {
		tArray[tCntr - tMin] = tCntr;
	}

	plotParams = newArray("1", "Group [1]", "Time", "MSD(t)", "blue", "1", "0", tMin, tMax, min, max);

	xMouse = string2ArrayNumeric("" + allParams[11]);
	nMouse = lengthOf(xMouse);
	nGroups = nMouse + 2;

	MSD_t = newArray(tN);
	D_t = newArray(tN);
	tgCntr = 0;
	for (groupCntr = nGroups; groupCntr > 1; groupCntr--) {
		for (tCntr = tMin; tCntr <= tMax; tCntr++) {
			MSD_t[tCntr - tMin] = MSD[tgCntr++];
			D_t[tCntr - tMin] = MSD_t[tCntr - tMin] / (4 * tCntr);
		}
		plotParams[1] = "MSD(t) of Group " + groupCntr;
		plotParams[3] = "MSD(t)" + groupCntr;
		plotCurve(tArray, MSD_t, plotParams);
		plotParams[1] = "D(t) of Group " + groupCntr;
		plotParams[3] = "D(t)" + groupCntr;
		//plotCurve(tArray, D_t, plotParams);
	}
	stackTitle = "MSD(t) Stack";
	run("Images to Stack", "name=[" + stackTitle + "] title=[MSD(t) of Group] use keep");
	while (!isOpen(stackTitle)) {
	}
	stackTitle = "D(t) Stack";
	//run("Images to Stack", "name=[" + stackTitle + "] title=[D(t) of Group] use keep");
	//while (!isOpen(stackTitle)) {
	//}
	return allParams;
}

function getMSD_t(XYTN, PQTSJ, allParams) {
	nSSCan = parseInt(allParams[15]);
	if (nSSCan != 1) {
		print("Error: Only one value of 's' should be used.");
		return -1;
	}

	nSpotsPerTrackArray = string2Array("" + allParams[6]);
	nTracks = lengthOf(nSpotsPerTrackArray);

	nSubTrajArray = string2ArrayNumeric("" + allParams[13]);
	subTrajStartAll = string2ArrayNumeric("" + allParams[14]);
	subTrajEndAll = string2ArrayNumeric("" + allParams[16]);
	subTrajGroupAll = string2ArrayNumeric("" + allParams[21]);
	xMouse = string2ArrayNumeric("" + allParams[11]);
	nMouse = lengthOf(xMouse);
	nGroups = nMouse + 2;

	P = Array.slice(PQTSJ, 0, lengthOf(PQTSJ) / 5);

	tMin = 6;
	tMax = 18;
	tN = tMax - tMin + 1;
	nMSD = tN * (nGroups - 1);
	MSD = newArray(nMSD);

	//print("subTrajGroupAll:");
	//Array.print(subTrajGroupAll);
	
	tgCntr = 0;
	for (groupCntr = nGroups; groupCntr > 1; groupCntr--) {
		for (tCntr = tMin; tCntr <= tMax; tCntr++) {
			showStatus("Calculating instantaneous distance MSD(t) ...");
			showProgress(tgCntr, nMSD);
			Cntr = 0;
			msd = 0;
			msdCntr = 0;
			for (trackIndex = 0; trackIndex < nTracks; trackIndex++) {
				nCurrentTrack = nSpotsPerTrackArray[trackIndex];
				nCurrentSubTrajs = nSubTrajArray[trackIndex];
				XYT = getSingleTrackXYT(XYTN, nSpotsPerTrackArray, trackIndex);
				X = Array.slice(XYT, 0 * nCurrentTrack, 1 * nCurrentTrack);
				Y = Array.slice(XYT, 1 * nCurrentTrack, 2 * nCurrentTrack);
				//T = Array.slice(XYT, 2 * nCurrentTrack, 3 * nCurrentTrack);
				for (subTrajCntr = 0; subTrajCntr < nCurrentSubTrajs; subTrajCntr++) {
					//print("subTrajGroupAll[Cntr] = " + (subTrajGroupAll[Cntr]));
					if (subTrajGroupAll[Cntr] == groupCntr) {
						subTrajStart = subTrajStartAll[Cntr];
						subTrajEnd = subTrajEndAll[Cntr];
						//print("subTrajCntr = " + subTrajCntr + " (out of " + nCurrentSubTrajs + ")");
						for (spotCntr = 1; spotCntr < (subTrajEnd - subTrajStart); spotCntr++) {
							nextIndex = subTrajStart + spotCntr;
							if (tCntr <= nextIndex) {
							//if (tCntr == nextIndex) {
								//vNorm(x1, y1, x2, y2);
								msd += (vNorm2(X[subTrajStart], Y[subTrajStart], X[nextIndex], Y[nextIndex]));
								msdCntr++;
							}
						}
					}
					Cntr++;
				}
			}
			//print("msd = " + msd + ", msdCntr = " + msdCntr + ", tgCntr = " + tgCntr + " (out of " + nMSD + ")");
			msd /= msdCntr;
			MSD[tgCntr++] = "" + msd;
		}
	}
	showStatus("");

	allParams[17] = "" + tMin;					// tMin
	allParams[18] = "" + tMax;					// tMax
	allParams[19] = "" + tN;					// tN
	allParams[20] = "" + array2String(MSD);		// MSD
	
	return allParams;
}

function getGroupBoundaries(PQTSJ, allParams) {
	plotTitle = allParams[12];
	selectWindow_(plotTitle);
	waitForUser("Please select Group boundaries; from the highest; SHIFT+Click to end");
	wait(1);
	selectWindow_(plotTitle);
	xMouseArray = newArray(0);
	x_ = newArray(1);
	continueFlag = true;
	while (continueFlag) {
		selectWindow_(plotTitle);
		run("Select None");
		pointXYShift = getPoint();
		x_[0] = pointXYShift[0];
		toScaled(x_[0]);
		appendFlag = (lengthOf(xMouseArray) == 0);
		if (!appendFlag) {
			appendFlag = (xMouseArray[0] !=  x_[0]);
		}
		if (appendFlag) {
			xMouseArray = Array.concat(x_, xMouseArray);
			continueFlag = (pointXYShift[2] == 0);
		}
	}
	allParams[11] = "" + array2String(xMouseArray);
	wait(10);
	close_(plotTitle);
	print("xMouseArray: ");
	Array.print(xMouseArray);
	print(" ");
	
	return allParams;
}

function getPoint() {
	flags = 0;
	x2 = -1;
	y2 = -1;
	flags2 = -1;
	shift = 1;
	leftButton = 16;
	msDebounceTime = 20;
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

function PlotPQs(PQTSJ, allParams) {
	nP = lengthOf(PQTSJ) / 5;
	if (nP == 0) {
		print("Error: The PQTSJ array is empty and P-Q cannot be plotted.");
		return -1;
	}
	P = Array.slice(PQTSJ, 0 * nP, 1 * nP);
	Q = Array.slice(PQTSJ, 1 * nP, 2 * nP);
	xMouseArray = string2Array("" + allParams[11]);
	nXMouseArray = lengthOf(xMouseArray);

	plotCreate = true;
	plotTitle = "Distance vs. Displacement";
	xLabel = "Displacement";
	yLabel = "Distance";
	color = "blue";
	plotShow = (nXMouseArray == 0);
	plotParams = newArray(plotCreate, plotTitle, xLabel, yLabel, color, plotShow, "1");
	if (isOpen(plotTitle)) {
		close_(plotTitle);
	}
	plotCurve(P, Q, plotParams);

	if (!plotShow) {
		nLines = nXMouseArray;
		Array.getStatistics(Q, min, max, mean, stdDev);
		y = newArray(min, max);
		for (cntr = 0; cntr < nLines; cntr++) {
			X = parseFloat(xMouseArray[cntr]);
			x = newArray(X, X);
			plotCreate = false;
			color = "red";
			plotShow = (cntr == (nLines - 1));
			plotParams = newArray(plotCreate, plotTitle, xLabel, yLabel, color, plotShow, "1", 0, 0, 0, 0, "lines");
			plotCurve(x, y, plotParams);
		}
	} else {
		allParams[12] = "" + plotTitle;
	}
	return allParams;
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

function getPQTSJ(XYTN, allParams) {
	nSSCan = parseInt(allParams[15]);
	nSpotsPerTrackArray = string2Array("" + allParams[6]);
	nTracks = lengthOf(nSpotsPerTrackArray);
	Array.getStatistics(nSpotsPerTrackArray, min, max, mean, stdDev);
	nSJMax = pow(max, 2) * nTracks;
	P = newArray(nSJMax);
	Q = newArray(nSJMax);
	T = newArray(nSJMax);
	S = newArray(nSJMax);
	J = newArray(nSJMax);
	
	showStatus("Calculating 'displacement-distance' of sub-trajectories");
	Cntr = 0;
	for (trackIndex = 0; trackIndex < nTracks; trackIndex++) {
		showProgress(trackIndex, nTracks);
		nCurrentTrack = nSpotsPerTrackArray[trackIndex];
		XYT = getSingleTrackXYT(XYTN, nSpotsPerTrackArray, trackIndex);
		nSpots = lengthOf(XYT) / 3;
		X = Array.slice(XYT, 0 * nSpots, 1 * nSpots);
		Y = Array.slice(XYT, 1 * nSpots, 2 * nSpots);
		
		if (nSSCan == 1) {
			minS = 6;
			maxS = minS;
		} else {
			minS = 2;
			maxS = minOf(20, floor(nCurrentTrack / 2));
		}
		for (s = minS; s <= maxS; s++) {
			maxJ = floor(nCurrentTrack / s);
			for (j = 1; j <= maxJ; j++) {
				index1 = s * (j - 1);
				index2 = s * j - 1;
				p = vNorm(X[index1], Y[index1], X[index2], Y[index2]);
			
				q = 0;
				for (n = 1; n < s; n++) {
					index1 = s * (j - 1) + n - 1;
					index2 = index1 + 1;
					q += (vNorm(X[index1], Y[index1], X[index2], Y[index2]));
				}
				
				P[Cntr] = p;
				Q[Cntr] = q;
				T[Cntr] = trackIndex;
				S[Cntr] = s;
				J[Cntr] = j;
				
				Cntr++;
			}
		}
	}
	P = Array.slice(P, 0, Cntr);
	Q = Array.slice(Q, 0, Cntr);
	T = Array.slice(T, 0, Cntr);
	S = Array.slice(S, 0, Cntr);
	J = Array.slice(J, 0, Cntr);
	
	PQTSJ = Array.concat(P, Q);
	PQTSJ = Array.concat(PQTSJ, T);
	PQTSJ = Array.concat(PQTSJ, S);
	PQTSJ = Array.concat(PQTSJ, J);
	showStatus("");
	return PQTSJ;
}

function getPQ(XYT, s, j) {
	nSpots = lengthOf(XYT) / 3;
	X = Array.slice(XYT, 0 * nSpots, 1 * nSpots);
	Y = Array.slice(XYT, 1 * nSpots, 2 * nSpots);
	T = Array.slice(XYT, 2 * nSpots, 3 * nSpots);

	index1 = s * (j - 1);
	index2 = s * j - 1;
	p = vNorm(X[index1], Y[index1], X[index2], Y[index2]);

	q = 0;
	for (n = 1; n < s; n++) {
		index1 = s * (j - 1) + n - 1;
		index2 = index1 + 1;
		q += vNorm(X[index1], Y[index1], X[index2], Y[index2]);
	}

	pq = newArray(p, q);
	return pq;
}

function vNorm2(x1, y1, x2, y2) {
	return pow(x2 - x1, 2) + pow(y2 - y1, 2);
}

function vNorm(x1, y1, x2, y2) {
	return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
}

function getLagMaxFromUser(allParams) {
	lagMax = getLagMax(allParams);
	Dialog.create("Maximum Lag Selection");
	Dialog.addNumber("Maximum Lag", lagMax);
	Dialog.show();
	lagMax = Dialog.getNumber();
	allParams = setLagMax(allParams, lagMax);
	print("A maximum lag value of " + lagMax + " was selected by the user.");
	return allParams;
}

function PlotAllFitParamsHists(allParams) {
	nTracks = parseInt("" + allParams[5]);
	nFitParams = parseInt("" + allParams[7]);
	fitParamsArray = string2Array("" + allParams[8]);
	print(" ");
	print("lengthOf(fitParamsArray) = " + (lengthOf(fitParamsArray)));

	diffusionRegime = newArray(nTracks);
	diffusionStrength = newArray(nTracks);
	for (cntr = 0; cntr < nTracks; cntr++) {
		diffusionRegime[cntr] = parseFloat("" + fitParamsArray[nFitParams * cntr + 2]);
		diffusionStrength[cntr] = parseFloat("" + fitParamsArray[nFitParams * cntr + 1]);
	}

	xyzHist = evaluateHistogram(diffusionRegime);
	x = Array.slice(xyzHist, 0 * nTracks, 1 * nTracks);
	y = Array.slice(xyzHist, 1 * nTracks, 2 * nTracks);
	z = Array.slice(xyzHist, 2 * nTracks, 3 * nTracks);
	/*
	plotCreate = true;
	plotTitle = "Histogram of Regime of Diffusion";
	xLabel = "Diffusion Regime: Active(+), Normal(zero), or Anomalous/Confined(-)";
	yLabel = "Counts";
	color = "red";
	plotShow = true;
	plotParams = newArray(plotCreate, plotTitle, xLabel, yLabel, color, plotShow, "1");
	plotCurve(x, y, plotParams);
	*/
	plotCreate = true;
	plotTitle = "Cumulative Histogram of Regime of Diffusion";
	xLabel = "Diffusion Regime: Active(+), Normal(zero), or Anomalous/Confined(-)";
	yLabel = "Cumulative Fraction";
	color = "red";
	plotShow = true;
	plotParams = newArray(plotCreate, plotTitle, xLabel, yLabel, color, plotShow, "1");
	plotCurve(x, z, plotParams);
	
	xyzHist = evaluateHistogram(diffusionStrength);
	x = Array.slice(xyzHist, 0 * nTracks, 1 * nTracks);
	y = Array.slice(xyzHist, 1 * nTracks, 2 * nTracks);
	z = Array.slice(xyzHist, 2 * nTracks, 3 * nTracks);
	/*
	plotCreate = true;
	plotTitle = "Histogram of Strength of Diffusion";
	xLabel = "Diffusion Strength";
	yLabel = "Counts";
	color = "red";
	plotShow = true;
	plotParams = newArray(plotCreate, plotTitle, xLabel, yLabel, color, plotShow, "1");
	plotCurve(x, y, plotParams);
	*/
	plotCreate = true;
	plotTitle = "Cumulative Histogram of Strength of Diffusion";
	xLabel = "Diffusion Strength";
	yLabel = "Cumulative Fraction";
	color = "red";
	plotShow = true;
	plotParams = newArray(plotCreate, plotTitle, xLabel, yLabel, color, plotShow, "1");
	plotCurve(x, z, plotParams);
	
	return allParams;
}

function evaluateHistogram(inArray) {
	//print("inArray:");Array.print(inArray);
	a = arrayClone(inArray);
	//print("a:");Array.print(a);
	N = lengthOf(a);
	Array.sort(a);
	xHist = newArray(N);
	yHist = newArray(N);

	xHist[0] = a[0];
	yHist[0] = 1;
	histCntr = 0;
	for (cntr = 1; cntr < N; cntr++) {
		if (a[cntr] == xHist[histCntr]) {
			yHist[histCntr]++;
		} else {
			yHist[++histCntr] = 1;
			xHist[histCntr] = a[cntr];
		}
		//print("histCntr = " + histCntr + ", xHist[histCntr] = " + (xHist[histCntr]) + ", yHist[histCntr] = " + (yHist[histCntr]) + ", a[cntr] = " + (a[cntr]));
	}
	histCntr++;
	xHist = Array.slice(xHist, 0, histCntr);
	yHist = Array.slice(yHist, 0, histCntr);

	zHist = newArray(histCntr);
	sumY = 0;
	for (cntr = 0; cntr < histCntr; cntr++) {
		sumY += yHist[cntr];
		zHist[cntr] = sumY / N;
	}
	xyHist = Array.concat(xHist, yHist);
	xyzHist = Array.concat(xyHist, zHist);
	return xyzHist;
}

function arrayClone(inArray) {
	nArray = lengthOf(inArray);
	outArray = newArray(nArray);
	for (cntr = 0; cntr < nArray; cntr++) {
		outArray[cntr] = inArray[cntr];
	}
	return outArray;
}

function PlotAllFitParams(allParams) {
	nTracks = parseInt("" + allParams[5]);
	nFitParams = parseInt("" + allParams[7]);
	fitParamsArray = string2Array("" + allParams[8]);
	print(" ");
	print("lengthOf(fitParamsArray) = " + (lengthOf(fitParamsArray)));

	x = newArray(nTracks);
	y = newArray(nTracks);
	for (cntr = 0; cntr < nTracks; cntr++) {
		x[cntr] = parseFloat("" + fitParamsArray[nFitParams * cntr + 2]);
		y[cntr] = parseFloat("" + fitParamsArray[nFitParams * cntr + 1]);
	}
	
	
	plotCreate = true;
	plotTitle = "Strnegth and Regime of Diffusion";
	xLabel = "Diffusion Regime: Active(+), Normal(zero), or Anomalous/Confined(-)";
	yLabel = "Diffusion Strength";
	color = "red";
	plotShow = true;
	plotParams = newArray(plotCreate, plotTitle, xLabel, yLabel, color, plotShow, "1");
	plotCurve(x, y, plotParams);
	return allParams;
}

function plotCurve(x, y, plotParams) {
	plotCreateFlag = parseInt(plotParams[0]);
	plotTitle = plotParams[1];
	xTitle = plotParams[2];
	yTitle = plotParams[3];
	curveColor = plotParams[4];
	plotShowFlag = parseInt(plotParams[5]);
	plotLimAutoFlag = parseInt(plotParams[6]);

	if (!plotLimAutoFlag) {
		xMin = parseFloat(plotParams[7]);
		xMax = parseFloat(plotParams[8]);
		yMin = parseFloat(plotParams[9]);
		yMax = parseFloat(plotParams[10]);
	} else {
		Array.getStatistics(x, xMin, xMax, xMean, xStdDev);
		Array.getStatistics(y, yMin, yMax, yMean, yStdDev);
	}

	if (lengthOf(plotParams) > 11) {
		plotType = plotParams[11];
	} else {
		plotType = "triangles";
	}

	if (plotCreateFlag) {
		print("Plot " + plotTitle + " was created.");
	}
	//print(" A curve with " + (lengthOf(x)) + " data points will be added to Plot " + plotTitle + ".X and Y are:");
	//Array.print(x);Array.print(y);

	if (plotCreateFlag) {
		Plot.create(plotTitle, xTitle, yTitle); 
		Plot.setLimits(xMin, xMax, yMin, yMax);
	}
	Plot.setColor(curveColor);
	Plot.add(plotType, x, y);
	if (plotShowFlag) {
		nImages_ = nImages;
		Plot.show();
		while (nImages == nImages_) {
		}
	}
}

function correlationAnalysisAll(XYTN, allParams) {
	nAllSpots = lengthOf(XYTN) / 4;
	nTracks = parseInt("" + allParams[5]);
	nSpotsPerTrackArray = string2Array("" + allParams[6]);

	X = Array.slice(XYTN, 0 * nAllSpots, 1 * nAllSpots);
	Y = Array.slice(XYTN, 1 * nAllSpots, 2 * nAllSpots);
	T = Array.slice(XYTN, 2 * nAllSpots, 3 * nAllSpots);
	startIndex = 0;
	setBatchMode(true);
	showStatus("Calculating diffusion parameters ...");
	for (cntr = 0; cntr < nTracks; cntr++) {
		showProgress(cntr, nTracks);
		nSpots = parseInt(nSpotsPerTrackArray[cntr]);
		x = Array.slice(X, startIndex, startIndex + nSpots);
		y = Array.slice(Y, startIndex, startIndex + nSpots);
		t = Array.slice(T, startIndex, startIndex + nSpots);
		startIndex += nSpots;
		XYT = Array.concat(x,y);
		XYT = Array.concat(XYT, t);
		allParams = setCurrentTrackIndex(allParams, cntr);
		allParams = correlationAnalysis(XYT, allParams);
	}
	nImages_ = nImages;
	run("Images to Stack", "name=Diffusion_Stack title=[Track #] use");
	while (nImages != (nImages_ - nTracks + 1)) {
	}
	wait(1);
	setBatchMode("exit and display");
	return allParams;
}

function getSingleTrackXYT(XYTN, nSpotsPerTrackArray, trackIndex) {
	nAllSpots = lengthOf(XYTN) / 4;
	X = Array.slice(XYTN, 0 * nAllSpots, 1 * nAllSpots);
	Y = Array.slice(XYTN, 1 * nAllSpots, 2 * nAllSpots);
	T = Array.slice(XYTN, 2 * nAllSpots, 3 * nAllSpots);

	startEndIndex = getTrackStartEndIndex(nSpotsPerTrackArray, trackIndex);
	x = Array.slice(X, startEndIndex[0], startEndIndex[1]);
	y = Array.slice(Y, startEndIndex[0], startEndIndex[1]);
	t = Array.slice(T, startEndIndex[0], startEndIndex[1]);

	XY = Array.concat(x, y);
	XYT = Array.concat(XY, t);
	return XYT;
}

function getTrackStartEndIndex(nSpotsPerTrackArray, trackIndex) {
	startIndex = 0;
	if (trackIndex > 0) {
		for (cntr = 0; cntr < trackIndex; cntr++) {
			startIndex += parseInt(nSpotsPerTrackArray[cntr]);
		}
	}
	endIndex = startIndex + parseInt(nSpotsPerTrackArray[trackIndex]);
	startEndIndex = newArray(startIndex, endIndex);
	return startEndIndex;
}

function getTrackStartIndex(nSpotsPerTrackArray, trackIndex) {
	startIndex = 0;
	if (tracIndex > 0) {
		for (cntr = 0; cntr < trackIndex; cntr++) {
			startIndex += parseInt(nSpotsPerTrackArray[cntr]);
		}
	}
	return startIndex;
}

function getTrackNSpots(nSpotsPerTrackArray, trackIndex) {
	return parseInt(nSpotsPerTrackArray[trackIndex]);
}

function getTracksXYTN(allParams) {
	if (isSimulatedData(allParams)) {
		XYTN = synthesizePath(allParams);
	} else {
		XYTN = getTrackMateXYTN(allParams);
	}
	return XYTN;
}

function setTracksInfo(XYTN, allParams) {
	//simulateFlag = isSimulatedData(allParams);
	nSpotsPerTrackArray = getNTrackArray(XYTN);
	nTracks = lengthOf(nSpotsPerTrackArray);

	print("Number of tracks = " + nTracks);

	
	allParams [5] = "" + nTracks;
	allParams[6] = "" + array2String(nSpotsPerTrackArray);
	return allParams;
}

function initializeAllParams() {
	nAllParams = 25;
	allParams = newArray(nAllParams);

	allParams[0] = "" + 1;						// simulateFlag
	allParams[1] = "" + 0;						// nX
	allParams[2] = "" + 0;						// nY
	allParams[3] = "" + 0;						// nT
	allParams[4] = "" + "";						// spotStatisticsPath
	allParams[5] = "" + 0;						// nTracks
	allParams[6] = "" + "";						// nSpotsPerTrackArray
	allParams[7] = "" + 3;						// nFitParams
	allParams[8] = "" + "";						// fitParamsArray
	allParams[9] = "" + 0;						// currentTrackIndex
	allParams[10] = "" + 20;					// lagMax
	allParams[11] = "" + "";					// xMouseArray
	allParams[12] = "" + "";					// originalPQPlotTitle
	allParams[13] = "" + 0;						// nSubTrajArrayString
	allParams[14] = "" + 0;						// subTrajStartAllString
	allParams[15] = "" + 1;						// nSSCan					
	allParams[16] = "" + 0;						// subTrajEndAllString
	allParams[17] = "" + 0;						// tMin
	allParams[18] = "" + 0;						// tMax
	allParams[19] = "" + 0;						// tN
	allParams[20] = "" + 0;						// MSD
	allParams[21] = "" + 0;						// subTrajGroupAllString
	
	//allParams[] = "" + ;						//
	return allParams;
}

function setLagMax(allParams, lagMax) {
	allParams[10] = "" + lagMax;
	return allParams;
}

function getLagMax(allParams) {
	lagMax = parseFloat("" + allParams[10]);
	return lagMax;
}

function setCurrentTrackIndex(allParams, currentIndex) {
	allParams[9] = "" + currentIndex;
	return allParams;
}

function getCurrentTrackIndex(allParams) {
	return parseInt("" + allParams[9]);
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

	closeAllUniqueWindows();
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

function closeAllUniqueWindows() {
	wait(1000);
	list = getList("window.titles");
	listLength = list.length;
	if (listLength > 0) {
		for (i = 0; i < listLength; i++) {
			if ((list[i] != "Log") && (list[i] != "Global Cell Table")){
				while (isOpen(list[i])) {
					selectWindow(list[i]);
					run("Close");
					wait(100);
					print("Window " + list[i] + " was closed.");
				}
				wait(1);
			}
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

function synthesizePath(allParams) {
	nX = parseInt(allParams[1]);
	nY = parseInt(allParams[2]);
	nPoints = parseInt(allParams[3]);

	x = newArray(nPoints);
	y = newArray(nPoints);
	t = newArray(nPoints);
	ID = newArray(nPoints);

	xMin = 0;
	xMax = nX - 1;
	x[0] = floor(nX / 2);
	dx = maxOf(1, floor(nX * 0.04));

	yMin = xMin;
	yMax = xMax;
	y[0] = x[0];
	dy = dx;

	t[0] = 0;
	ID[0] = 0;

	xDiameter = 10;
	yDiameter = xDiameter;
	xDiameterHalf = floor(xDiameter / 2);
	yDiameterHalf = floor(yDiameter / 2);
	newImage("synthesized Tracks", "8-bit", nX, nX, 1);

	makeOval(x[0] - xDiameterHalf, y[0] - yDiameterHalf,xDiameter, yDiameter);
	Overlay.addSelection("", 0 ,"#" + toHex(0xff0000));
	
	for (cntr = 1; cntr < nPoints; cntr++) {
		x[cntr] = clipValue(x[cntr - 1] + floor(dx * 2 * (random - 0.5)), xMin, xMax);
		y[cntr] = clipValue(y[cntr - 1] + floor(dy * 2 * (random - 0.5)), yMin, yMax);
		t[cntr] = cntr;
		ID[cntr] = 0;

		makeOval(x[cntr] - xDiameterHalf, y[cntr] - yDiameterHalf,xDiameter, yDiameter);
		fraction = round(255 * cntr / (nPoints - 1));
		color = toHex(fraction * (- 0x010000 + 0x000001) + 0xff0000);
		nColor = lengthOf(color);
		if (nColor < 6) {
			for (cntr2 = 0; cntr2 < (6 - nColor); cntr2++) {
				color = "0" + color;
			}
		}
		Overlay.addSelection("", 0, "#" + color);
	}
	Overlay.show();
	run("Select None");
	//run("Set... ", "zoom=400 x=" + getWidth + " y=" + getHeight);
	XYTN = Array.concat(x, y);
	XYTN = Array.concat(XYTN, t);
	XYTN = Array.concat(XYTN, ID);
	return XYTN;
}

function waitForWindow(wTitle) {
	while(!isOpen(wTitle)) {
	}
}

function clipValue(x, xMin, xMax) {
	return minOf(xMax, maxOf(x, xMin));
}

function getTrackMateXYTN(allParams) {
	spotStatisticsPath = "" + allParams[4];
	if (isOpen("Results")) {
		//closeWindow("Results");
	}
	run("Clear Results");
	run("Results... ", "open=[" + spotStatisticsPath + "]");
	waitForWindow("Results");

	nSpots = nResults;
	spotPositionX = newArray(nSpots);
	spotPositionY = newArray(nSpots);
	spotPositionT = newArray(nSpots);
	spotTrackID = newArray(nSpots);
	for (cntr = 0; cntr < nSpots; cntr++) {
		spotPositionX[cntr] = getResult("POSITION_X", cntr);
		spotPositionY[cntr] = getResult("POSITION_Y", cntr);
		spotPositionT[cntr] = getResult("FRAME", cntr);
		spotTrackID[cntr] = getResult("TRACK_ID", cntr);
	}
	XYTN = Array.concat(spotPositionX, spotPositionY);
	XYTN = Array.concat(XYTN, spotPositionT);
	XYTN = Array.concat(XYTN, spotTrackID);
	return XYTN;
}

function getNTrackArray(XYTN) {
	nSpots = lengthOf(XYTN) / 4;
	spotTrackID = Array.slice(XYTN, 3 * nSpots, 4 * nSpots);
	//print("spotTrackID: ");Array.print(spotTrackID);waitForUser;wait(1);
	
	nTracks = 0;
	lastTrackID = spotTrackID[0];
	currentNTrack = 1;
	nTrackArray = newArray(nSpots);
	for (cntr = 1; cntr < nSpots; cntr++) {
		currentTrackID = spotTrackID[cntr];
		if (currentTrackID != lastTrackID) {
			nTrackArray[nTracks++] = currentNTrack;
			currentNTrack = 1;
			lastTrackID = currentTrackID;
		} else {
			currentNTrack++;
		}
	}
	nTrackArray[nTracks++] = currentNTrack;
	nTrackArray = Array.slice(nTrackArray, 0, nTracks);
	return nTrackArray;
}

function correlationAnalysis(XYT, allParams) {
	nPoints = lengthOf(XYT) / 3;
	x = Array.slice(XYT, 0 * nPoints, 1 * nPoints);
	y = Array.slice(XYT, 1 * nPoints, 2 * nPoints);
	t = Array.slice(XYT, 2 * nPoints, 3 * nPoints);
	currentTrackIndex = getCurrentTrackIndex(allParams);
	nTracks = parseInt("" + allParams[5]);
	

	print(" ");
	print("Analyzing track #" + (currentTrackIndex + 1) + " (out of " + nTracks + " tracks)");
	
	nMax = getLagMax(allParams);
	N = lengthOf(x);
	lagMax = t[N - 1] - t[0];
	//print("The t array is:");Array.print(t);
	nMax = minOf(nMax , lagMax);
	corrFunction = newArray(nMax);
	lagVariable = newArray(nMax);
	
	for (lagCntr = 1; lagCntr <= nMax; lagCntr++) {
		lagVariable[lagCntr - 1] = lagCntr;
		dummy_1 = 0;
		dummy_2 = 0;
		for (cntr = 0; cntr < (N - lagCntr); cntr++) {
			if ( (t[cntr + lagCntr] - t[cntr] ) == lagCntr) {
				dummy_1 += pow(x[cntr + lagCntr]-x[cntr],2) + pow(y[cntr + lagCntr]-y[cntr],2) ;
				dummy_2++;
			}
		}
		corrFunction[lagCntr - 1] = dummy_1 / dummy_2;
		print(dummy_2 + " pairs used for a time lag of " + lagCntr);
	}

	allParams = curveFit(lagVariable, corrFunction, allParams);
	nFitParams = parseInt("" + allParams[7]);
	fitParamsArray = string2Array("" + allParams[8]);
	nCurrentFitParamsArray = lengthOf(fitParamsArray);
	diffRegime = parseFloat("" + fitParamsArray[nCurrentFitParamsArray - 1]);
	diffStrength = parseFloat("" + fitParamsArray[nCurrentFitParamsArray - 2]);
	

	Array.getStatistics(corrFunction,corrMin,corrMax,corrMean,corrStd);
	Array.getStatistics(lagVariable,LagMin,LagMax,LagMean,LagStd);
	Plot.create("Track #" + (1 + currentTrackIndex) + " (Regime, Strength) = (" + diffRegime + ", " + diffStrength + ")",
				"Lag Time (" + fromCharCode(0x0394) + "t)", 
				"Mean Square Distance (d" + fromCharCode(0x00B2) + ")",
				lagVariable, corrFunction);
	Plot.setLimits(LagMin, LagMax, corrMin, corrMax);	
	nImages_ = nImages;
	Plot.show;
	while (nImages_ == nImages) {
	}
	wait(1);

	
	return allParams;
}

function decideDataType(allParams) {
	items = newArray("Simulate data", "Load data");
	Dialog.create("Correlation Analysis of a track");
	Dialog.addRadioButtonGroup("Source of data", items, 2, 1, items[1]);
	Dialog.addHelp("http://www.nature.com/mt/journal/v19/n7/fig_tab/mt2011102f2.html#figure-title");
	Dialog.show();
	simulateFlag = (Dialog.getRadioButton() == items[0]);
	allParams[0] = "" + simulateFlag;
	if (simulateFlag) {
		nX = 300;
		nY = 300;
		nT = 200;
		allParams[1] = "" + nX;
		allParams[2] = "" + nY;
		allParams[3] = "" + nT;
	} else {
		spotStatisticsPath = File.openDialog("Please select the 'Spots' output file of TrackMate");
		allParams[4] = "" + spotStatisticsPath;
	}
	return allParams;
}

function isSimulatedData(allParams) {
	return parseInt(allParams[0]);
}

function array2String(x) {
	N = lengthOf(x);
	xString = "";
	for (cntr = 0; cntr < N; cntr++) {
		xString += "" + x[cntr];
		if (cntr < (N - 1)) {
			xString += "" + ", ";
		}
	}

	logFlag = false;
	if (logFlag) {
		print("The following " + N + "-element array was converted to a single string:");
		for (cntr = 0; cntr < N; cntr++) {
			print("x[" + cntr + "] = " + x[cntr]);
		}
		print(xString);
	}

	return xString;
}

function string2Array(xString) {
	nString = lengthOf(xString);

	if (nString == 0) {
		x = newArray(nString);
		return x;
	}

	N = 0;
	for (cntr = 0; cntr < nString; cntr++) {
		if (matches(substring(xString, cntr, cntr + 1), ",")) {
			N++;
		}
	}
	if (N == 0) {
		x = newArray(1);
		x[0] = "" + xString;
		return x;
	}

	N = 0;
	currentCommaIndex = 0;
	commaIndexArray = newArray(N);
	while (currentCommaIndex >= 0) {
		//print("xString = " + xString + ", currentCommaIndex = " + currentCommaIndex);
		currentCommaIndex = indexOf(xString, ",", currentCommaIndex + 1);
		if (currentCommaIndex >= 0) {
			N++;
			commaIndexArray = Array.concat(commaIndexArray, currentCommaIndex);
		}
	}

	x = newArray(N + 1);
	if (N > 0) {
		firstIndex = 0;
		lastIndex = commaIndexArray[0] - 1;
		x[0] = "" + substring(xString, firstIndex, lastIndex + 1);
		if (N > 1) {
			for (cntr = 1; cntr < N; cntr++) {
				firstIndex = commaIndexArray[cntr - 1] + 2;
				lastIndex = commaIndexArray[cntr] - 1;
				x[cntr] = "" + substring(xString, firstIndex, lastIndex + 1);  
			}
		}
		firstIndex = commaIndexArray[N - 1] + 2;
		lastIndex = nString - 1;
		x[N] = "" + substring(xString, firstIndex, lastIndex + 1);
	} else {
		x[0] = "" + xString;
	}

	logFlag = false;
	if (logFlag) {
		print("The following string was converted into a " + (N + 1) + "-element array:");
		print(xString);
		for (cntr = 0; cntr <= N; cntr++) {
			print("x[" + cntr + "] = " + x[cntr]);
		}
	}

	return x;
}

function curveFit(x, y, allParams) {
	nFitParams = parseInt("" + allParams[7]);
	fitParamsArray = string2Array("" + allParams[8]);
	currentTrackIndex = parseInt("" + allParams[9]);
	
	Fit.doFit("y = a + b * x + c * x * x", x, y);
	fitNParams = Fit.nParams;
	currentFitParams = newArray(fitNParams);
	Factor = 10000;
	for (cntr = 0; cntr < fitNParams; cntr++) {
		currentFitParams[cntr] = Factor * Fit.p(cntr);
	}
	
	logFlag = true;
	if (logFlag) {
		print("Diffusion curve parameters: <r^2> = a + b * (dt) + c * (dt)^2");
		print("a = " + (currentFitParams[0]) + ", b = " + (currentFitParams[1]) + ", c = " + (currentFitParams[2]));
	}
	
	fitParamsArray = Array.concat(fitParamsArray, currentFitParams);
	allParams[8] = "" + array2String(fitParamsArray);

	return allParams;
}
