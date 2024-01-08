// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./base64.sol";
import "./console.sol";

contract UniversalPoetry is ERC721, Ownable {
  string private _title = 'Universal Poetry';
  string private _description = 'VIP Entry NFT';
  string private _presetBaseURI = 'https://arweave.net/';
  string private _imageHash = 'JouPE---ZSWvZEjQ-ZTU4Qk6PQNXElmNbxF34X4XrB8';
  string private _assetHash;
  bool public mintingFinalized;

  uint256 private tokenIndex = 1;

  constructor(
    string memory name,
    string memory symbol,
    string memory assetHash
  ) ERC721(name, symbol) {
    _assetHash = assetHash;
    mintingFinalized = false;
  }

  function mintRSVP(address winner) public onlyOwner {
    _safeMint(winner, tokenIndex);
    tokenIndex++;
  }

  function updateAsset(string memory asset) public onlyOwner {
    _assetHash = asset;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
    require(ownerOf(tokenId) != address(0));

    string memory encoded = string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"',
              _title,
              ' #',
              Strings.toString(tokenId),
              '", "description":"',
              _description,
              '", "image": "',
              _presetBaseURI,
              _imageHash,
              '", "animation_url": "',
              _presetBaseURI,
              _assetHash,
              '" }'
            )
          )
        )
      )
    );

    return encoded;
  }

  bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || super.supportsInterface(interfaceId);
  }

  function getFeeRecipients(uint256 tokenId) public view returns (address payable[] memory) {
    address payable[] memory recipients;
    recipients[0] = payable(0xa8047C2a86D5A188B0e15C3C10E2bc144cB272C2);
    return recipients;
  }

  function getFeeBps(uint256 tokenId) public view returns (uint[] memory) {
    uint[] memory fees;
    fees[0] = 500;
    return fees;
  }

  function royaltyInfo(uint256 tokenId, uint256 value) public view returns (address recipient, uint256 amount){
    return (0xa8047C2a86D5A188B0e15C3C10E2bc144cB272C2, 500 * value / 10000);
  }
}