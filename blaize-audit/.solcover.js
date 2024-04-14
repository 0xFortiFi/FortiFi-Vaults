module.exports = {
    configureYulOptimizer: true, // (Experimental). Should resolve "stack too deep" in projects using ABIEncoderV2.
    skipFiles: [
        "vaults/interfaces/",
        "strategies/interfaces/",
        "fee-managers/interfaces/",
        "fee-calculators/interfaces/",
        "mock/",
        "from-dependencies/"
    ],
    mocha: {
        fgrep: "[skip-on-coverage]",
        invert: true
    }
};
