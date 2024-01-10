// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./Math.sol";

import "./BaseImplementation.sol";
import "./Obligations.sol";

abstract contract ToonTokenExtendedImplementation is
    ToonTokenBaseImplementation,
    Obligations
{
    uint256 private constant _UNMINTED_RESERVE_LIMIT = 10000 * 10**18;

    uint256 public maintainerBonusReserve;

    uint256 public bountyBonusReserve;

    uint256 public bountyObligationReferencePrice;

    event BountyObligationReferencePriceUpdated(uint256 referencePrice);

    function setBountyObligationReferencePrice(uint256 referencePrice)
        external
        onlyMaintainer
    {
        require(
            referencePrice > (currentPricePerToken * 2),
            "twice the current price"
        );
        bountyObligationReferencePrice = referencePrice;

        emit BountyObligationReferencePriceUpdated(referencePrice);
    }

    function lockTokens(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) external {
        _createObligation(
            _msgSender(),
            amount,
            recipient,
            releaseTime,
            targetPrice
        );
    }

    function mintAndLockMaintainerBonusReserves() public {
        _mint(maintainerWallet, maintainerBonusReserve);
        _createObligation(
            maintainerWallet,
            maintainerBonusReserve,
            maintainerWallet,
            block.timestamp + 365 days,
            currentPricePerToken * 2
        );
        maintainerBonusReserve = 0;
    }

    function mintAndLockBountyBonusReserves() public {
        _mint(bountyWallet, bountyBonusReserve);

        uint256 targetPrice = currentPricePerToken * 2;
        if (currentPricePerToken < bountyObligationReferencePrice) {
            targetPrice = Math.min(bountyObligationReferencePrice, targetPrice);
        }

        _createObligation(
            bountyWallet,
            bountyBonusReserve,
            bountyWallet,
            block.timestamp + 36500 days,
            targetPrice
        );
        bountyBonusReserve = 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return
            super.totalSupply() + maintainerBonusReserve + bountyBonusReserve;
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        _transfer(sender, recipient, amount);
    }

    function _mintMaintainerBonus(uint256 maintainerBonusTokensAmount)
        internal
        virtual
        override
    {
        maintainerBonusReserve += maintainerBonusTokensAmount;

        if (maintainerBonusReserve > _UNMINTED_RESERVE_LIMIT) {
            mintAndLockMaintainerBonusReserves();
        }
    }

    function _mintBountyBonus(uint256 bountyBonusTokensAmount)
        internal
        virtual
        override
    {
        bountyBonusReserve += bountyBonusTokensAmount;

        if (bountyBonusReserve > _UNMINTED_RESERVE_LIMIT) {
            mintAndLockBountyBonusReserves();
        }
    }

    function _currentPricePerToken()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return currentPricePerToken;
    }

    uint256[47] private __gap;
}
