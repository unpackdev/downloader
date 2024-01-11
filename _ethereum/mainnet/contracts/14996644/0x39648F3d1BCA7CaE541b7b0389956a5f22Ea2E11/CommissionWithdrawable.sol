// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IWithdrawable.sol";

/**
 *
 * ██████╗░██╗████████╗  ██████╗░██████╗░██╗███████╗███████╗░██████╗
 * ██╔══██╗██║╚══██╔══╝  ██╔══██╗██╔══██╗██║╚════██║██╔════╝██╔════╝
 * ██████╔╝██║░░░██║░░░  ██████╔╝██████╔╝██║░░███╔═╝█████╗░░╚█████╗░
 * ██╔═══╝░██║░░░██║░░░  ██╔═══╝░██╔══██╗██║██╔══╝░░██╔══╝░░░╚═══██╗
 * ██║░░░░░██║░░░██║░░░  ██║░░░░░██║░░██║██║███████╗███████╗██████╔╝
 * ╚═╝░░░░░╚═╝░░░╚═╝░░░  ╚═╝░░░░░╚═╝░░╚═╝╚═╝╚══════╝╚══════╝╚═════╝░
 *
 */

contract CommissionWithdrawable is IWithdrawable, Ownable {
    address internal immutable _commissionPayoutAddress;
    uint256 internal immutable _commissionPayoutPerMille;

    error CommissionPayoutAddressIsZeroAddress();
    error CommissionPayoutPerMilleTooLarge();

    constructor(
        address commissionPayoutAddress_,
        uint256 commissionPayoutPerMille_
    ) {
        if (commissionPayoutAddress_ == address(0)) {
            revert CommissionPayoutAddressIsZeroAddress();
        }
        if (commissionPayoutPerMille_ > 1000) {
            revert CommissionPayoutPerMilleTooLarge();
        }
        _commissionPayoutAddress = commissionPayoutAddress_;
        _commissionPayoutPerMille = commissionPayoutPerMille_;
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;
        (
            uint256 ownerShareMinusCommission,
            uint256 commissionFee
        ) = calculateOwnerShareAndCommissionFee(balance);
        payable(msg.sender).transfer(ownerShareMinusCommission);
        payable(_commissionPayoutAddress).transfer(commissionFee);
    }

    function withdrawToken(address token_) external override onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        (
            uint256 ownerShareMinusCommission,
            uint256 commissionFee
        ) = calculateOwnerShareAndCommissionFee(balance);
        IERC20(token_).transfer(msg.sender, ownerShareMinusCommission);
        IERC20(token_).transfer(_commissionPayoutAddress, commissionFee);
    }

    function calculateOwnerShareAndCommissionFee(uint256 balance_)
        private
        view
        returns (uint256, uint256)
    {
        uint256 commissionFee;
        if (balance_ < 2**246) {
            commissionFee = (balance_ * _commissionPayoutPerMille) / 1000;
        } else {
            commissionFee = (balance_ / 1000) * _commissionPayoutPerMille;
        }
        uint256 ownerShareMinusCommission = balance_ - commissionFee;
        return (ownerShareMinusCommission, commissionFee);
    }
}
