// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./AbstractRoyalties.sol";
import "./RoyaltiesV2.sol";

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {
    function getVindergoodV2Royalties(uint256 id)
        public
        view
        override
        returns (LibPart.Part memory)
    {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 _id, LibPart.Part memory _royalties)
        internal
        override
    {
        emit RoyaltiesSet(_id, _royalties);
    }
}
