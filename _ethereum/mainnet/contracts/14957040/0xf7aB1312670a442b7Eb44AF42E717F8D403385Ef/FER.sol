// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract FER is ERC721A, Ownable {
  address private constant TEAM1 = 0x2D21d640bc81eFf46F6CFA5681f862dfa0BC9121;
  address private constant TEAM2 = 0x6c1E6e34139A348d6fe79A7d6c58CFb286f06823;
  string public _tokenBaseURI;
  using Strings for uint256;
  bool public started = false;
  bool public claimed = false;
  uint256 public constant MAX_SUPPLY = 9999;
  uint256 public constant MAX_MINT = 9;
  uint256 public constant TEAM_CLAIM_AMOUNT = 99;
  mapping(uint256 => string) internal customIdToURI;
  mapping(address => uint) public addressClaimed;

  constructor() ERC721A("FCUK ETH REFUND", "FER") {}

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
      _tokenBaseURI = _baseURI;
  }

  function mint() external {
    require(started, "The mint has not yet started");
    require(addressClaimed[_msgSender()] < MAX_MINT, "You have already received your Token");
    require(totalSupply() < MAX_SUPPLY, "All Tokens claimed!");
    if (!claimed) {
       require(totalSupply() + 198 < MAX_SUPPLY, "All Tokens claimed!");
    }
    // mint
    addressClaimed[_msgSender()] += 9;
    _safeMint(msg.sender, 9);
  }

  function teamClaim() external onlyOwner {
    require(!claimed, "Team already claimed");
    // claim
    _safeMint(TEAM1, TEAM_CLAIM_AMOUNT);
    _safeMint(TEAM2, TEAM_CLAIM_AMOUNT);
    claimed = true;
  }

  function tokenBaseURI() external view returns (string memory) {
      return _tokenBaseURI;
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721A)
      returns (string memory)
  {
      require(tokenId <= totalSupply() - 1, "Token does not exist.");
      return
          string(
              abi.encodePacked(_tokenBaseURI, tokenId.toString())
          );
  }
  function enableMint(bool mintStarted) external onlyOwner {
      started = mintStarted;
  }
}
