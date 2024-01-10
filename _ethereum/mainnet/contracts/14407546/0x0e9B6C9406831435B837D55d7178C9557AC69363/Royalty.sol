// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC2981.sol";
import "./RoyaltiesV2.sol";
import "./LibRoyaltiesV2.sol";

abstract contract Royalty is ERC2981, RoyaltiesV2 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function setRoyalty(
        uint256 id,
        address addr,
        uint96 feeNumerator
    ) internal {
        _setTokenRoyalty(id, addr, feeNumerator);

        LibPart.Part[] memory part = new LibPart.Part[](1);
        part[0].value = feeNumerator;
        part[0].account = payable(addr);

        emit RoyaltiesSet(id, part);
    }

    function getRaribleV2Royalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory)
    {
        RoyaltyInfo memory royaltyInfo = tokenRoyaltyInfo[id];

        LibPart.Part[] memory part = new LibPart.Part[](1);
        part[0].value = royaltyInfo.royaltyFraction;
        part[0].account = payable(royaltyInfo.receiver);

        return part;
    }
}
