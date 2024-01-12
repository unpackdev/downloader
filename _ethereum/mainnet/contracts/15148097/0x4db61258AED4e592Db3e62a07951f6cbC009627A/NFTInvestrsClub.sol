// SPDX-License-Identifier: MIT

/*///////////////////////////////////////////////////////////////////////////////////
 ▐ ▄ ·▄▄▄▄▄▄▄▄    ▪   ▐ ▄  ▌ ▐·▄▄▄ ..▄▄ · ▄▄▄▄▄▄▄▄  .▄▄ ·      ▄▄· ▄▄▌  ▄• ▄▌▄▄▄▄· 
•█▌▐█▐▄▄·•██      ██ •█▌▐█▪█·█▌▀▄.▀·▐█ ▀. •██  ▀▄ █·▐█ ▀.     ▐█ ▌▪██•  █▪██▌▐█ ▀█▪
▐█▐▐▌██▪  ▐█.▪    ▐█·▐█▐▐▌▐█▐█•▐▀▀▪▄▄▀▀▀█▄ ▐█.▪▐▀▀▄ ▄▀▀▀█▄    ██ ▄▄██▪  █▌▐█▌▐█▀▀█▄
██▐█▌██▌. ▐█▌·    ▐█▌██▐█▌ ███ ▐█▄▄▌▐█▄▪▐█ ▐█▌·▐█•█▌▐█▄▪▐█    ▐███▌▐█▌▐▌▐█▄█▌██▄▪▐█
▀▀ █▪▀▀▀  ▀▀▀     ▀▀▀▀▀ █▪. ▀   ▀▀▀  ▀▀▀▀  ▀▀▀ .▀  ▀ ▀▀▀▀     ·▀▀▀ .▀▀▀  ▀▀▀ ·▀▀▀▀ 
*////////////////////////////////////////////////////////////////////////////////////

// ARTWORK LICENSE: CC0
// No Roadmap, No Utility, 0% Royalties                                                                                 

pragma solidity 0.8.15;

import "./Ownable.sol";
import "./ERC721A.sol";

contract NFTInvestrsClub is ERC721A, Ownable {
  // "not for everyone" Variables
  address private constant RINGMASTER = 0x49086328e44966dE791aC99353c203B039b63e51;
  string private baseURI;

  // "for everyone" Variables
  bool public started = false;
  bool public claimed = false;
  uint256 public constant CLOWN_STAFF = 5210;
  uint256 public constant FUN_LIMIT = 4;
  uint256 public constant CAPTIVE_CLOWNS = 210;

  mapping(address => uint) public addressClaimed;

  constructor() ERC721A("nftinvestrs", "NIC") {}

  // Start at Clown 1, Clown 0 does not exist
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function mint(uint256 _count) external {
    uint256 total = totalSupply();
    uint256 minCount = 0;
    require(started, "HAHAHAhahahHAhahah You wanted to mint? THE CIRCUS IS NOT IN TOWN YET *HONKHONK* HAHAHAHA");
    require(_count > minCount, "*HONKHONK* Silly you! You need to mint at least one HAHAHAHA!");
    require(total + _count <= CLOWN_STAFF, "Actually we don't have that many CLOWNS in here *HONKHONKHONK*!");
    require(addressClaimed[_msgSender()] + _count <= FUN_LIMIT, "*HONKHONK* Don't get GREEDY, I won't give you more than that HAHAHA!");
    require(total <= CLOWN_STAFF, "*HONKHONK* THE CIRCUS IS IN TOWN *HONKHONK*");
    // Flash Clone Clown
    addressClaimed[_msgSender()] += _count;
    _safeMint(msg.sender, _count);
  }

  function teamClaim() external onlyOwner {
    require(!claimed, ":'( THESE CLOWNS ARE STILL WORKING FOR US ),:");
    // Transfer Clowns to the RINGMASTER
    _safeMint(RINGMASTER, CAPTIVE_CLOWNS);
    claimed = true;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function startCircus(bool circusStarted) external onlyOwner {
      started = circusStarted;
  }
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), '):< THERE IS NO CLOWN WITH THAT ID ):<');
    //CLOWN IDENTIFIER DNA
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), '.json'))
        : '';
  }
}