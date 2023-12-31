// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721TokenReceiver.sol";
import "./IERC1155TokenReceiver.sol";

interface ITokenReceiver is
    IERC721TokenReceiver,
    IERC1155TokenReceiver
{
    event NFTReceived(uint256 frameId, address owner, address nftAddress, uint256 nftId);
}
