// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./AccessOperatable.sol";

// On Chain Maids Contract Interface(Full on chain metadata)
interface iOCM {
  function tokenURI(uint256 tokenId_) external view returns (string memory);
}

contract CryptoMaidsOnChain is ERC721A, AccessOperatable {
  iOCM public OCM;
  bool public useOnChainMetadata = false;
  uint256 public constant MAX_ELEMENTS = 10000;
  string public defaultURI;

  event UpdateDefaultURI(string defaultURI);

  constructor() ERC721A("CryptoMaidsOnChain", "CMOC") {
    defaultURI = "https://api.cryptomaids.tokyo/metadata/body/";
  }

  function setOCM(address address_) external {
    OCM = iOCM(address_);
  }

  function setOnChainMetadata(bool useOnChainMetadata_) external {
    useOnChainMetadata = useOnChainMetadata_;
  }

  function mint(address to, uint256 quantity) external onlyOperator()  {
    // limit supply
    require(totalSupply() <= MAX_ELEMENTS, "Exceed Max Elements");
    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(to, quantity);
  }

  // mint by the arrays of to and quantity
  function bulkMint(address[] memory _tos, uint256[] memory _quantities) public onlyOperator() {
    require(_tos.length == _quantities.length);
    uint8 i;
    for (i = 0; i < _tos.length; i++) {
      _safeMint(_tos[i], _quantities[i]);
    }
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    // change contract metadata if useOnChainMetadata is true
    if (useOnChainMetadata && OCM != iOCM(address(0x0))) {
      return OCM.tokenURI(tokenId);
    } else {
      return super.tokenURI(tokenId);
    }
  }

  function setDefaultURI(string memory defaultURI_) public onlyOperator() {
    defaultURI = defaultURI_;
  }

  function _baseURI() internal view override returns (string memory) {
    return defaultURI;
  }

  function withdraw(address withdrawAddress) public {
    uint256 balance = address(this).balance;
    require(balance > 0);
    (bool success, ) = withdrawAddress.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}