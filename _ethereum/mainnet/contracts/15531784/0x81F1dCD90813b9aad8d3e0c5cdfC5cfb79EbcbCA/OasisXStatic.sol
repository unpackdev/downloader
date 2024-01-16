//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StaticERC20.sol";
import "./StaticERC721.sol";
import "./StaticERC1155.sol";
import "./StaticUtil.sol";
import "./StaticMarket.sol";

/**
 * @title OasisXStatic
 * @notice static call functions
 * @author OasisX Protocol | cryptoware.eth
 */
contract OasisXStatic is
    StaticERC20,
    StaticERC721,
    StaticERC1155,
    StaticUtil,
    StaticMarket
{
    string public constant name = "OasisX Static";

    constructor(address atomicizerAddress) {
        require
        (
            atomicizerAddress != address(0),
            "OasisXAtomicizer: Atomicizer address cannot be 0"
        );
        atomicizer = atomicizerAddress;
        atomicizerAddr = atomicizerAddress;
    }
}
