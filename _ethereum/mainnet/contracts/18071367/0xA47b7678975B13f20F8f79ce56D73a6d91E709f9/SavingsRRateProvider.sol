pragma solidity ^0.8.19;

interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface IERC4626 {
    function convertToAssets(uint256 shares) external view returns (uint256);
}

/**
 * @title Savings R Rate Provider
 * @notice Returns the value of RR in terms of R
 */
contract SavingsRRateProvider is IRateProvider {
    IERC4626 public constant savingsR = IERC4626(0x2ba26baE6dF1153e29813d7f926143f9c94402f3);
    
    /**
     * @return the value of RR in terms of R
     */
    function getRate() external view override returns (uint256) {
        return savingsR.convertToAssets(1e18);
    }
}