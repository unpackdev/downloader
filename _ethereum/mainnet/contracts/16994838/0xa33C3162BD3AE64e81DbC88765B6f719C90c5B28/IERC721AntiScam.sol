// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC721Lockable.sol";
import "./IERC721RestrictApprove.sol";

/// @title IERC721AntiScam
/// @dev 詐欺防止機能付きコントラクトのインターフェース
/// @author hayatti.eth

interface IERC721AntiScam is IERC721Lockable, IERC721RestrictApprove {

}
