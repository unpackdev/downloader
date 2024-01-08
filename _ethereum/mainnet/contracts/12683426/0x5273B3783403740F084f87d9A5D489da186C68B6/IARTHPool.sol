// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IARTHPool {
    function repay(uint256 amount) external;

    function borrow(uint256 amount) external;

    function setBuyBackCollateralBuffer(uint256 percent) external;

    function setCollatGMUOracle(address _collateralGMUOracleAddress) external;

    function setPoolParameters(uint256 newCeiling, uint256 newRedemptionDelay)
        external;

    function setTimelock(address newTimelock) external;

    function setOwner(address ownerAddress) external;

    function mint(uint256 collateralAmount, uint256 arthOutMin, uint256 arthxOutMin)
        external
        returns (uint256, uint256);

    function redeem(uint256 arthAmount, uint256 arthxAmount, uint256 collateralOutMin)
        external;

    function collectRedemption() external;

    function recollateralizeARTH(uint256 collateralAmount, uint256 arthxOutMin)
        external
        returns (uint256);

    function buyBackARTHX(uint256 arthxAmount, uint256 collateralOutMin)
        external;

    function getGlobalCR() external view returns (uint256);

    function getCollateralGMUBalance() external view returns (uint256);

    function getAvailableExcessCollateralDV() external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function collateralGMUOracleAddress() external view returns (address);
}
