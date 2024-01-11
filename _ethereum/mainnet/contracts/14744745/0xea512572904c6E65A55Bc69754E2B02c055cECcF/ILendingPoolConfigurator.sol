pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

interface ILendingPoolConfigurator {

    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;

    function setReserveFactor(address asset, uint256 reserveFactor) external;
}
