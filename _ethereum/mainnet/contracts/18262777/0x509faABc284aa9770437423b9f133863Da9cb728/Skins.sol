// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Votes.sol";

/// @title Skins ERC-20 token contract
/// @author Holdex Limited (https://holdex.io)
/// @dev Based on the the ERC-20 token standard as defined at https://eips.ethereum.org/EIPS/eip-20
contract SkinsToken is Votes {
    /// @notice EIP-20 token name for this token
    string public constant name = "COINS & SKINS";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "SKINS";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint96 public constant totalSupply = 800_000_000e18; // 800 million SKINS

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) private _allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    constructor(address multisig) nonZA(multisig) {
        balances[multisig] = totalSupply;
        emit Transfer(address(0), multisig, totalSupply);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(
        address account,
        address spender
    ) external view returns (uint) {
        return _allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(
        address spender,
        uint256 rawAmount
    ) external nonZA(spender) returns (bool) {
        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount);
        }

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(
        address dst,
        uint256 rawAmount
    ) external nonZA(dst) returns (bool) {
        uint96 amount = safe96(rawAmount);
        return _transferTokens(msg.sender, dst, amount);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external nonZA(src) nonZA(dst) returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = _allowances[src][spender];
        uint96 amount = safe96(rawAmount);

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(spenderAllowance, amount);
            _allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        return _transferTokens(src, dst, amount);
    }

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal returns (bool) {
        balances[src] = sub96(balances[src], amount);
        unchecked {
            balances[dst] += amount;
        }
        emit Transfer(src, dst, amount);
        _moveDelegates(delegates[src], delegates[dst], amount);

        return true;
    }

    /**
     * @dev Returns the voting units of an `account`.
     */
    function _getVotingUnits(
        address account
    ) internal view override returns (uint96) {
        return balances[account];
    }

    function _name() internal pure override returns (string memory) {
        return name;
    }
}
