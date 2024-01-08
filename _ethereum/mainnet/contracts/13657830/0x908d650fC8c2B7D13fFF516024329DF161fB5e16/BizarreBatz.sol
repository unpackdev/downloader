/********** NFT GENERATOR **********/
//V0.52

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/* IMPORTS */

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "Ownable.sol";
import "Counters.sol";
import "SafeMath.sol";
import "ERC165Storage.sol";
import "IERC2981.sol";

contract BizarreBatz is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, IERC2981, ERC165Storage {

/* GLOBALS */

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public maxMint;
    uint256 public tokenCounter;
    address public devAddress;
  	address private royaltyAddress;
  	uint256 private royaltyPercent;

    // ERC 165
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

/* CONSTRUCTOR */

    constructor() ERC721("BizarreBatz", "BATZ") {
        devAddress = msg.sender;
        _setMaxMintable(3150);
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

/* CUSTOM FUNCTIONS */

    // Mint a new token
    function createToken(string memory tokenURI) public returns (uint256) {
        uint256 newItemId = tokenCounter;
        require(tokenCounter < maxMint);
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _setRoyalties(devAddress, 10);
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }

    // Set maximum mintable tokens
    function _setMaxMintable(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    // EIP-2981 Set to be internal function _setRoyalties
    // _setRoyalties(address,uint256) => 0x40a04a5a
    function _setRoyalties(address _receiver, uint256 _percentage) internal {
      royaltyAddress = _receiver;
      royaltyPercent = _percentage;
    }

    // EIP-2981 Override for royaltyInfo(uint256, uint256)
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override(IERC2981) returns (
        address receiver,
        uint256 royaltyAmount
    ) {
    receiver = royaltyAddress;
    // This sets royalties by price * percentage / 100
    royaltyAmount = _salePrice * royaltyPercent / 100;
    }

    // Override isApprovedForAll to auto-approve OpenSea proxy contract
  	function isApprovedForAll(
  			address _owner,
  			address _operator
  	) public override view returns (bool isOperator) {
  		  // if OpenSea's ERC721 Proxy Address is detected, auto-return true
  			if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
  					return true;
  			}
  			// otherwise, use the default ERC721.isApprovedForAll()
  			return ERC721.isApprovedForAll(_owner, _operator);
  	}

/* SOLIDITY REQUIRED OVERRIDES */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC165Storage, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
