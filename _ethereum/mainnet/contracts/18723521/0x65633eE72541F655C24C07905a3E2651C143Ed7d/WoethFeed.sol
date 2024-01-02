pragma solidity 0.6.7;

abstract contract WOETH {
    function totalAssets() external view virtual returns (uint256);
    function convertToAssets(uint256) external view virtual returns (uint256);
}

// WOETH / STETH feed following GEB's DSValue interface
contract WoethFeed {
    // --- Variables ---
    WOETH public immutable woeth;
    uint256 public constant WAD = 10**18;

    bytes32 public constant symbol = "woeth-oeth";

    constructor(address woethAddress) public {
        woeth = WOETH(woethAddress);
        require(WOETH(woethAddress).totalAssets() > 0, "invalid woeth address");
    }

    // --- Main Getters ---
    /**
     * @notice Fetch the latest result or revert if is is null
     **/
    function read() external view returns (uint256 result) {
        result = woeth.convertToAssets(WAD);
        require(result > 0, "invalid woeth price");
    }

    /**
     * @notice Fetch the latest result and whether it is valid or not
     **/
    function getResultWithValidity()
        external
        view
        returns (uint256 result, bool valid)
    {
        result = woeth.convertToAssets(WAD);
        valid = result > 0;
    }

    // --- Median Updates ---
    /*
     * @notice Remnant from other GEB medians
     */
    function updateResult(address feeReceiver) external {}
}