// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./LibAppStorage.sol";
import "./LibERC721.sol";
import "./IERC20.sol";

import "./Strings.sol";

library LibNftCommon {
    function getNftCommon(uint256 _tokenId) internal view returns(NftCommon memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.nfts[_tokenId];
    }

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        //remove
        uint256 index = s.ownerTokenIdIndexes[_from][_tokenId];
        uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
        if (index != lastIndex) {
            uint256 lastTokenId = s.ownerTokenIds[_from][lastIndex];
            s.ownerTokenIds[_from][index] = lastTokenId;
            s.ownerTokenIdIndexes[_from][lastTokenId] = index;
        }
        s.ownerTokenIds[_from].pop();
        delete s.ownerTokenIdIndexes[_from][_tokenId];
        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit LibERC721.Approval(_from, address(0), _tokenId);
        }

        // add
        setOwner(_tokenId, _to);
    }

    function validateAndLowerName(string memory _name) internal pure returns(string memory) {
        bytes memory name = abi.encodePacked(_name);
        uint256 len = name.length;
        
        require(len != 0, "LibNftCommon: Name can't be 0 chars");
        require(len < 26, "LibNftCommon: Name can't be greater than 25 characters");

        uint256 char = uint256(uint8(name[0]));
        require(char != 32, "LibNftCommon: First char of name can't be a space");

        char = uint256(uint8(name[len-1]));
        require(char != 32, "LibNftCommon: Last char of name can't be a space");

        for (uint256 i; i < len; i++) {
            char = uint256(uint8(name[i]));
            require(char > 31 && char < 127, "LibNftCommon: Invalid character in nft name");
            
            if (char < 91 && char > 64) {
                name[i] = bytes1(uint8(char+32));
            }
        }

        return string(name);
    }

    function tokenBaseURI(uint256 _tokenId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return bytes(s.baseURI).length > 0 ? string(abi.encodePacked(s.baseURI, Strings.toString(_tokenId))) : s.cloneBoxURI;
    }

    function setOwner(uint256 id, address newOwner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address oldOwner = s.nfts[id].owner;

        s.nfts[id].owner = newOwner;
        s.ownerTokenIdIndexes[newOwner][id] = s.ownerTokenIds[newOwner].length;
        s.ownerTokenIds[newOwner].push(id);

        emit LibERC721.Transfer(oldOwner, newOwner, id);
    }
}
