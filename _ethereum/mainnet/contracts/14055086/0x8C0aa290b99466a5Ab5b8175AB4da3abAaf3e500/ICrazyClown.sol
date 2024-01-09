// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

/*
 ▄████▄   ██▀███   ▄▄▄      ▒███████▒▓██   ██▓
▒██▀ ▀█  ▓██ ▒ ██▒▒████▄    ▒ ▒ ▒ ▄▀░ ▒██  ██▒
▒▓█    ▄ ▓██ ░▄█ ▒▒██  ▀█▄  ░ ▒ ▄▀▒░   ▒██ ██░
▒▓▓▄ ▄██▒▒██▀▀█▄  ░██▄▄▄▄██   ▄▀▒   ░  ░ ▐██▓░
▒ ▓███▀ ░░██▓ ▒██▒ ▓█   ▓██▒▒███████▒  ░ ██▒▓░
░ ░▒ ▒  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▒▒ ▓░▒░▒   ██▒▒▒
  ░  ▒     ░▒ ░ ▒░  ▒   ▒▒ ░░░▒ ▒ ░ ▒ ▓██ ░▒░
░          ░░   ░   ░   ▒   ░ ░ ░ ░ ░ ▒ ▒ ░░
░ ░         ░           ░  ░  ░ ░     ░ ░
░                           ░         ░ ░
 ▄████▄   ██▓     ▒█████   █     █░ ███▄    █   ██████
▒██▀ ▀█  ▓██▒    ▒██▒  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██    ▒
▒▓█    ▄ ▒██░    ▒██░  ██▒▒█░ █ ░█ ▓██  ▀█ ██▒░ ▓██▄
▒▓▓▄ ▄██▒▒██░    ▒██   ██░░█░ █ ░█ ▓██▒  ▐▌██▒  ▒   ██▒
▒ ▓███▀ ░░██████▒░ ████▓▒░░░██▒██▓ ▒██░   ▓██░▒██████▒▒
░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
  ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  ░ ░░   ░ ▒░░ ░▒  ░ ░
░          ░ ░   ░ ░ ░ ▒    ░   ░     ░   ░ ░ ░  ░  ░
░ ░          ░  ░    ░ ░      ░             ░       ░
░

Crazy Clowns Insane Asylum
2021, V1.1
https://ccia.io
*/

interface ICrazyClown {
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

  function MINTER_ROLE() external view returns (bytes32);

  function PublicRevealStatus() external view returns (bool);

  function _changeBioFee() external view returns (uint256);

  function _changeNameFee() external view returns (uint256);

  function getTokenBio(uint256 _tokenId) external view returns (string memory);

  function getTokenName(uint256 _tokenId) external view returns (string memory);

  // function addAttributes ( tuple[] _attributes ) external;
  function addContractToWhitelist(address _contract) external;

  function addMinterRole(address _address) external;

  function addToPreSaleList(address[] memory entries) external;

  // function addTokenIdHash ( tuple[] _hashList ) external;
  function approve(address to, uint256 tokenId) external;

  function attributes(string memory)
    external
    view
    returns (
      string memory id,
      string memory trait_type,
      string memory value
    );

  function balanceOf(address owner) external view returns (uint256);

  // function buildTokenUri ( tuple meta ) external view returns ( string );
  function burn(uint256 tokenId) external;

  function changeBio(uint256 _tokenId, string memory _bio) external;

  function changeName(uint256 _tokenId, string memory _name) external;

  function contractURI() external view returns (string memory);

  function dataURI(uint256 tokenId) external view returns (string memory);

  function evolve_mint(address _user) external;

  function flipPreSaleStatus() external;

  function flipPublicSaleStarted() external;

  // function genericDataURI ( string name, string description, string external_url, string imageUrl, uint256 mintDate, tuple[] attributesData ) external view returns ( string );
  function getApproved(uint256 tokenId) external view returns (address);

  function getPreSalePrice() external view returns (uint256);

  function getPrice() external view returns (uint256);

  function getReservedLeft() external view returns (uint256);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function hasRole(bytes32 role, address account) external view returns (bool);

  function hashList(uint256) external view returns (string memory);

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function isPreSaleApproved(address addr) external view returns (bool);

  function maxSupply() external view returns (uint256);

  function mint(uint256 _nbTokens, bool _allowStaking) external;

  function mintListPurchases(address) external view returns (uint256);

  function name() external view returns (string memory);

  function ownerOf(uint256 tokenId) external view returns (address);

  function placeHolderURI() external view returns (string memory);

  function preSaleListPurchases(address) external view returns (uint256);

  function preSaleLive() external view returns (bool);

  function preSaleMintLimit() external view returns (uint256);

  function preSalePrice() external view returns (uint256);

  function preSaleWhitelist(address) external view returns (bool);

  function price() external view returns (uint256);

  function provenanceHash() external view returns (string memory);

  function publicMintLimit() external view returns (uint256);

  function publicSaleTransLimit() external view returns (uint256);

  function removeContractFromWhitelist(address _contract) external;

  function removeFromPreSaleList(address[] memory entries) external;

  function renounceRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) external;

  function saleStarted() external view returns (bool);

  function sendReserve(address _receiver, uint256 _nbTokens) external;

  function setApprovalForAll(address operator, bool approved) external;

  function setBaseURI(string memory _URI) external;

  function setChangeBioFee(uint256 _fee) external;

  function setChangeNameFee(uint256 _fee) external;

  function setContractURI(string memory _URI) external;

  function setPlaceholderURI(string memory uri) external;

  function setPreSaleMintLimit(uint256 _newPresaleMintLimit) external;

  function setPreSalePrice(uint256 _newPreSalePrice) external;

  function setPrice(uint256 _newPrice) external;

  function setProvenanceHash(string memory _provenanceHash) external;

  function setPublicMintLimit(uint256 limit) external;

  function setPublicSaleTransLimit(uint256 limit) external;

  function setReservedSupply(uint256 _newReservedSupply) external;

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function symbol() external view returns (string memory);

  function togglePublicReveal() external;

  function tokenByIndex(uint256 index) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function utilityToken() external view returns (address);

  function walletOfOwner(address _owner) external view returns (uint256[] memory);

  function withdraw(address _receiver) external;
}
