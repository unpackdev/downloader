// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//TODO: Remove this interface and use reward wallet.

interface ISaltsToken {

    function transfer( address _to, uint256 _value ) external returns (bool success);

    function balanceOf(address account) external view returns (uint256);

    function registerUser(address _user, address _referer) external;

    function approve( address _spender, uint256 _value ) external returns (bool success);

    function transferFrom( address _from, address _to, uint256 _value ) external returns (bool success);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function CurrentSupply() external view returns (uint256);

    function setRewardsWallet(address _rewardsContractAddress) external;

    function BurnedTokens() external view returns (uint256);

    // sets developer wallet address for receiving fee
    function setDevWallet(address _devWallet) external;

    function claimReferalReward() external;

    event Taxes(uint256 burnTax, uint256 devTax, uint256 rewardstax);

    event UserRegistered( address indexed user, address indexed referer, uint256 timestamp );

    event Burn(address account, uint256 amount, uint256 timestamp);

}
