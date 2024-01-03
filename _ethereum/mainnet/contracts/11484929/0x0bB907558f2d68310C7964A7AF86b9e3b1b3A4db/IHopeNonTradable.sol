// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IHopeNonTradable {
    function totalSupply() external view returns (uint256);

    function totalClaimed() external view returns (uint256);

    function addClaimed(uint256 _amount) external;

    function setClaimed(uint256 _amount) external;

    function transfer(address receiver, uint numTokens) external returns (bool);

    function transferFrom(address owner, address buyer, uint numTokens) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function mint(address _to, uint256 _amount) external;

    function burn(address _account, uint256 value) external;
}