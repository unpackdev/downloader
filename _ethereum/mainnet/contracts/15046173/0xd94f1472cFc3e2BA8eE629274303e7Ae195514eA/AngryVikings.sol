                                                                                              // SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract AngryVikings is ERC721A, Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Strings for uint256;


  // "Private" Variables
  address private constant VIKING1 = 0x25A01df4Ca1A90f850CFDAb38644f8ffa47e0E7B;
  string private blindURI;
  string private baseURI;

  // Public Variables
  bool public started = false;
  bool public claimed = false;
  bool public reveal = false;
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant MAX_MINT = 2;
  uint256 public constant TEAM_CLAIM_AMOUNT = 500;

  mapping(address => uint) public addressClaimed;

  constructor() ERC721A("Angry Vikings", "AngryVikings") {}

  // Start tokenid at 1 instead of 0
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function mint() external {
    require(started, "Valhalla is still waiting for the vikings.");
    require(addressClaimed[_msgSender()] < MAX_MINT, "You have already received your Angry Vikings");
    require(totalSupply() < MAX_SUPPLY, "All Angry Vikings have entered to Valhalla.");
    // mint
    addressClaimed[_msgSender()] += 1;
    _safeMint(msg.sender, 1);
  }

  function teamClaim() external onlyOwner {
    require(!claimed, "Team already claimed");
    // claim
    _safeMint(VIKING1, TEAM_CLAIM_AMOUNT);
    claimed = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function enableMint(bool mintStarted) external onlyOwner {
      started = mintStarted;
  }

  function setReveal(bool revealed) external onlyOwner {
      reveal = revealed;
  }

  function setURIs(string memory _blindURI, string memory _URI) external onlyOwner {
      blindURI = _blindURI;
      baseURI = _URI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      if (!reveal) {
          return string(abi.encodePacked(blindURI));
      } else {
          return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
      }
  }
}