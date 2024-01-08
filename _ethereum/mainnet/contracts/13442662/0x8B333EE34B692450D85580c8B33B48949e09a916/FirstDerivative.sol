// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC1155.sol";
import "./ERC165Checker.sol";
import "./SafeCast.sol";
import "./Strings.sol";


import "./base64.sol";
import "./CryptopunksData.sol";
import "./ERC2981.sol";

/**
 * @title FirstDerivative contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract FirstDerivative is ERC721, ERC2981, Ownable {
    using SafeMath for uint256;
    using ERC165Checker for address;

    struct Underlying {
      address collection;
      uint256 tokenId;
    }

    bytes4  private constant _INTERFACE_ID_ERC721      = 0x80ac58cd;
    bytes4  private constant _INTERFACE_ID_ERC1155     = 0xd9b67a26;
    address private constant _CRYPTOPUNKS_ADDRESS      = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address private constant _CRYPTOPUNKS_DATA_ADDRESS = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;

    uint256 public derivativePrice;
    uint256 public maxDerivativeDepth;

    mapping(bytes32 => uint256)    private _issuedDerivatives;
    mapping(uint256 => Underlying) private _underlyings;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
      _setRoyalties(msg.sender, 1000);
      maxDerivativeDepth = 1;
      derivativePrice    = 26000000000000000; //0.026 ETH
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function setMaxDerivativeDepth(uint256 depth) public onlyOwner {
      maxDerivativeDepth = depth;
    }

    function setDerivativePrice(uint256 price) public onlyOwner {
      derivativePrice = price;
    }

    function mintDerivative(address collection, uint256 tokenId) public payable returns (uint256) {
        require(derivativePrice <= msg.value, "Eth value sent is not sufficient");
        require(collection.supportsInterface(_INTERFACE_ID_ERC721) || collection.supportsInterface(_INTERFACE_ID_ERC1155) || collection == _CRYPTOPUNKS_ADDRESS, "Derivative collection is not ERC721, ERC1155 or supported NFT type");
        require(_getIssuedDerivativeTokenId(collection, tokenId) == 0, "Derivative has already been issued for this token");

        if (collection == address(this)) {
          require(getDepthOfDerivative(tokenId) + 1 <= maxDerivativeDepth, "Derivative would exceed maximum depth");
        }

        uint mintIndex = totalSupply() + 1;

        _setIssuedDerivativeTokenId(collection, tokenId, mintIndex);
        _setUnderlying(mintIndex, Underlying(collection, tokenId));

        _safeMint(msg.sender, mintIndex);

        return mintIndex;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        (address underlyingCollectionId, uint256 underlyingTokenId) = getUnderlying(tokenId);

        if (underlyingCollectionId.supportsInterface(_INTERFACE_ID_ERC721)) {
          return IERC721Metadata(underlyingCollectionId).tokenURI(underlyingTokenId);
        } else if (underlyingCollectionId.supportsInterface(_INTERFACE_ID_ERC1155)) {
          return IERC1155MetadataURI(underlyingCollectionId).uri(underlyingTokenId);
        } else if (underlyingCollectionId == _CRYPTOPUNKS_ADDRESS) {
          return _constructCryptopunksUri(underlyingTokenId);
        } else {
          revert("Unsupported underlying contract type");
        }
    }

    function getDerivative(address collection, uint256 tokenId) public view returns (uint256) {
      return _getIssuedDerivativeTokenId(collection, tokenId);
    }

    function getUnderlying(uint256 tokenId) public view returns (address, uint256) {
      require(_exists(tokenId), "Query for non-existing token");
      Underlying storage underlying = _underlyings[tokenId];

      return (underlying.collection, underlying.tokenId);
    }

    function setRoyalties(uint256 royalty) public onlyOwner {
      _setRoyalties(this.owner(), royalty);
    }

    function getDepthOfDerivative(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId));

      uint256 depth        = 1;
      uint256 derivativeId = tokenId;

      while (true) {
        (address underlyingCollectionId, uint256 underlyingTokenId) = getUnderlying(derivativeId);

        if (underlyingCollectionId != address(this)) {
          return depth;
        } else {
          depth++;
          derivativeId = underlyingTokenId;
        }
      }
    }

    function _setUnderlying(uint256 tokenId, Underlying memory underlying) private {
      _underlyings[tokenId] = underlying;
    }

    function _getIssuedDerivativeTokenId(address collection, uint256 tokenId) private view returns (uint256) {
      return _issuedDerivatives[_underlyingHash(collection, tokenId)];
    }

    function _setIssuedDerivativeTokenId(address collection, uint256 tokenId, uint256 derivativeId) private {
      _issuedDerivatives[_underlyingHash(collection, tokenId)] = derivativeId;
    }

    function _underlyingHash(address collection, uint256 tokenId) private pure returns (bytes32) {
      return keccak256(abi.encodePacked(collection, tokenId));
    }

    function _constructCryptopunksUri(uint256 tokenId) private view returns (string memory) {
      bytes  memory imageSvg = _getPunkSvg(tokenId);
      string memory json     = Base64.encode(abi.encodePacked('{"name":"CryptoPunk #', Strings.toString(tokenId), '","image":"data:image/svg+xml;base64,', Base64.encode(imageSvg), '"}'));

      return string(abi.encodePacked("data:applicaion/json;base64,", json));
    }

    function _getPunkSvg(uint256 tokenId) private view returns (bytes memory) {
      bytes memory imageSvgUri = bytes(CryptopunksData(_CRYPTOPUNKS_DATA_ADDRESS).punkImageSvg(SafeCast.toUint16(tokenId)));
      bytes memory imageSvg    = new bytes(imageSvgUri.length - 24);

      for (uint i=0;i<imageSvg.length;i++) {
        imageSvg[i] = imageSvgUri[i + 24];
      }

      return imageSvg;
    }
}
