// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./ERC721Metadata.sol";

contract NWCMembership is ERC721Metadata, ReentrancyGuard, Pausable {
  // Max supply of NFTs
  uint256 public MAX_NFT_SUPPLY = 300;

  // Mint price is 1.5 AVAX
  uint256 public mintPrice = 1 ether;

  // Total supply of NFTs
  uint256 private _totalSupply;

  // Admin wallets
  address public admin;

  modifier beforeMint() {
    require(_totalSupply < MAX_NFT_SUPPLY, "Not enough remaining");
    require(mintPrice == msg.value, "Invalid ether value");

    _;
  }

  constructor(string memory baseURI_, address _admin)
    ERC721Metadata("Builder Collection", "NWCBM", baseURI_)
  {
    admin = _admin;
    _pause();
  }

  // Ownable functions
  function pauseMint() external onlyOwner {
    _pause();
  }

  function unpauseMint() external onlyOwner {
    _unpause();
  }

  function setAdmin(address _admin) external onlyOwner {
    admin = _admin;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    require(_mintPrice > 0, "Price can't be zero");
    mintPrice = _mintPrice;
  }

  function _ownerMint(address recipient, uint256 tokenId) private {
    require(recipient != address(0), " Invalid recipient");
    require(!_exists(tokenId), "Already minted");
    _mint(recipient, tokenId);
    _totalSupply++;
  }

  function ownerMint(address recipient, uint256 tokenId) external onlyOwner {
    _ownerMint(recipient, tokenId);
  }

  function ownerMintBatch(address[] calldata recipients, uint256[] calldata tokenIds)
    external
    onlyOwner
  {
    require(recipients.length == tokenIds.length, "Length mismatch");
    for (uint256 i = 0; i < recipients.length; i++) {
      _ownerMint(recipients[i], tokenIds[i]);
    }
  }

  // end of ownable functions

  function publicMint(uint256 tokenId) external payable beforeMint() whenNotPaused nonReentrant {
    require(!_exists(tokenId), "Already minted");
    _mint(msg.sender, tokenId);
    _totalSupply++;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Withdraw the contract balance to the administrator address
   */
  function withdraw() external onlyOwner {
    uint256 amount = address(this).balance;
    (bool success, ) = admin.call{value: amount}("");
    require(success, "Failed to send ether");
  }
}
