"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var keypoints_1 = require("../keypoints");
var util_1 = require("./util");
var util_2 = require("./util");
var poseChain = [
    ['nose', 'leftEye'], ['leftEye', 'leftEar'], ['nose', 'rightEye'],
    ['rightEye', 'rightEar'], ['nose', 'leftShoulder'],
    ['leftShoulder', 'leftElbow'], ['leftElbow', 'leftWrist'],
    ['leftShoulder', 'leftHip'], ['leftHip', 'leftKnee'],
    ['leftKnee', 'leftAnkle'], ['nose', 'rightShoulder'],
    ['rightShoulder', 'rightElbow'], ['rightElbow', 'rightWrist'],
    ['rightShoulder', 'rightHip'], ['rightHip', 'rightKnee'],
    ['rightKnee', 'rightAnkle']
];
var parentChildrenTuples = poseChain.map(function (_a) {
    var parentJoinName = _a[0], childJoinName = _a[1];
    return ([keypoints_1.partIds[parentJoinName], keypoints_1.partIds[childJoinName]]);
});
var parentToChildEdges = parentChildrenTuples.map(function (_a) {
    var childJointId = _a[1];
    return childJointId;
});
var childToParentEdges = parentChildrenTuples.map(function (_a) {
    var parentJointId = _a[0];
    return parentJointId;
});
function getDisplacement(i, point, displacements) {
    var numEdges = displacements.shape[2] / 2;
    return {
        y: displacements.get(point.y, point.x, i),
        x: displacements.get(point.y, point.x, numEdges + i)
    };
}
function decode(point, outputStride, height, width) {
    return {
        y: util_1.clamp(Math.round(point.y / outputStride), 0, height - 1),
        x: util_1.clamp(Math.round(point.x / outputStride), 0, width - 1)
    };
}
function traverseToTargetKeypoint(edgeId, sourceKeypoint, targetKeypointId, scoresBuffer, offsets, outputStride, displacements) {
    var _a = scoresBuffer.shape, height = _a[0], width = _a[1];
    var sourceKeypointIndeces = decode(sourceKeypoint.position, outputStride, height, width);
    var displacement = getDisplacement(edgeId, sourceKeypointIndeces, displacements);
    var displacedPoint = util_2.addVectors(sourceKeypoint.position, displacement);
    var displacedPointIndeces = decode(displacedPoint, outputStride, height, width);
    var offsetPoint = util_1.getOffsetPoint(displacedPointIndeces.y, displacedPointIndeces.x, targetKeypointId, offsets);
    var targetKeypoint = util_2.addVectors(displacedPoint, { x: offsetPoint.x, y: offsetPoint.y });
    var targetKeypointIndeces = decode(targetKeypoint, outputStride, height, width);
    var score = scoresBuffer.get(targetKeypointIndeces.y, targetKeypointIndeces.x, targetKeypointId);
    return { position: targetKeypoint, part: keypoints_1.partNames[targetKeypointId], score: score };
}
function decodePose(root, scores, offsets, outputStride, displacementsFwd, displacementsBwd) {
    var numParts = scores.shape[2];
    var numEdges = parentToChildEdges.length;
    var instanceKeypoints = new Array(numParts);
    var rootPart = root.part, rootScore = root.score;
    var rootPoint = util_2.getImageCoords(rootPart, outputStride, offsets);
    instanceKeypoints[rootPart.id] = {
        score: rootScore,
        part: keypoints_1.partNames[rootPart.id],
        position: rootPoint
    };
    for (var edge = numEdges - 1; edge >= 0; --edge) {
        var sourceKeypointId = parentToChildEdges[edge];
        var targetKeypointId = childToParentEdges[edge];
        if (instanceKeypoints[sourceKeypointId] &&
            !instanceKeypoints[targetKeypointId]) {
            instanceKeypoints[targetKeypointId] = traverseToTargetKeypoint(edge, instanceKeypoints[sourceKeypointId], targetKeypointId, scores, offsets, outputStride, displacementsBwd);
        }
    }
    for (var edge = 0; edge < numEdges; ++edge) {
        var sourceKeypointId = childToParentEdges[edge];
        var targetKeypointId = parentToChildEdges[edge];
        if (instanceKeypoints[sourceKeypointId] &&
            !instanceKeypoints[targetKeypointId]) {
            instanceKeypoints[targetKeypointId] = traverseToTargetKeypoint(edge, instanceKeypoints[sourceKeypointId], targetKeypointId, scores, offsets, outputStride, displacementsFwd);
        }
    }
    return instanceKeypoints;
}
exports.decodePose = decodePose;
