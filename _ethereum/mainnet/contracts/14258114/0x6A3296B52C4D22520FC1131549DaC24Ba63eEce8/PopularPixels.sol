// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

import "./base64.sol";
import "./Verifier.sol";

import "./console.sol";


/**
 * @title Popular pixels contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract PopularPixels is ERC721Enumerable, Ownable {

    struct OwnerMapItem {
      uint256 tokenId;
      address owner;
    }

    event Revision(address creator, uint256 tokenId, bytes data);

    uint256 public constant TOTAL_DIMENSION    = 1000;
    uint256 public constant PIXEL_BLOCK_SIZE   = 50;
    uint256 public constant TOTAL_PIXEL_BLOCKS = (TOTAL_DIMENSION * TOTAL_DIMENSION) / (PIXEL_BLOCK_SIZE * PIXEL_BLOCK_SIZE);


    mapping(uint256 => bytes) private _data;

    address private _verifierAddress;
    uint256 private _revisionCount;
    uint256 private _price;


    constructor(string memory name, string memory symbol, address verifierAddress) ERC721(name, symbol) {
      _price           = 500000000000000000; // .50 eth
      _verifierAddress = verifierAddress;
      _revisionCount   = 0;
    }

    function getAvailablePixelBlocksCount() public view returns (uint256) {
      return TOTAL_PIXEL_BLOCKS - totalSupply();
    }

    function getRevisionCount() public view returns (uint256) {
      return _revisionCount;
    }

    function getOwnersMap() public view returns (OwnerMapItem[] memory) {
      OwnerMapItem[] memory owners = new OwnerMapItem[](totalSupply());

      for (uint256 i=0;i<totalSupply();i++) {
        uint256 tokenId = tokenByIndex(i);
        address owner   = ownerOf(tokenId);

        owners[i] = OwnerMapItem({tokenId: tokenId, owner: owner});
      }

      return owners;
    }

    function mint(uint256[] memory tokenIds) public payable {
      for (uint i=0;i<tokenIds.length;i++) require(!_exists(tokenIds[i]), "Token has already been minted");
      for (uint i=0;i<tokenIds.length;i++) require(tokenIds[i] < TOTAL_PIXEL_BLOCKS, "Token out of range");
      require(_price * tokenIds.length <= msg.value, "Eth value sent is not sufficient");

      for (uint i=0;i<tokenIds.length;i++) {
        _safeMint(msg.sender, tokenIds[i]);
      }
    }

    function save(uint256 tokenId, bytes memory data) public {
      require(_exists(tokenId), "Token has not been minted");
      require(ownerOf(tokenId) == msg.sender, "Not your token");

      Verifier.ResponseCode memory result = Verifier(_verifierAddress).validate(data);
      require(result.valid, result.reason);

      _data[tokenId] = data;
      _revisionCount += 1;

      emit Revision(msg.sender, tokenId, data);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "URI query for nonexistent token");

      string memory svgUri  = getEncodedSvgUri();
      string memory json    = Base64.encode(abi.encodePacked('{"name":"Popular Pixels #', Strings.toString(tokenId), '","image":"', svgUri, '"}'));
      string memory jsonUri = string(abi.encodePacked("data:application/json;base64,", json));

      return jsonUri;
    }

    function getEncodedSvgUri() public view returns (string memory) {
      return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(getSvg()))));
    }

    function getSvg() public view returns (string memory) {
      bytes[] memory fragments   = new bytes[](TOTAL_PIXEL_BLOCKS + 2);
      uint256        totalLength = 0;

      fragments[0] = abi.encodePacked('<svg viewBox="0 0 ', Strings.toString(TOTAL_DIMENSION), ' ', Strings.toString(TOTAL_DIMENSION), '" xmlns="http://www.w3.org/2000/svg">');
      totalLength += fragments[0].length;

      for (uint256 i=0;i<TOTAL_PIXEL_BLOCKS;i++) {
        uint256 x = (i * PIXEL_BLOCK_SIZE) % TOTAL_DIMENSION;
        uint256 y = ((i * PIXEL_BLOCK_SIZE) / TOTAL_DIMENSION) * PIXEL_BLOCK_SIZE;

        bytes memory encodedFragment = abi.encodePacked('<svg x="', Strings.toString(x), '" y="', Strings.toString(y), '" width="50" height="50" viewBox="0 0 50 50">', _data[i], '</svg>');

        fragments[i + 1] = encodedFragment;
        totalLength     += encodedFragment.length;
      }

      fragments[fragments.length - 1] = '</svg>';
      totalLength += fragments[fragments.length - 1].length;

      return string(_concatenateArray(fragments, totalLength));
    }

    function setPrice(uint256 newPrice) public onlyOwner {
      _price = newPrice;
    } 

    function getPrice() public view returns (uint256) {
      return _price;
    }

    function setVerifierAddress(address verifierAddress) public onlyOwner {
      _verifierAddress = verifierAddress;
    }

    function _concatenateArray(bytes[] memory input, uint256 outputLength) private pure returns (bytes memory result) {
      bytes   memory output = new bytes(outputLength);
      uint256        offset = 0;

      uint outputPtr;
      assembly { outputPtr := add(output, 32) }

      for (uint256 i=0;i<input.length;i++) {
        bytes   memory inputElement = input[i];
        uint256        length       = inputElement.length;

        uint inputElementPtr;
        assembly { inputElementPtr := add(inputElement, 32) }

        _memcpy(outputPtr + offset, inputElementPtr, length);
        offset += length;
      }

      return output;
    }

    function _memcpy(uint dest, uint src, uint len) private pure {
      // Copy word-length chunks while possible
      for(; len >= 32; len -= 32) {
        assembly {
          mstore(dest, mload(src))
        }
        dest += 32;
        src += 32;
      }

      // Copy remaining bytes
      if (len > 0) {
        uint mask = 256 ** (32 - len) - 1;
        assembly {
          let srcpart := and(mload(src), not(mask))
          let destpart := and(mload(dest), mask)
          mstore(dest, or(destpart, srcpart))
        }
      }
    }
}