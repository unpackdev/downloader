// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC1155Burnable {

    function burn(address account, uint tokenId, uint amount) external;

}