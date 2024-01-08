// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./AbstractRoyalties.sol";
import "./RoyaltiesV2.sol";

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {
    function getPaceArtV2Royalties(uint256 id) override external view returns (LibPart.Part memory) {
        return royalties[id];
    }
    function _onRoyaltiesSet(uint256 _id, LibPart.Part memory _royalties) override internal {
        emit RoyaltiesSet(_id, _royalties);
    }
}