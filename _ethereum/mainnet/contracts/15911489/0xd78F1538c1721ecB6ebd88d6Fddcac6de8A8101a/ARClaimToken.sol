// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./ARLibrary.sol";

contract ARClaimToken is ERC721, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIdCounter;

  mapping(string => uint256) public barcodeToTokenId;
  mapping(uint256 => ARLibrary.Claim) public claims;
  mapping(uint256 => ARLibrary.Beneficiary[]) public beneficiaries;
  mapping(uint256 => string) private _tokenURIs;
  mapping(string => bool) public materials;

  event ClaimCreated(
    uint256 tokenId,
    address claimCreator,
    string country,
    string tokenURI,
    string barcodeId,
    string material,
    uint256 mass,
    uint256 purity,
    ARLibrary.Beneficiary[] beneficiaries
  );

  constructor() ERC721("ARClaimTokenV2", "ARCT") {}

  function _baseURI() internal pure override returns (string memory) {
    return "https://ipfs.io/ipfs/";
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  function mintClaim(
    string memory _country,
    string memory _barcodeId,
    string memory _material,
    uint256 _mass,
    uint256 _purity,
    ARLibrary.Beneficiary[] memory _beneficiaries,
    string memory _tokenUri
  ) public {
    require(materials[_material] == true, "Material does not exist");
    require(barcodeToTokenId[_barcodeId] == 0, "Barcode already exists");

    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();

    barcodeToTokenId[_barcodeId] = tokenId;

    ARLibrary.Claim storage cm = claims[tokenId];
    cm.creator = msg.sender;
    cm.country = _country;
    cm.barcodeId = _barcodeId;
    cm.material = _material;
    cm.mass = _mass;
    cm.purity = _purity;

    // 30% Benes, 30% COOP, 10% Protocol, 30% Exporter ---> standard
    uint256 totalPercent = 0;
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      cm.beneficiaries.push(_beneficiaries[i].beneficiary);
      cm.percentages.push(_beneficiaries[i].percent);
      totalPercent += _beneficiaries[i].percent;
    }
    require(totalPercent <= 7_000, "Max sum of benficiary percentages is 70%.");

    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, _tokenUri);

    emit ClaimCreated(tokenId, msg.sender, _country, _tokenUri, _barcodeId, _material, _mass, _purity, _beneficiaries);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = _baseURI();

    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }
    return string(abi.encodePacked(base, tokenId.toString()));
  }

  // VIEW FUNCTIONS
  function getMaterial(string memory _material) public view returns (bool) {
    return materials[_material];
  }

  function getBeneficiaries(uint256 _tokenId) public view returns (ARLibrary.Beneficiary[] memory) {
    return beneficiaries[_tokenId];
  }

  function getClaim(uint256 _tokenId) public view returns (ARLibrary.Claim memory) {
    return claims[_tokenId];
  }

  // ADMIN FUNCTIONS
  function addMaterial(string memory _material) public onlyOwner {
    materials[_material] = true;
  }

  function removeMaterial(string memory _material) public onlyOwner {
    materials[_material] = false;
  }
}
