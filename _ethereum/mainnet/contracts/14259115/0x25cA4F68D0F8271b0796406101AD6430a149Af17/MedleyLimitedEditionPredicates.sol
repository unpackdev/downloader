// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ICollectionNFTEligibilityPredicate.sol";
import "./ICollectionNFTMintFeePredicate.sol";
import "./IHashes.sol";

contract MedleyLimitedEditionPredicates is Ownable, ICollectionNFTEligibilityPredicate, ICollectionNFTMintFeePredicate {
    enum RolloutState {
        Disabled,
        AllowlistPreSeason,
        DAOHashesPreSeason,
        AllHashesPreSeason,
        AllowlistNormalSeason,
        DAOHashesNormalSeason,
        AllHashesNormalSeason
    }

    RolloutState public currentRolloutState;

    IHashes hashes;

    mapping(uint256 => bool) public preSeasonAllowlist;
    mapping(uint256 => bool) public normalSeasonAllowlist;

    uint256 preSeasonMintFee;
    uint256 normalSeasonMintFee;

    constructor(
        IHashes _hashes,
        address _owner,
        uint256 _preSeasonMintFee,
        uint256 _normalSeasonMintFee
    ) {
        hashes = _hashes;
        preSeasonMintFee = _preSeasonMintFee;
        normalSeasonMintFee = _normalSeasonMintFee;

        transferOwnership(_owner);
    }

    function setPreSeasonAllowlist(uint256[] memory _allowlist, bool[] memory _enable) external onlyOwner {
        require(_allowlist.length == _enable.length, "MedleyLimitedEditionPredicates: arrays must be same length");
        for (uint256 i = 0; i < _allowlist.length; i++) {
            preSeasonAllowlist[_allowlist[i]] = _enable[i];
        }
    }

    function setNormalSeasonAllowlist(uint256[] memory _allowlist, bool[] memory _enable) external onlyOwner {
        require(_allowlist.length == _enable.length, "MedleyLimitedEditionPredicates: arrays must be same length");
        for (uint256 i = 0; i < _allowlist.length; i++) {
            normalSeasonAllowlist[_allowlist[i]] = _enable[i];
        }
    }

    function setCurrentRolloutState(RolloutState _rolloutState) external onlyOwner {
        currentRolloutState = _rolloutState;
    }

    function getTokenMintFee(uint256 _tokenId, uint256) external view override returns (uint256) {
        if (_tokenId < 15) {
            return preSeasonMintFee;
        }
        return normalSeasonMintFee;
    }

    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (bool) {
        if (currentRolloutState == RolloutState.Disabled) {
            return false;
        }
        if (currentRolloutState == RolloutState.AllowlistPreSeason) {
            return _tokenId < 15 && preSeasonAllowlist[_hashesTokenId];
        }
        if (currentRolloutState == RolloutState.DAOHashesPreSeason) {
            return
                _tokenId < 15 &&
                ((_hashesTokenId < 1000 && !hashes.deactivated(_hashesTokenId)) || preSeasonAllowlist[_hashesTokenId]);
        }
        if (currentRolloutState == RolloutState.AllHashesPreSeason) {
            return _tokenId < 15;
        }
        if (currentRolloutState == RolloutState.AllowlistNormalSeason) {
            return normalSeasonAllowlist[_hashesTokenId];
        }
        if (currentRolloutState == RolloutState.DAOHashesNormalSeason) {
            return
                (_hashesTokenId < 1000 && !hashes.deactivated(_hashesTokenId)) || normalSeasonAllowlist[_hashesTokenId];
        }
        return true;
    }
}
