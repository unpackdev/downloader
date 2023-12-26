// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./Ownable.sol";
import "./AvatarConstants.sol";
import "./IAvatarVolumeAndFrequency.sol";

abstract contract AvatarVolumeAndFrequency is Ownable, AvatarConstants, IAvatarVolumeAndFrequency {
    address public SANSWAP_ADDR;
    uint256[MAX_SUPPLY + 1] public avatarLevels;

    function levelUp(
        uint256 _tokenId,
        uint256 _levelIncreases
    )
        external
    {
        if (_msgSender() != SANSWAP_ADDR) revert CallerIsNotSanswap();
        _levelUp(_tokenId, _levelIncreases);
    }

    function levelUpBatch(
        uint256[] calldata _tokenIds,
        uint256[] calldata _levelIncreases
    )
        external
    {
        if (_msgSender() != SANSWAP_ADDR) revert CallerIsNotSanswap();
        for (uint i; i < _tokenIds.length; ++i) {
            _levelUp(_tokenIds[i], _levelIncreases[i]);
        }
    }

    function setSanswap(
        address _sanswap
    )
        external
        onlyOwner
    {
        SANSWAP_ADDR = _sanswap;
    }

    function getVolumeAndFrequency(
        uint256 _tokenId
    )
        public
        view
        returns (uint128 volume_, uint128 frequency_)
    {
        if (_tokenId == 0 || _tokenId > MAX_SUPPLY) revert InvalidTokenId();
        uint256 levels = avatarLevels[_tokenId];
        volume_ = uint128(levels);
        frequency_ = uint128(levels >> 128);
    }

    function _levelUp(
        uint256 _tokenId,
        uint256 _levelIncreases
    )
        private
    {
        if (_tokenId == 0 || _tokenId > MAX_SUPPLY) revert InvalidTokenId();
        uint256 newLevel = avatarLevels[_tokenId] += _levelIncreases;
        emit AvatarLevelUp(_tokenId, newLevel);
    }

}
