pragma solidity ^0.8.19;

interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface ISavingsDAI {
    function convertToAssets(uint256 shares) external view returns (uint256);
}

/**
 * @title sDAI Rate Provider
 * @notice Returns the value of sDAI in terms of DAI
 */
contract SavingsDAIRateProvider is IRateProvider {
    ISavingsDAI public constant sDAI = ISavingsDAI(0x83F20F44975D03b1b09e64809B757c47f942BEeA);

    /**
     * @return the value of sDAI in terms of DAI
     */
    function getRate() external view override returns (uint256) {
        return sDAI.convertToAssets(1e18);
    }
}