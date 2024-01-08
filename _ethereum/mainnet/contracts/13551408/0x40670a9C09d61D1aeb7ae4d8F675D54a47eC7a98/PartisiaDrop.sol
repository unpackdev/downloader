// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//    PPPPPPPPPPPPPPPPP                                               tttt            iiii                     iiii                       //
//    P::::::::::::::::P                                           ttt:::t           i::::i                   i::::i                      //
//    P::::::PPPPPP:::::P                                          t:::::t            iiii                     iiii                       //
//    PP:::::P     P:::::P                                         t:::::t                                                                //
//      P::::P     P:::::Paaaaaaaaaaaaa  rrrrr   rrrrrrrrr   ttttttt:::::ttttttt    iiiiiii     ssssssssss   iiiiiii   aaaaaaaaaaaaa      //
//      P::::P     P:::::Pa::::::::::::a r::::rrr:::::::::r  t:::::::::::::::::t    i:::::i   ss::::::::::s  i:::::i   a::::::::::::a     //
//      P::::PPPPPP:::::P aaaaaaaaa:::::ar:::::::::::::::::r t:::::::::::::::::t     i::::i ss:::::::::::::s  i::::i   aaaaaaaaa:::::a    //
//      P:::::::::::::PP           a::::arr::::::rrrrr::::::rtttttt:::::::tttttt     i::::i s::::::ssss:::::s i::::i            a::::a    //
//      P::::PPPPPPPPP      aaaaaaa:::::a r:::::r     r:::::r      t:::::t           i::::i  s:::::s  ssssss  i::::i     aaaaaaa:::::a    //
//      P::::P            aa::::::::::::a r:::::r     rrrrrrr      t:::::t           i::::i    s::::::s       i::::i   aa::::::::::::a    //
//      P::::P           a::::aaaa::::::a r:::::r                  t:::::t           i::::i       s::::::s    i::::i  a::::aaaa::::::a    //
//      P::::P          a::::a    a:::::a r:::::r                  t:::::t    tttttt i::::i ssssss   s:::::s  i::::i a::::a    a:::::a    //
//    PP::::::PP        a::::a    a:::::a r:::::r                  t::::::tttt:::::ti::::::is:::::ssss::::::si::::::ia::::a    a:::::a    //
//    P::::::::P        a:::::aaaa::::::a r:::::r                  tt::::::::::::::ti::::::is::::::::::::::s i::::::ia:::::aaaa::::::a    //
//    P::::::::P         a::::::::::aa:::ar:::::r                    tt:::::::::::tti::::::i s:::::::::::ss  i::::::i a::::::::::aa:::a   //
//    PPPPPPPPPP          aaaaaaaaaa  aaaarrrrrrr                      ttttttttttt  iiiiiiii  sssssssssss    iiiiiiii  aaaaaaaaaa  aaaa   //
//                                                                                                                                        //
//    /$$$$$$$  /$$                     /$$                 /$$                 /$$                                                       //
//   | $$__  $$| $$                    | $$                | $$                |__/                                                       //
//   | $$  \ $$| $$  /$$$$$$   /$$$$$$$| $$   /$$  /$$$$$$$| $$$$$$$   /$$$$$$  /$$ /$$$$$$$                                              //
//   | $$$$$$$ | $$ /$$__  $$ /$$_____/| $$  /$$/ /$$_____/| $$__  $$ |____  $$| $$| $$__  $$                                             //
//   | $$__  $$| $$| $$  \ $$| $$      | $$$$$$/ | $$      | $$  \ $$  /$$$$$$$| $$| $$  \ $$                                             //
//   | $$  \ $$| $$| $$  | $$| $$      | $$_  $$ | $$      | $$  | $$ /$$__  $$| $$| $$  | $$                                             //
//   | $$$$$$$/| $$|  $$$$$$/|  $$$$$$$| $$ \  $$|  $$$$$$$| $$  | $$|  $$$$$$$| $$| $$  | $$                                             //
//   |_______/ |__/ \______/  \_______/|__/  \__/ \_______/|__/  |__/ \_______/|__/|__/  |__/                                             //
//                                                                                                                                        //                                 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Partisia Blockchain's 1st Official NFT

import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract PartisiaDrop001 is ERC721URIStorage, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint16 public constant maxSupply = 1111;
  uint public constant maxTotalMints = 20; // This is the total mints limited per address
  uint256 public dropStartsAt;
  uint256 public dropEndsAt;
  uint256 public nftUnitPrice = 2.5 ether;
  bool public paused = false;

  string private _baseURIextended;
  address private constant withdrawTo = 0x5d0b575479ca01D2Ae0c6F7d5db8b7c1aC8f589E;

  mapping(address => uint) _addressMinted;
  mapping(address => bool) _whitelist;
  mapping(address => bool) public whitelist;

  constructor() ERC721("Partisia", "PARTISIA") { }

  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      (bool sent, bytes memory data) = withdrawTo.call{value: balance}("");
      require(sent, "Failed to send Ether");
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      _baseURIextended = baseURI_;
  }

  function setWhitelistAndTime(
      address[] memory addresses,
      uint256 timeStart,
      uint256 timeEnd
  ) external onlyOwner {
      for (uint16 i = 0; i < addresses.length; i++) {
        whitelist[addresses[i]] = true;
      }
      dropStartsAt = timeStart;
      dropEndsAt = timeEnd;
  }

  function addToWhitelist(address[] memory addresses) external onlyOwner{
    for (uint16 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = true;
    }
  }

  function setDropTime(uint256 timeStart, uint256 timeEnd) external onlyOwner {
    dropStartsAt = timeStart;
    dropEndsAt = timeEnd;
  }

  function setMintPrice(uint256 price) external onlyOwner {
    nftUnitPrice = price;
  }

  function togglePaused() external onlyOwner {
    paused = !paused;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseURIextended;
  }

  function totalSupply() public view virtual returns (uint256) {
      return _tokenIds.current();
  }

  function getMintAmount() public view virtual returns (uint256) {
      return nftUnitPrice;
  }

  function getBaseUri() public view virtual returns (string memory) {
      return _baseURIextended;
  }

  function getAuctionTime() public view virtual returns (uint256[2] memory) {
      return [dropStartsAt, dropEndsAt];
  }

  function hasMinted(address addr) public view returns(uint) {
    return _addressMinted[addr];
  }

  function numRemaining(address addr) public view returns(uint) {
    return maxTotalMints - _addressMinted[addr];
  }

  function mint(uint numberOfTokens) external payable {
    require(!paused, "The contract is currently paused");
    require((_addressMinted[msg.sender] + numberOfTokens) <= maxTotalMints , "This exceeds the max mint limit");
    require(_tokenIds.current().add(numberOfTokens) <= maxSupply, "Purchase would exceed total supply");
    require(nftUnitPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
    require(block.timestamp >= dropStartsAt , "Invalid block start time");
    require(block.timestamp <= dropEndsAt, "Invalid block end time");
    require(whitelist[msg.sender], "Address not whitelisted");

    for(uint i=0; i < numberOfTokens; i++) {
      _tokenIds.increment();
      uint256 _idx = _tokenIds.current();
      _mint(msg.sender, _idx);
      _setTokenURI(_idx, Strings.toString(_idx));
    }

    _addressMinted[msg.sender] = _addressMinted[msg.sender] + numberOfTokens;
  }
}