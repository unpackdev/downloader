// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IKaijuMartRedeemable {
    function kmartRedeem(uint256 lotId, uint32 amount, address to) external;
}

contract AirdropKmartRedeemable is Ownable {
    constructor() {}

    function airdrop(
        IKaijuMartRedeemable _redeemable,
        address[] calldata _receivers,
        uint32[] calldata _amounts
    ) public payable onlyOwner {
        assert(_receivers.length == _amounts.length);

        for (uint256 i; i < _receivers.length;) {
            _redeemable.kmartRedeem(0, _amounts[i], _receivers[i]);
            unchecked { ++i; }
        }
    }
}