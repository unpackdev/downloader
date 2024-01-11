//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFaction {
    function balanceOf(address to) external returns (uint256);
    function initialize(string memory _name, string memory _symbol, address admin_) external;
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
