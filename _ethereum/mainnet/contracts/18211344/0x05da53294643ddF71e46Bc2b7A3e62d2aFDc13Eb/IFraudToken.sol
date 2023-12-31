// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFraudToken {
    function mint(address to, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function transferUnderlying(address to, uint256 value) external returns (bool);
    function fragmentToFraud(uint256 value) external view returns (uint256);
    function fraudToFragment(uint256 fraud) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function getCurrentEpoch() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);

    function burn(address from, uint256 amount) external;
    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) external returns (uint256);
}


