// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./RoyaltiesV2Upgradeable.sol";

//royalties for gen-art, one royalty value for the whole collection
contract RoyaltiesV2GenImpl is RoyaltiesV2Upgradeable {
    LibPart.Part[] collectionRoyalties;

    function __RoyaltiesV2GenImpl_init_unchained(LibPart.Part[] memory _royalties) internal initializer {
        _saveRoyalties(_royalties);
    }

    function getRaribleV2Royalties(uint256) override external view returns (LibPart.Part[] memory) {
        return collectionRoyalties;
    }

    function _saveRoyalties(LibPart.Part[] memory _royalties) internal {
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            collectionRoyalties.push(_royalties[i]);
        }
        _onRoyaltiesSet(_royalties);
    }

    function _onRoyaltiesSet(LibPart.Part[] memory _royalties) internal {
        emit RoyaltiesSet(0, _royalties);
    }

    uint256[50] private __gap;
}