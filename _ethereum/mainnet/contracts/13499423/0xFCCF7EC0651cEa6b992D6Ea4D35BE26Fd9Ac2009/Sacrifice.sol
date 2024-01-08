// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./IERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./IShogunNFT.sol";

contract Sacrifice is Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint256;

  IShogunNFT public shogunNFT;
  address public vault; // holds all unrevealed Samurais

  uint256 public revealedCount;

  // allows transactiones from only externally owned account (cannot be from smart contract)
  modifier onlyEOA() {
    require(msg.sender == tx.origin, "SHOGUN: Only EOA");
    _;
  }

  constructor(address _shogunNFT, address _vault) {
    shogunNFT = IShogunNFT(_shogunNFT);
    vault = _vault;
    _pause();
  }

  function sacrifice(uint256 tokenId) external whenNotPaused onlyEOA nonReentrant {
    require(
      shogunNFT.isApprovedForAll(vault, address(this)),
      "SHOGUN: vault is locked"
    );
    require(
      shogunNFT.balanceOf(vault) > 0,
      "SHOGUN: no more samurais available"
    );
    require(
      tokenId <= revealedCount,
      "SHOGUN: cannot sacrifice unrevealed samurai"
    );
    uint256 newTokenId = shogunNFT.tokenOfOwnerByIndex(vault, 0);
    shogunNFT.seppuku(tokenId);
    shogunNFT.safeTransferFrom(vault, msg.sender, newTokenId);
  }

  //*************** OWNER FUNCTIONS ******************//
  function setPaused(bool _state) external onlyOwner {
    if (_state) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setRevealedCount(uint256 _state) external onlyOwner {
    revealedCount = _state;
  }

  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }
}
