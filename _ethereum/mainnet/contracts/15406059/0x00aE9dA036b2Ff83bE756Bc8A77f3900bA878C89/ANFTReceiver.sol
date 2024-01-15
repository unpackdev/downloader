// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./AERC1155Receiver.sol";

import "./AERC721Receiver.sol";

abstract contract ANFTReceiver is AERC721Receiver, AERC1155Receiver {}
