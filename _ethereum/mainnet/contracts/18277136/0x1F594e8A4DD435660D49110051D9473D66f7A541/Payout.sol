// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./ERC2981Upgradeable.sol";
import "./AdministratedUpgradeable.sol";

import "./IPayout.sol";

abstract contract Payout is AdministratedUpgradeable, ERC2981Upgradeable, IPayout {
    address public payoutAddress;

    address public platformFeesAddress;
    uint96 public platformFeesNumerator;

    uint256 constant MAX_PLATFORM_FEES_NUMERATOR = 2000;

    function __Payout_init()
        internal
        onlyInitializing
    {
        platformFeesAddress = 0xeA6b5147C353904D5faFA801422D268772F09512;
        platformFeesNumerator = 500;
    }

    function updatePlatformFees(
        address newPlatformFeesAddress,
        uint256 newPlatformFeesNumerator
    ) external onlyAdministrator {
        _updatePlatformFees(newPlatformFeesAddress, newPlatformFeesNumerator);
    }

    function updatePayoutAddress(
        address newPayoutAddress
    ) external onlyOwnerOrAdministrator {
        _updatePayoutAddress(newPayoutAddress);
    }

    function updateRoyalties(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwnerOrAdministrator {
        _updateRoyalties(receiver, feeNumerator);
    }

    function withdrawAllFunds() external onlyOwnerOrAdministrator {
        if (address(this).balance == 0) {
            revert NothingToWithdraw();
        }

        if (payoutAddress == address(0)) {
            revert InvalidPayoutAddress();
        }

        if (platformFeesAddress == address(0)) {
            revert InvalidPlatformFeesAddress();
        }

        uint256 platformFees = (address(this).balance * platformFeesNumerator) / _feeDenominator();
        if (platformFees > 0) {
            (bool platformFeesSuccess, ) = platformFeesAddress.call{value: platformFees}("");
            if (!platformFeesSuccess) revert PlatformFeesTransferFailed();
        }

        (bool payoutSuccess, ) = payoutAddress.call{value: address(this).balance}("");
        if (!payoutSuccess) revert PayoutTransferFailed();
    }

    function _updatePayoutAddress(
        address newPayoutAddress
    ) internal {
        if (newPayoutAddress == address(0)) {
            revert PayoutAddressCannotBeZeroAddress();
        }

        payoutAddress = newPayoutAddress;

        emit PayoutAddressUpdated(newPayoutAddress);
    }

    function _updateRoyalties(
        address receiver,
        uint96 feeNumerator
    ) internal {
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltiesUpdated(receiver, feeNumerator);
    }

    function _updatePlatformFees(
        address newPlatformFeesAddress,
        uint256 newPlatformFeesNumerator
    ) internal {
        if (newPlatformFeesAddress == address(0)) {
            revert PlatformFeesAddressCannotBeZeroAddress();
        }

        if (newPlatformFeesNumerator > MAX_PLATFORM_FEES_NUMERATOR) {
            revert PlatformFeesNumeratorTooHigh();
        }

        platformFeesAddress = newPlatformFeesAddress;
        platformFeesNumerator = uint96(newPlatformFeesNumerator);

        emit PlatformFeesUpdated(newPlatformFeesAddress, newPlatformFeesNumerator);
    }
}
