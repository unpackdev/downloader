// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IWithdrawalManager.sol";

contract WithdrawalManager is IWithdrawalManager, Ownable {
    using SafeERC20 for IERC20;

    function massTokensSend(
        TokenSendInfo[] calldata tokenSendInfoArr_
    ) external payable override onlyOwner {
        uint256 totalValueAmount_ = _getETHBalance();
        uint256 sentAmount_;

        for (uint256 i = 0; i < tokenSendInfoArr_.length; i++) {
            TokenSendInfo calldata tokenSendInfo_ = tokenSendInfoArr_[i];

            if (tokenSendInfo_.recipientsArr.length != tokenSendInfo_.valuesArr.length) {
                revert WithdrawalManagerArraysLengthMismatch();
            }

            IERC20 currentToken_ = IERC20(tokenSendInfo_.tokenAddr);

            for (uint256 j = 0; j < tokenSendInfo_.recipientsArr.length; j++) {
                if (tokenSendInfo_.recipientsArr[j] == address(0)) {
                    revert WithdrawalManagerZeroRecipientAddress();
                }

                if (tokenSendInfo_.tokenAddr != address(0)) {
                    currentToken_.safeTransferFrom(
                        msg.sender,
                        tokenSendInfo_.recipientsArr[j],
                        tokenSendInfo_.valuesArr[j]
                    );
                } else {
                    _sendETH(tokenSendInfo_.recipientsArr[j], tokenSendInfo_.valuesArr[j]);

                    sentAmount_ += tokenSendInfo_.valuesArr[j];
                }
            }
        }

        if (totalValueAmount_ > sentAmount_) {
            _sendETH(msg.sender, totalValueAmount_ - sentAmount_);
        }
    }

    function _sendETH(address recipient_, uint256 value_) internal {
        if (_getETHBalance() < value_) {
            revert WithdrawalManagerNotEnoungETHForTransfer(value_);
        }

        (bool success_, ) = recipient_.call{value: value_}("");

        if (!success_) {
            revert WithdrawalManagerFailedToTransferETH();
        }
    }

    function _getETHBalance() internal view returns (uint256) {
        return address(this).balance;
    }
}
