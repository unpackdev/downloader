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

contract JamesBond is ERC721, Ownable {
  string private _title = '007 Bond Soiree';
  string private _description = '007.nyc RSVP NFT';
  string private _presetBaseURI = 'https://arweave.net/';
  string private _imageHash = 'bsdKJWVvfBPdJYEWXM5avDoodrQn43_Yy5DN77lbLC0';
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
    recipients[0] = payable(0x4B49652fBf286b3DA10E44442c38134d841159eF);
    return recipients;
  }

  function getFeeBps(uint256 tokenId) public view returns (uint[] memory) {
    uint[] memory fees;
    fees[0] = 500;
    return fees;
  }

  function royaltyInfo(uint256 tokenId, uint256 value) public view returns (address recipient, uint256 amount){
    return (0x4B49652fBf286b3DA10E44442c38134d841159eF, 500 * value / 10000);
  }
}