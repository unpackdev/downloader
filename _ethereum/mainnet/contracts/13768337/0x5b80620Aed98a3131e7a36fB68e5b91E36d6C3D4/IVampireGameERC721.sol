// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC721.sol";
import "./IVampireGame.sol";

/// @notice Interface composed by IVampireGame + IERC721
interface IVampireGameERC721 is IVampireGame, IERC721 {}