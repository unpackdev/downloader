// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

interface IDeFiatPoints {
    function viewDiscountOf(address _address) external view returns (uint256);
    function viewEligibilityOf(address _address) external view returns (uint256 tranche);
    function discountPointsNeeded(uint256 _tranche) external view returns (uint256 pointsNeeded);
    function viewTxThreshold() external view returns (uint256);
    function viewRedirection(address _address) external view returns (bool);

    function overrideLoyaltyPoints(address _address, uint256 _points) external;
    function addPoints(address _address, uint256 _txSize, uint256 _points) external;
    function burn(uint256 _amount) external;
}