// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract WAG2FADIE is ERC721A, Ownable {
  // "Private" Variables
  address private constant FLIPPER1 = 0x940498BaE9cd95d8D6ea7080E3a276f6Db14C175;
  address private constant FLIPPER2 = 0x5893797fd329Df12C0Bb5C9213aF701642E3BaF3;
  string private baseURI;

  // Public Variables
  bool public started = false;
  bool public claimed = false;
  uint256 public constant MAX_SUPPLY = 6666;
  uint256 public constant MAX_MINT = 2;
  uint256 public constant TEAM_CLAIM_AMOUNT = 56;

  mapping(address => uint) public addressClaimed;

  constructor() ERC721A("We Are All Going to Flip and Die", "WAG2FADIE") {}

  // Start tokenid at 1 instead of 0
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function mint() external {
    require(started, "The pilgrimage to this land has not yet flipped");
    require(addressClaimed[_msgSender()] < MAX_MINT, "You have already received your Token(s) of Worship");
    require(totalSupply() < MAX_SUPPLY, "All lost souls that have flipped are accounted for");
    // mint
    addressClaimed[_msgSender()] += 1;
    _safeMint(msg.sender, 1);
  }

  function teamClaim() external onlyOwner {
    require(!claimed, "Team already claimed");
    // claim
    _safeMint(FLIPPER1, TEAM_CLAIM_AMOUNT);
    _safeMint(FLIPPER2, TEAM_CLAIM_AMOUNT);
    claimed = true;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function enableMint(bool mintStarted) external onlyOwner {
      started = mintStarted;
  }
}