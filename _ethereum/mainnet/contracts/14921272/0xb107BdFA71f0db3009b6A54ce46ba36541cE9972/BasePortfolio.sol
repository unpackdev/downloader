// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "IERC20.sol";
import {ERC20Upgradeable} from "ERC20Upgradeable.sol";
import {Upgradeable} from "Upgradeable.sol";
import {SafeERC20} from "SafeERC20.sol";

import {IProtocolConfig} from "IProtocolConfig.sol";
import {IBasePortfolio} from "IBasePortfolio.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {ITransferStrategy} from "ITransferStrategy.sol";

abstract contract BasePortfolio is IBasePortfolio, ERC20Upgradeable, Upgradeable {
    using SafeERC20 for IERC20;

    event Deposited(uint256 shares, uint256 amount, address indexed sender);
    event Withdrawn(uint256 shares, uint256 amount, address indexed sender);
    event TransferStrategyChanged(address indexed oldStrategy, address indexed newStrategy);
    event FeePaid(address indexed sender, address indexed recipient, uint256 amount);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    uint256 public constant BASIS_PRECISION = 10000;

    uint256 public endDate;
    IERC20 public underlyingToken;
    uint8 public underlyingTokenDecimals;

    address public transferStrategy;
    IProtocolConfig public protocolConfig;
    uint256 public managerFee;
    uint256 public virtualTokenBalance;

    function __BasePortfolio_init(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager,
        uint256 _managerFee
    ) internal initializer {
        require(_duration > 0, "BasePortfolio: Cannot have zero duration");
        __Upgradeable_init(_protocolConfig.protocolAddress(), _protocolConfig.pauserAddress());
        _grantRole(MANAGER_ROLE, _manager);
        _setRoleAdmin(DEPOSIT_ROLE, MANAGER_ROLE);
        _setRoleAdmin(WITHDRAW_ROLE, MANAGER_ROLE);

        protocolConfig = _protocolConfig;
        endDate = block.timestamp + _duration;
        underlyingToken = _underlyingToken;
        underlyingTokenDecimals = IERC20WithDecimals(address(_underlyingToken)).decimals();
        if (_managerFee > 0) {
            managerFee = _managerFee;
        }
    }

    function setTransferStrategy(address _transferStrategy) public onlyRole(MANAGER_ROLE) {
        _setTransferStrategy(_transferStrategy);
    }

    /* @notice This contract is upgradeable and interacts with settable deposit strategies,
     * that may change over the contract's lifespan. As a safety measure, we recommend approving
     * this contract with the desired deposit amount instead of performing infinite allowance.
     */
    function deposit(uint256 amount, address sender) public virtual onlyRole(DEPOSIT_ROLE) whenNotPaused {
        uint256 sharesToMint = calculateSharesToMint(amount);
        _mint(sender, sharesToMint);
        virtualTokenBalance += amount;
        underlyingToken.safeTransferFrom(sender, address(this), amount);
        emit Deposited(sharesToMint, amount, sender);
    }

    function withdraw(uint256 shares, address sender) public virtual onlyRole(WITHDRAW_ROLE) whenNotPaused {
        uint256 amountToWithdraw = calculateAmountToWithdraw(shares);
        require(amountToWithdraw <= virtualTokenBalance, "BasePortfolio: Amount exceeds pool balance");
        virtualTokenBalance -= amountToWithdraw;
        _burn(sender, shares);
        underlyingToken.safeTransfer(sender, amountToWithdraw);
        emit Withdrawn(shares, amountToWithdraw, sender);
    }

    function calculateSharesToMint(uint256 depositedAmount) public view virtual returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return (depositedAmount * 10**decimals()) / (10**underlyingTokenDecimals);
        } else {
            return (depositedAmount * _totalSupply) / value();
        }
    }

    function calculateAmountToWithdraw(uint256 shares) public view virtual returns (uint256) {
        return (shares * value()) / totalSupply();
    }

    function value() public view virtual returns (uint256) {
        return virtualTokenBalance;
    }

    function _setTransferStrategy(address _transferStrategy) internal {
        address oldTransferStrategy = transferStrategy;
        require(_transferStrategy != oldTransferStrategy, "BasePortfolio: New transfer strategy needs to be different");

        transferStrategy = _transferStrategy;
        emit TransferStrategyChanged(oldTransferStrategy, _transferStrategy);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override whenNotPaused {
        if (transferStrategy != address(0)) {
            require(
                ITransferStrategy(transferStrategy).canTransfer(sender, recipient, amount),
                "BasePortfolio: This transfer not permitted"
            );
        }
        super._transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override whenNotPaused {
        super._approve(owner, spender, amount);
    }
}
