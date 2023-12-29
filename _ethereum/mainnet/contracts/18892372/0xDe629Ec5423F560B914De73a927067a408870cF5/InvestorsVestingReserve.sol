// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

import "./ManagedVestingReserve.sol";

/**
 * @title InvestorsVestingReserve
 * @author Ethichub
 */
contract InvestorsVestingReserve is ManagedVestingReserve {
    constructor(
        IERC20 _token,
        uint256 _startTime, // 2022-12-31 (1672441200)
        uint256 _endTime, // 2025-12-31 (1767135600)
        uint256 _editAddressUntil // 2025-12-30 (1767049200)
    ) ManagedVestingReserve(_token, _startTime, _endTime, _editAddressUntil) {}

    function initialize() external override {
        require(!initialized, 'InvestorsVestingReserve: Already initialized');
        require(
            token.transferFrom(msg.sender, address(this), 822831*10**18),
            'ManagedVestingReserve: Cannot transfer tokens from sender.'
        );
        locked[0x632065D6B0C075864808881444A9888828B41eF4] = 195556*10**18;
        locked[0x3BA9806cF61d6dA903fdEb4B8Da0ecb8Bab67efB] = 24444*10**18;
        locked[0xaa60084B1170bce4b6AaA1c56C1AA5f3DCA85923] = 24444*10**18;
        locked[0x329ac76a0D21Ab5e36F4FbB50A63423c678a2970] = 55556*10**18;
        locked[0x3083b29FC2F7E08218C5bFc439D36aC7393265BF] = 24444*10**18;
        locked[0xF3047476e29766E56CE7d2cc8569464d94B66860] = 24444*10**18;
        locked[0xf973806c522d87dF67fFf5DAa2420c21A92A95D4] = 53498*10**18;
        locked[0x135907936537a44763817AC7Fc30abaec9a81Fab] = 122222*10**18;
        locked[0x3ff72df4B65f1Bb5b51e037b113436324aFe30E7] = 24444*10**18;
        locked[0x4e7f2dEf792A9e2Ea8AE37e2696F2a6040cC1B1a] = 36667*10**18;
        locked[0x18689028e445105eAd475D983Ef860f120f3930F] = 29333*10**18;
        locked[0xc1f0A5c6CFA9eDDa352336e9E8202BC097E72C68] = 122222*10**18;
        locked[0xaDA24B6CF4DbD18abEffE2A49d78283cdc3C1Ee7] = 24444*10**18;
        locked[0xd54Ac0f0F3385B16Ed88055fF56aA4E6Ceae6B3e] = 36667*10**18;
        locked[0xac700361036d0608979F68c3B25b90F8c989568f] = 24444*10**18;

        initialized = true;
    }
}
