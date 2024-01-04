// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IDeFiatPoints {
    function viewDiscountOf(address _address) external view returns (uint256);
    function viewEligibilityOf(address _address) external view returns (uint256 tranche);
    function discountPointsNeeded(uint256 _tranche) external view returns (uint256 pointsNeeded);
    function viewTxThreshold() external view returns (uint256);
    function viewWhitelisted(address _address) external view returns (bool);
    function viewRedirection(address _address) external view returns (bool);
    function setWhitelisted(address _address, bool _whitelist) external;
    function setRedirection(address _address, bool _redirect) external;
    function overrideLoyaltyPoints(address _address, uint256 _points) external;
}