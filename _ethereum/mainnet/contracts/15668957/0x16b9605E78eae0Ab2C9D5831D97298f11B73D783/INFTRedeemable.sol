// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

/// @title Interface for redemption
/// @author Martin Wawrusch
interface INFTRedeemable {
    function redeem(address sender, uint256 tokenId) external;
}

