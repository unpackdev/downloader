
//    ______                              ______ _           _
//   / _____)                  _         / _____) |         (_)     _
//  | /       ____ _   _ ____ | |_  ___ | /     | | _   ____ _  ___| |_  ____   ____ _____
//  | |      / ___) | | |  _ \|  _)/ _ \| |     | || \ / ___) |/___)  _)|    \ / _  (___  )
//  | \_____| |   | |_| | | | | |_| |_| | \_____| | | | |   | |___ | |__| | | ( ( | |/ __/
//   \______)_|    \__  | ||_/ \___)___/ \______)_| |_|_|   |_(___/ \___)_|_|_|\_||_(_____)
//                (____/|_|
//
// Powered by:
//     _____ __          __________     __  ____       __
//    / ___// /_  __  __/ __/ __/ /__  /  |/  (_)___  / /_
//    \__ \/ __ \/ / / / /_/ /_/ / _ \/ /|_/ / / __ \/ __/
//   ___/ / / / / /_/ / __/ __/ /  __/ /  / / / / / / /_
//  /____/_/ /_/\__,_/_/ /_/ /_/\___/_/  /_/_/_/ /_/\__/
//                                          @shufflemint
// SPDX-License-Identifier: MIT



pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CryptoChristmaz is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string baseURI;
  string baseContractURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.035 ether;
  uint256 public maxSupply = 2222;
  uint256 public maxMintAmount = 10;
  bool public publicActive = false;
  bool public presaleActive = false;
  bool public revealed = false;
  string public notRevealedUri;
  uint256 public teamClaimAmount = 50;
  bool public teamClaimed = false;

  // Payment Addresses
  address christmas = 0xE73c1BdaDF6e81bF63Ca1DC482DebE7E44F6a778;
  address shufflemint = 0xC79108A7151814A77e1916E61e0d88D5EA935c84;

  mapping (address => bool) public claimWhitelist;

  event Minted(uint256 indexed tokenId, address indexed owner);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    string memory _contractURI_
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    baseContractURI = _contractURI_;
    setNotRevealedURI(_initNotRevealedUri);
    _tokenIds.increment();
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function publicMint(uint256 _mintAmount) public payable {
    require(publicActive, "Sale has not started yet.");
    require(_mintAmount > 0, "Quantity cannot be zero");
    require(_mintAmount <= maxMintAmount, "Exceeds 20, the max qty per mint.");
    require(totalSupply() + _mintAmount <= maxSupply, "Quantity requested exceeds max supply.");
    require(msg.value >= cost * _mintAmount, "Ether value sent is below the price");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 mintIndex = _tokenIds.current();
      _safeMint(msg.sender, mintIndex);

      // increment id counter
      _tokenIds.increment();
      emit Minted(mintIndex, msg.sender);
    }
  }


  function claim() public {
      require(presaleActive || publicActive,   "A sale period must be active to claim");
      require(claimWhitelist[msg.sender],      "No claim available for this address");
      require(totalSupply() + 1 <= maxSupply,  "Quantity requested exceeds max supply.");

      uint256 mintIndex = _tokenIds.current();
      _safeMint(msg.sender, mintIndex);

      // increment id counter
      _tokenIds.increment();
      emit Minted(mintIndex, msg.sender);
      claimWhitelist[msg.sender] = false;
  }

  function teamClaim() public onlyOwner {
      require(totalSupply() + teamClaimAmount <= maxSupply, "Quantity requested exceeds max supply.");
      require(!teamClaimed, "Team has claimed");
      for (uint256 i = 1; i <= teamClaimAmount; i++) {
        uint256 mintIndex = _tokenIds.current();
        _safeMint(christmas, mintIndex);

      _tokenIds.increment();
      }
    teamClaimed = true;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if(revealed == false) {
      return bytes(notRevealedUri).length > 0
          ? string(abi.encodePacked(notRevealedUri, tokenId.toString(), baseExtension))
          : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function publicLive(bool _state) public onlyOwner {
    publicActive = _state;
  }

  function presaleLive(bool _state) public onlyOwner {
    presaleActive = _state;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds.current() - 1;
  }

  function withdraw() public payable onlyOwner {
    // Shufflemint 10%
    (bool sm, ) = payable(shufflemint).call{value: address(this).balance * 50 / 100}("");
    require(sm);

    // Notables 90%
    (bool os, ) = payable(christmas).call{value: address(this).balance}("");
    require(os);
  }

  function editClaimList(address[] calldata claimAddresses) public onlyOwner {
      for(uint256 i; i < claimAddresses.length; i++){
          claimWhitelist[claimAddresses[i]] = true;
      }
  }

  function contractURI() public view returns (string memory) {
    return baseContractURI;
  }

  function setContractURI(string memory uri) public onlyOwner {
    baseContractURI = uri;
  }
}
