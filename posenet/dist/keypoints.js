"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.partNames = [
    'nose', 'leftEye', 'rightEye', 'leftEar', 'rightEar', 'leftShoulder',
    'rightShoulder', 'leftElbow', 'rightElbow', 'leftWrist', 'rightWrist',
    'leftHip', 'rightHip', 'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle'
];
exports.NUM_KEYPOINTS = exports.partNames.length;
exports.partIds = exports.partNames.reduce(function (result, jointName, i) {
    result[jointName] = i;
    return result;
}, {});
var connectedPartNames = [
    ['leftHip', 'leftShoulder'], ['leftElbow', 'leftShoulder'],
    ['leftElbow', 'leftWrist'], ['leftHip', 'leftKnee'],
    ['leftKnee', 'leftAnkle'], ['rightHip', 'rightShoulder'],
    ['rightElbow', 'rightShoulder'], ['rightElbow', 'rightWrist'],
    ['rightHip', 'rightKnee'], ['rightKnee', 'rightAnkle'],
    ['leftShoulder', 'rightShoulder'], ['leftHip', 'rightHip']
];
exports.connectedPartIndeces = connectedPartNames.map(function (_a) {
    var jointNameA = _a[0], jointNameB = _a[1];
    return ([exports.partIds[jointNameA], exports.partIds[jointNameB]]);
});
