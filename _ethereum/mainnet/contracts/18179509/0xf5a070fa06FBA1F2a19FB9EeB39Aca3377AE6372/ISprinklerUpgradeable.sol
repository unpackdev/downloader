// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISprinklerUpgradeable {
    /// @dev events
    event WaterExchanged(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 waterAmount,
        bool isTemporarily
    );
    event AddWhiteListAsset(address indexed token, uint256 tokenMultiplier);
    event UnListAsset(address indexed token);
    event DepositWater(uint256 amount);
    event WithdrawToken(address indexed token, address to, uint256 amount);
    
    function getWaterAmount(
        address _token,
        uint256 _amount
    ) external view returns (uint256 waterAmount);
}
