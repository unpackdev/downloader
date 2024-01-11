/*
 _   _ _  __ _      __          __   _ _
| \ | (_)/ _| |     \ \        / /  | | |
|  \| |_| |_| |_ _   \ \  /\  / /_ _| | |___
| . ` | |  _| __| | | \ \/  \/ / _` | | / __|
| |\  | | | | |_| |_| |\  /\  / (_| | | \__ \
|_| \_|_|_|  \__|\__, | \/  \/ \__,_|_|_|___/
          __/ |
         |___/

An NFT project by vrypan.eth.

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Base64.sol";
import "./ERC721WithShuffledIDs.sol";
import "./Metadata.sol";
import "./Whitelist.sol";


contract NiftyWalls is Ownable, ERC721WithShuffledIDs {

  uint256 private    _price = 0.05 ether;
  address public     metadata;
  address public     whitelist;
  uint256 public     minPrice = 0.01 ether; // create a setter
  uint256 public     mintsPerDay;
  uint256 public     mintPeriodStart = 0;
  uint256 public     mintedToday = 0;
  bool public        paused = false;

  constructor(
    address _metadata,
    uint256 _tokenCount,
    uint256 _mintsPerDay,
    uint _initialMint
  )
  ERC721WithShuffledIDs("NiftyWalls", "WALLS", uint16(_tokenCount))
  {
    metadata = _metadata;
    mintsPerDay = _mintsPerDay;
    for (uint i = 0; i<_initialMint; i++) {
      _safeMint(msg.sender);
    }
    mintPeriodStart = block.timestamp;
  }

  receive() external payable {}

  function updatePeriod() private {
    // If more than a day since minting period started.
    if ( (block.timestamp - mintPeriodStart) / (24 hours) != 0) {
      _price = price();
      mintPeriodStart = block.timestamp;
      mintedToday = 0;
    }
  }

  function _newPrice() private view returns (uint256) {
    uint256 newPrice = (mintedToday == mintsPerDay) ? _price+(_price/10) : _price;
    newPrice = (mintedToday < 3) ? _price-(_price/10) : newPrice;
    return (newPrice > minPrice) ? newPrice : minPrice;
  }

  function price() public view returns (uint256) {
    if ( (block.timestamp - mintPeriodStart) / (24 hours) == 0) {
      return _price;
    } else {
      return _newPrice();
    }
  }

  function _mint() private {
    require(!paused, "Contract is paused.");
    if ( (block.timestamp - mintPeriodStart) / (24 hours) == 0) {
      require(mintedToday < mintsPerDay, "Maximum limit of mints per period reached.");
      mintedToday += 1;
    } else {
      _price = _newPrice();
      mintPeriodStart = block.timestamp;
      mintedToday = 1;
    }
    _safeMint(msg.sender);
  }

  function mint() public payable {
    require(msg.value >= price(), "Pay up, fren.");
    _mint();
  }

  function mintAsFriend(address _contract) public {
    Whitelist wl = Whitelist(whitelist); // make it global?
    wl.update(_contract, msg.sender);
    _mint();
  }

  function tokenURI(uint256 tokenId) public view override(ERC721)returns (string memory) {
    require(_exists(tokenId), "NiftyWalls: URI query for nonexistent token");
    Metadata meta = Metadata(metadata);
    string memory json = meta.idToJson(tokenId);
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
  }

  function setMetadataContract(address _metadata) public onlyOwner {
    metadata = _metadata;
  }

  function setWhitelistContract(address _whitelist) public onlyOwner {
    whitelist = _whitelist;
  }

  // owner methods
  function setPrice(uint256 newPrice) public onlyOwner {
    _price = newPrice;
  }

  function setMinPrice(uint256 _minPrice) public onlyOwner {
    minPrice = _minPrice;
    if (_price < minPrice) {
      _price = minPrice;
    }
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdraw20(address _contract, address _to, uint256 _amount) public onlyOwner {
    IERC20(_contract).transfer(_to, _amount);
  }

  function withdraw721(address _contract, address _to, uint256 _id) public onlyOwner {
    IERC721(_contract).transferFrom(address(this), _to, _id);
  }

  function pause() public onlyOwner {
    paused = !paused;
  }

  /* Only on testnets
  function shutdown() public onlyOwner {
    selfdestruct(payable(owner()));
  }
  */
}