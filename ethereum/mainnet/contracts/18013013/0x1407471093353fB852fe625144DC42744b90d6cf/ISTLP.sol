// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface ISTLP {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function bridge(address to, uint256 amount, bytes32 _raw) external;

    function bridgeAddress() external view returns (address);

    function burn(address from, uint256 amount) external;

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function setBrige(address _bridge) external;

    function setStaking(address _staking) external;

    function stakingAddress() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
