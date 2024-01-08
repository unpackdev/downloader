/*
 * RollApp
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title Reservoir
 *
 * @dev The contract is used to keep tokens with the function
 * of transfer them to another target address (it is assumed that
 * it will be a contract address).
 */
contract Reservoir is Ownable {

    using SafeERC20 for IERC20;

    IERC20 public token;
    address public target;

    event WithdrawByOwner(IERC20 token, uint256 amount);

    /**
     * @dev A constructor sets the address of token and
     * the address of the target contract.
     */
    constructor(IERC20 _token, address _target) public {
        token = _token;
        target = _target;
    }

    /**
     * @dev Transfers a certain amount of tokens to the target address.
     *
     * Requirements:
     * - msg.sender should be the target address.
     *
     * @param requestedTokens The amount of tokens to transfer.
     */
    function drip(uint256 requestedTokens)
        external
        returns (uint256 sentTokens)
    {
        address target_ = target;
        IERC20 token_ = token;
        require(msg.sender == target_, "Reservoir: permission denied");

        uint256 reservoirBalance = token_.balanceOf(address(this));
        sentTokens = (requestedTokens > reservoirBalance)
            ? reservoirBalance
            : requestedTokens;

        token_.safeTransfer(target_, sentTokens);
    }

    /**
     * @dev Transfers ERC20 tokens to the owner.
     *
     * Requirements:
     * - msg.sender should be the owner.
     *
     * @param _token ERC20 token that owner wants to withdraw.
     * @param _amount Amount of ERC20 tokens.
     */
    function withdraw(IERC20 _token, uint256 _amount) public onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        uint256 withdrawalAmount = (_amount > tokenBalance) ? tokenBalance : _amount;

        _token.safeTransfer(msg.sender, withdrawalAmount);
        emit WithdrawByOwner(_token, withdrawalAmount);
    }
}
