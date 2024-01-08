// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "Ownable.sol";
import "ERC721.sol";
import "ERC721URIStorage.sol";
import "ERC721Enumerable.sol";
import "IERC721TokenAuthor.sol";
import "Errors.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata URI extension.
 */
contract ThroneNFT is ERC721, ERC721Enumerable, ERC721URIStorage, IERC721TokenAuthor, Ownable {
    uint256 internal _lastTokenId;
    mapping (uint256 => address) private _tokenAuthor;
    string internal _contractURI;

    event ContractURISet(string newContractURI);

    constructor(address ownerAddress) ERC721("ThroneNFT", "THNNFT") Ownable() {
        if (owner() != ownerAddress) {  // openzeppelin v4.1.0 has no _transferOwnership
            require(ownerAddress != address(0), Errors.ZERO_ADDRESS);
            transferOwnership(ownerAddress);
        }
    }

    function _baseURI() override(ERC721) internal pure returns(string memory) {
        return "ipfs://";
    }

    function mintWithTokenURI(string memory _tokenIPFSHash) external returns (uint256) {
        require(bytes(_tokenIPFSHash).length > 0, Errors.EMPTY_METADATA);
        uint256 tokenId = ++_lastTokenId;  // start from 1
        address to = _msgSender();
        _mint(to, tokenId);
        _tokenAuthor[tokenId] = to;
        _setTokenURI(tokenId, _tokenIPFSHash);
        return tokenId;
    }

    function burn(uint256 tokenId) external {
        require(ERC721.ownerOf(tokenId) == msg.sender, Errors.NOT_OWNER);
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

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);  // take care about multiple inheritance
        delete _tokenAuthor[tokenId];
    }

    function tokenAuthor(uint256 tokenId) external override view returns(address) {
        require(_exists(tokenId), Errors.NOT_EXISTS);
        return _tokenAuthor[tokenId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721TokenAuthor).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function contractURI() external view returns(string memory) {
        return _contractURI;
    }

    function setContractURI(string memory newContractURI) onlyOwner external {
        _contractURI = newContractURI;
        emit ContractURISet(newContractURI);
    }
}
