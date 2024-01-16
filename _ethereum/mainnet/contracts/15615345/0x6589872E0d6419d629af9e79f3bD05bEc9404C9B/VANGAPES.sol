// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract VANGAPES is ERC721A, Ownable {
  // "Private" Variables
  address private constant TEAM = 0x2363Ece18566b087109B6388dfA1fFA1Df9dfA8b;
  string private baseURI;

  // Public Variables
  bool public started = false;
  bool public claimed = false;
  uint256 public constant MAX_SUPPLY = 1000;
  uint256 public constant MAX_MINT = 1;
  uint256 public constant TEAM_CLAIM_AMOUNT = 30  ;

  mapping(address => uint) public addressClaimed;

  constructor() ERC721A("Van Gapes", "VANGAPES") {}

  // Start tokenid at 1 instead of 0
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function mint() external {
    require(started, "The Apes have not yet been unleashed");
    require(addressClaimed[_msgSender()] < MAX_MINT, "You have already received your Ape");
    require(totalSupply() < MAX_SUPPLY, "All Apes have been claimed");
    // mint
    addressClaimed[_msgSender()] += 1;
    _safeMint(msg.sender, 1);
  }

  function teamClaim() external onlyOwner {
    require(!claimed, "Team already claimed");
    // claim
    _safeMint(TEAM, TEAM_CLAIM_AMOUNT);
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