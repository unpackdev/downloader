// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

contract DreamHollywood is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  using Strings for uint256;

  uint256 private maxSupplyTotal = 100;
  uint256 private pricePublic = 3 ether;
  uint256 private constant maxPerTx = 5;
  bool private paused = true;
  string private uriPrefix;
  address private withdrawWallet;

  constructor() ERC721A("Dream Hollywood", "DRMH") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "Minting is paused.");
    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds total supply.");
    _;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.");

    return bytes(uriPrefix).length > 0 ? string(abi.encodePacked(uriPrefix, tokenId.toString(), ".json")) : "";
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(msg.value >= (pricePublic * _mintAmount), "Insufficient balance to mint.");
    require(_mintAmount <= maxPerTx, "Mint amount exceeds max per transaction.");

    _safeMint(_msgSender(), _mintAmount);
  }

  function mintFor(address _receiver, uint256 _mintAmount)
    public
    mintCompliance(_mintAmount)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _safeMint(_receiver, _mintAmount);
  }

  function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(withdrawWallet != address(0), "Withdraw wallet is not set.");

    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }

  function updateWithdrawWallet(address _withdrawWallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawWallet = _withdrawWallet;
  }

  function updateURIPrefix(string memory _uriPrefix) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uriPrefix = _uriPrefix;
  }

  function togglePause(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
    paused = _state;
  }
}
