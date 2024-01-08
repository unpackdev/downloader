// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IENS.sol";
import "./IMirrorTokenStorage.sol";

/**
 * @title DistributionStorage
 * @author MirrorXYZ
 */
contract MirrorTokenStorage is IMirrorTokenStorage {
    // ============ ERC20 Attributes ============

    /// @notice EIP-20 token name for this token
    string public override name = "Mirror";

    /// @notice EIP-20 token symbol for this token
    string public override symbol = "MIRROR";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant override decimals = 18;

    // ============ Mutable ERC20 Attributes ============

    /// @notice Total number of tokens in circulation
    uint256 public override totalSupply;

    /// @notice Official record of token balances for each account
    mapping(address => uint256) public override balanceOf;

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) public override allowance;

    // ============ Treasury ============

    address public treasuryConfig;
}
