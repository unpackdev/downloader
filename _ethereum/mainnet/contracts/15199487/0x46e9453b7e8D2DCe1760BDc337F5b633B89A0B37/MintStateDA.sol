// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStateDA {
    struct State {
        uint8 allowedMintGoldPhase1;
        uint8 allowedMintGoldPhasesOtherEach;
        uint8 allowedMintStandardPhase1;
        uint8 allowedMintStandardPhasesOtherAccu;
        // maps membershipIds to the amount of mints
        mapping(uint256 => mapping(uint256 => uint256)) _mints;
    }

    function init(State storage state) internal {
        state.allowedMintStandardPhase1 = 1;
        state.allowedMintStandardPhasesOtherAccu = 1;
        state.allowedMintGoldPhase1 = 3;
        state.allowedMintGoldPhasesOtherEach = 1;
    }

    function getMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 daPhase
    ) internal view returns (uint256) {
        uint256 key = isGold ? daPhase : daPhase > 1 ? 2 : daPhase;
        return state._mints[membershipId][key];
    }

    function getAllowedMints(
        State storage state,
        bool isGold,
        uint256 daPhase
    ) internal view returns (uint256) {
        uint256 key = isGold ? daPhase : daPhase > 1 ? 2 : daPhase;
        return
            isGold
                ? (
                    key > 1
                        ? state.allowedMintGoldPhasesOtherEach
                        : state.allowedMintGoldPhase1
                )
                : (
                    key > 1
                        ? state.allowedMintStandardPhasesOtherAccu
                        : state.allowedMintStandardPhase1
                );
    }

    function getAvailableMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 daPhase,
        uint256 collectionSupply,
        uint256 currentSupply
    ) internal view returns (uint256) {
        uint256 availableMints = collectionSupply - currentSupply;

        return
            availableMints > 0
                ? getAllowedMints(state, isGold, daPhase) -
                    getMints(state, membershipId, isGold, daPhase)
                : 0;
    }

    function update(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 daPhase,
        uint256 value
    ) internal {
        uint256 key = isGold ? daPhase : daPhase > 1 ? 2 : daPhase;
        unchecked {
            state._mints[membershipId][key] += value;
        }
    }
}
