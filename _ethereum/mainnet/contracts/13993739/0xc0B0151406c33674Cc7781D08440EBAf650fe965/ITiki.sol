// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.4 <0.9.0;

interface ITiki {
    function ownerOf(uint256 tokenID) external view returns(address);
}
