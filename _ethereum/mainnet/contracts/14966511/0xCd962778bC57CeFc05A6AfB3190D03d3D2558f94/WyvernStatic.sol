// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./StaticERC20.sol";
import "./StaticERC721.sol";
import "./StaticERC1155.sol";
import "./StaticUtil.sol";

/**
 * @title WyvernStatic
 * @author Wyvern Protocol Developers
 */
contract WyvernStatic is StaticERC20, StaticERC721, StaticERC1155, StaticUtil {
    string public constant name = "Wyvern Static";

    constructor(address atomicizerAddress) {
        require(atomicizerAddress != address(0), "Atomicizer address required");
        atomicizer = atomicizerAddress;
    }

    function test() public pure {}
}
