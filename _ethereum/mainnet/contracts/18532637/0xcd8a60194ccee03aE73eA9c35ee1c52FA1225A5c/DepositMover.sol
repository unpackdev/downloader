// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";

import "./IDepositAddressMaker.sol";
import "./IDepositMover.sol";

contract DepositMover is OwnableUpgradeable, IDepositMover {
    IDepositAddressMaker public override depositAddressMaker;
    address public override massDepositMoverAddr;

    modifier onlyOwnerOrMassDepositMover() {
        _onlyOwnerOrMassDepositMover();
        _;
    }

    function __DepositMover_init(
        IDepositAddressMaker factory_,
        address massDepositMoverAddr_,
        address executorAddr_
    ) external override initializer {
        __Ownable_init();

        depositAddressMaker = factory_;
        massDepositMoverAddr = massDepositMoverAddr_;

        _transferOwnership(executorAddr_);
    }

    receive() external payable {}

    function setMassDepositMover(address newMassDepositMover_) external override onlyOwner {
        massDepositMoverAddr = newMassDepositMover_;
    }

    function withdrawETH() external override onlyOwnerOrMassDepositMover {
        uint256 balance_ = address(this).balance;

        if (balance_ == 0) {
            revert DepositMoverZeroETHBalance();
        }

        (bool success_, ) = _onlyExistingHotwallet().call{value: balance_}("");

        if (!success_) {
            revert DepositMoverFailedToSendETH();
        }
    }

    function withdrawTokens(
        address[] calldata tokens_
    ) external override onlyOwnerOrMassDepositMover {
        if (tokens_.length == 0) {
            revert DepositMoverEmptyTokensArray();
        }

        address hotwalletAddr_ = _onlyExistingHotwallet();

        for (uint256 i = 0; i < tokens_.length; i++) {
            IERC20 token_ = IERC20(tokens_[i]);

            uint256 balance_ = token_.balanceOf(address(this));

            if (balance_ != 0) {
                token_.transfer(hotwalletAddr_, balance_);
            }
        }
    }

    function _onlyExistingHotwallet() internal view returns (address hotwalletAddr_) {
        hotwalletAddr_ = depositAddressMaker.hotwallet();

        if (hotwalletAddr_ == address(0)) {
            revert DepositMoverUnableToWithdrawFunds();
        }
    }

    function _onlyOwnerOrMassDepositMover() internal view {
        if (msg.sender != owner() && msg.sender != massDepositMoverAddr) {
            revert DepositMoverCallerIsNotTheOwnerOrWithdrawalManager();
        }
    }
}
