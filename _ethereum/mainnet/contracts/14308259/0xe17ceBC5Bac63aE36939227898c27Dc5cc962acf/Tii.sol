// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Tii is ERC721URIStorage, ERC721Enumerable, Ownable {
    string[] private tiiNames;
    mapping (string => bool) private _tiiNameExists;

    constructor() ERC721("Tii", "TII")  {}

    function addTii(string memory tiiName) public onlyOwner returns (uint256) {
        require(!_tiiNameExists[tiiName], "This Tii has already been taken");

        tiiNames.push(tiiName);
        _tiiNameExists[tiiName] = true;
        return tiiNames.length - 1;
    }

    function getTiiNames() public view returns (string[] memory) {
        return tiiNames;
    }

    function checkIfTiiExists(string memory tiiName) public view returns (bool) {
        return _tiiNameExists[tiiName];
    }

    function removeTii(string memory tiiName) onlyOwner public {
        _tiiNameExists[tiiName] = false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId, string memory tiiName) 
        public
        onlyOwner
    {
        removeTii(tiiName);
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function awardTii(address buyer, string memory tiiName, string memory URI)
        public
        onlyOwner
        returns (uint256)
    {
        // Make sure the tii we are trying to mint has not already been minted
        require(!checkIfTiiExists(tiiName), "This Tii has already been taken");
        require(_checkLength(tiiName), "The Tii is not between 1 - 4 characters");
        require(_checkName(tiiName), "This Tii contains invalid characters");

        // Store that we have minted this tii
        uint tokenId = addTii(tiiName);

        _safeMint(buyer, tokenId);
        _setTokenURI(tokenId, URI);

        return tokenId;
    }

    function getAllTokensForOwner(address _owner) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(_owner);
        if (balance == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](balance);
        uint256 count;
        for (count = 0; count < balance; count++) {
            tokenIds[count] = tokenOfOwnerByIndex(_owner, count);
        }
        return tokenIds;
    }

    // https://ethereum.stackexchange.com/a/8285
    function _checkName(string memory _name) internal pure returns(bool){
        uint allowedChars = 0;
        bytes memory byteString = bytes(_name);
        bytes memory allowed = bytes("ABCDEFGHIJKLMNOPQRSTUVWXYZ");  // here you put what character are allowed to use

        for(uint i=0; i < byteString.length; i++){
           for(uint j=0; j < allowed.length; j++){
              if(byteString[i]==allowed[j] ) {
                allowedChars++;         
              }
           }
        }

        if(allowedChars < byteString.length)
            return false;

        return true;
    }

    function _checkLength(string memory _name) internal pure returns(bool){
        bytes memory byteString = bytes(_name);
        uint allowedLength = 4;

        if(byteString.length == 0)
            return false;

        if(byteString.length > allowedLength)
            return false;

        return true;
    }
}