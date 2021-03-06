"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var tf = require("@tensorflow/tfjs");
var posenet_1 = require("./posenet");
describe('PoseNet', function () {
    var net;
    beforeAll(function (done) {
        posenet_1.load()
            .then(function (posenetInstance) {
            net = posenetInstance;
        })
            .then(done)
            .catch(done.fail);
    });
    describe('estimateSinglePose', function () {
        it('does not leak memory', function (done) {
            var canvas = document.createElement('canvas');
            canvas.width = 513;
            canvas.height = 513;
            var beforeTensors = tf.memory().numTensors;
            net.estimateSinglePose(canvas)
                .then(function () {
                expect(tf.memory().numTensors).toEqual(beforeTensors);
            })
                .then(done)
                .catch(done.fail);
        });
    });
    describe('estimateMultiplePoses', function () {
        it('does not leak memory', function (done) {
            var canvas = document.createElement('canvas');
            canvas.width = 513;
            canvas.height = 513;
            var beforeTensors = tf.memory().numTensors;
            net.estimateMultiplePoses(canvas)
                .then(function () {
                expect(tf.memory().numTensors).toEqual(beforeTensors);
            })
                .then(done)
                .catch(done.fail);
        });
    });
});
