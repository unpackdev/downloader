// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IONFT1155Core.sol";
import "./ILinkageLeaf.sol";
import "./IERC1155Receiver.sol";

interface IProxyONFT1155 is IONFT1155Core, IERC1155Receiver, ILinkageLeaf {}
