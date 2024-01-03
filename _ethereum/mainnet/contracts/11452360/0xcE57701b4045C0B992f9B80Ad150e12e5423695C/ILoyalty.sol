// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ILoyalty {
    event TrancheUpdated(uint256 _tranche, uint256 _points);
    event LoyaltyUpdated(address indexed _user, uint256 _tranche, uint256 _points);
    event BaseFeeUpdated(address indexed _user, uint256 _baseFee);
    event ProtocolFeeUpdated(address indexed _user, uint256 _protocolFee);
    event DiscountMultiplierUpdated(address indexed _user, uint256 _multiplier);
    event Deposit(address indexed _user, uint256 _id, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _id, uint256 _amount);
    
    function staked(uint256 _id, address _address) external view returns (uint256);
    function whitelistedTokens(uint256 _id) external view returns (bool);

    function getTotalShares(address _user, uint256 _amount) external view returns (uint256);
    function getTotalFee(address _user, uint256 _amount) external view returns (uint256);
    function getProtocolFee(uint256 _amount) external view returns (uint256);
    function getBoost(address _user) external view returns (uint256);
    function deposit(uint256 _id, uint256 _amount) external;
    function withdraw(uint256 _id, uint256 _amount) external;
    function whitelistToken(uint256 _id) external;
    function blacklistToken(uint256 _id) external;
    function updatePoints(address _user) external;
}