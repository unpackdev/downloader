// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGobblers {
    function addGoo (uint256 amount) external;
    function removeGoo(uint256 amount) external;
    function mintFromGoo(uint256 maxPrice, bool useVirtual) external;
    function transferFrom(address maxPrice, address useVirtual, uint256 id) external;
    function gooBalance(address user) view external returns(uint256);
}
