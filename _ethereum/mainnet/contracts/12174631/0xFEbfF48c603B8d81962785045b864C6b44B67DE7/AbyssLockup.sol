/*
░█████╗░██████╗░██╗░░░██╗░██████╗░██████╗  ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
██╔══██╗██╔══██╗╚██╗░██╔╝██╔════╝██╔════╝  ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
███████║██████╦╝░╚████╔╝░╚█████╗░╚█████╗░  █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
██╔══██║██╔══██╗░░╚██╔╝░░░╚═══██╗░╚═══██╗  ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
██║░░██║██████╦╝░░░██║░░░██████╔╝██████╔╝  ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═════╝░╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * Abyss Finance's AbyssLockup Contract
 * A smart contract that stores tokens requested for withdrawal, as well as through which tokens are transferred from/to user and between contracts.
 */
contract AbyssLockup is Ownable {
    using SafeERC20 for IERC20;

    address public safeContract1;
    address public safeContract3;
    address public safeContract7;
    address public safeContract14;
    address public safeContract21;
    address public safeContract28;
    address public safeContract90;
    address public safeContract180;
    address public safeContract365;
    uint256 private _freeDeposits;

    struct Token {
        uint256 deposited;
        uint256 divFactor;
    }

    mapping (address => Token) private _tokens;

    constructor(uint256 freeDeposits_) {
        _freeDeposits = freeDeposits_;
    }

    // VIEW FUNCTIONS

    /**
     * @dev See {IAbyssLockup-deposited}.
     */
    function deposited(address token) external view returns (uint256) {
        return _tokens[token].deposited;
    }

    /**
     * @dev See {IAbyssLockup-divFactor}.
     */
    function divFactor(address token) external view returns (uint256) {
        return _tokens[token].divFactor;
    }

    /**
     * @dev See {IAbyssLockup-freeDeposits}.
     */
    function freeDeposits() public view returns (uint256) {
        return _freeDeposits;
    }

    // ACTION FUNCTIONS

    /**
     * @dev See {IAbyssLockup-externalTransfer}.
     */
    function externalTransfer(address token, address sender, address recipient, uint256 amount, uint256 abyssRequired) external onlyContract(msg.sender) returns (bool) {
        if (sender == address(this)) {
            IERC20(address(token)).safeTransfer(recipient, amount);
        } else {
            if (recipient != address(this) && abyssRequired > 0 && _freeDeposits > 0) {
                _freeDeposits = _freeDeposits - 1;
            }
            IERC20(address(token)).safeTransferFrom(sender, recipient, amount);
        }
        return true;
    }

    function resetData(address token) external onlyContract(msg.sender) returns (bool) {
        delete _tokens[token].deposited;
        delete _tokens[token].divFactor;
        return true;
    }

    function updateData(address token, uint256 balance, uint256 divFactor_) external onlyContract(msg.sender) returns (bool) {
        _tokens[token].deposited = balance;
        if (divFactor_ == 1) {
            delete _tokens[token].divFactor;
        } else if (divFactor_ > 0) {
            _tokens[token].divFactor = divFactor_;
        }
        return true;
    }

    // ADMIN FUNCTIONS

    /**
     * @dev Configurates smart contract allowing modification in the amount of
     * free deposits.
     */
    function setup(uint256 freeDeposits__) external onlyOwner returns (bool) {
        _freeDeposits = freeDeposits__;
        return true;
    }

    /**
     * @dev Initializes configuration of a given smart contract, with a specified
     * addresses for the `safeContract` smart contracts.
     *
     * All three of these values are immutable: they can only be set once.
     */
    function initialize(address safe1, address safe3, address safe7, address safe14, address safe21,
                        address safe28, address safe90, address safe180, address safe365) external onlyOwner returns (bool) {
        require(address(safeContract1) == address(0), "AbyssLockup: already initialized");
        safeContract1 = safe1;
        safeContract3 = safe3;
        safeContract7 = safe7;
        safeContract14 = safe14;
        safeContract21 = safe21;
        safeContract28 = safe28;
        safeContract90 = safe90;
        safeContract180 = safe180;
        safeContract365 = safe365;
        return true;
    }

    /**
     * @dev A function that allows the `owner` to withdraw any locked and lost tokens
     * from the smart contract if such `token` is not yet deposited.
     *
     * NOTE: Embedded in the function is verification that allows for token withdrawal
     * only if the token balance is greater than the token balance requested to
     * withdrawals on all `safeContract` smart contracts.
     */
    function withdrawLostTokens(address token) external onlyOwner returns (bool) {
        uint256 _tempBalance = IERC20(address(token)).balanceOf(address(this));

        if (_tokens[token].deposited == 0 && _tempBalance > 0) {
            SafeERC20.safeTransfer(IERC20(address(token)), msg.sender, _tempBalance);
        }
        return true;
    }

    /**
     * @dev Modifier that allows usage only for `safeContract` smart contracts
    */
    modifier onlyContract(address account)  {
        require(account == address(safeContract1) || account == address(safeContract3) || account == address(safeContract7) ||
        account == address(safeContract14) || account == address(safeContract21) || account == address(safeContract28) ||
        account == address(safeContract90) || account == address(safeContract180) || account == address(safeContract365), "AbyssLockup: restricted area");
        _;
    }
}
