// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./SafeMath.sol";

import "./Royalties.sol";

abstract contract TokenDetails is Royalties {
    using SafeMath for uint256;

    function getTokenRole(uint256 tokenId) public view returns (string memory) {
        return tokenRoles[tokenId];
    }

    /**
     * @dev Get token details for a specific address from an index of owner's token lsit
     * @param owner_ for which to get the token details
     * @param index from which to start retrieving the token details
     */
    function getTokenDetailsForFromIndex(address owner_, uint256 index)
        public
        view
        returns (NFTDetails[] memory)
    {
        uint256[] memory ownerList = ownerTokenList[owner_];
        NFTDetails[] memory details = new NFTDetails[](
            ownerList.length - index
        );
        uint256 counter = 0;
        for (uint256 i = index; i < ownerList.length; i++) {
            details[counter] = ownedTokensDetails[owner_][ownerList[i]];
            counter++;
        }
        return details;
    }

    /**
     * @dev Get token history list of owner
     * @param owner_ for which to get all the tokens
     */
    function getTokenListFor(address owner_)
        public
        view
        returns (uint256[] memory)
    {
        return ownerTokenList[owner_];
    }
}
