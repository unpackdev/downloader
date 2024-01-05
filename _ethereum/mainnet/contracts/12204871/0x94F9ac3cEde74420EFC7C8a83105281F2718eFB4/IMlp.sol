// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

abstract contract IMlp {
    function makeOffer(address _token, uint _amount, uint _unlockDate, uint _endDate, uint _slippageTolerancePpm, uint _maxPriceVariationPpm) external virtual returns (uint offerId);

    function takeOffer(uint _pendingOfferId, uint _amount, uint _deadline) external virtual returns (uint activeOfferId);

    function cancelOffer(uint _offerId) external virtual;

    function release(uint _offerId, uint _deadline) external virtual;
}
