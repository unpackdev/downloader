/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.7.5;


contract MixinNonFungibleToken {
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

    uint256 constant internal NF_INDEX_MASK = uint128(~0);

    uint256 constant internal TYPE_NF_BIT = 1 << 255;

    mapping (uint256 => address) internal nfOwners;

    mapping (address => uint256[]) internal nfOwnerMapping;

    // One index as a hack to tell the diff between unset and 0-value
    mapping (uint256 => uint256) internal tokenIdToNFOwnerMappingOneIndex;

    /// @dev Returns true if token is non-fungible
    function isNonFungible(uint256 id) public pure returns(bool) {
        return id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    /// @dev Returns true if token is fungible
    function isFungible(uint256 id) public pure returns(bool) {
        return id & TYPE_NF_BIT == 0;
    }

    /// @dev Returns index of non-fungible token
    function getNonFungibleIndex(uint256 id) public pure returns(uint256) {
        return id & NF_INDEX_MASK;
    }

    /// @dev Returns base type of non-fungible token
    function getNonFungibleBaseType(uint256 id) public pure returns(uint256) {
        return id & TYPE_MASK;
    }

    /// @dev Returns true if input is base-type of a non-fungible token
    function isNonFungibleBaseType(uint256 id) public pure returns(bool) {
        // A base type has the NF bit but does not have an index.
        return (id & TYPE_NF_BIT == TYPE_NF_BIT) && (id & NF_INDEX_MASK == 0);
    }

    /// @dev Returns true if input is a non-fungible token
    function isNonFungibleItem(uint256 id) public pure returns(bool) {
        // A base type has the NF bit but does has an index.
        return (id & TYPE_NF_BIT == TYPE_NF_BIT) && (id & NF_INDEX_MASK != 0);
    }

    /// @dev returns owner of a non-fungible token
    function ownerOf(uint256 id) public view returns (address) {
        return nfOwners[id];
    }

    /// @dev returns all owned NF tokenIds given an address
    function nfTokensOf(address _address) external view returns (uint256[] memory) {
        return nfOwnerMapping[_address];
    }

    /// @dev transfer token from one NF owner to another
    function transferNFToken(uint256 _id, address _from, address _to) internal {
        require(nfOwners[_id] == _from, "Token not owned by the from address");

        // chage nfOwner of the id to the new address
        nfOwners[_id] = _to;

        // only delete from the "from" user if this tokenId mapping already exists. When the from is 0x0 then it won't
        if (tokenIdToNFOwnerMappingOneIndex[_id] != 0) {
            // get index of where the token ID is stored in the from user's array of token IDs
            uint256 fromTokenIdIndex = tokenIdToNFOwnerMappingOneIndex[_id] - 1;

            // move the last token of the from user's array of token IDs to where fromTokenIdIndex is so we can shrink the array
            uint256 tokenIdToMove = nfOwnerMapping[_from][nfOwnerMapping[_from].length-1];

            // make the moves and then shrink the array. make sure to move the reference of the index in the tokenIdToNFOwnerMappingOneIndex
            nfOwnerMapping[_from][fromTokenIdIndex] = tokenIdToMove;
            nfOwnerMapping[_from].pop();
            tokenIdToNFOwnerMappingOneIndex[tokenIdToMove] = fromTokenIdIndex + 1;
        }

        // move the tokenId to the "to" user (and override index)
        nfOwnerMapping[_to].push(_id);
        tokenIdToNFOwnerMappingOneIndex[_id] = nfOwnerMapping[_to].length; // no need -1 because 1-index
    }
}
