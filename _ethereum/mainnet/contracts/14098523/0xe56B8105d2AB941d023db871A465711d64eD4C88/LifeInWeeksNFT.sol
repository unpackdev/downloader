//      _ _  __        _                           _        
//     | (_)/ _| ___  (_)_ __   __      _____  ___| | _____ 
//     | | | |_ / _ \ | | '_ \  \ \ /\ / / _ \/ _ \ |/ / __|
//     | | |  _|  __/ | | | | |  \ V  V /  __/  __/   <\__ \
//     |_|_|_|  \___| |_|_| |_|   \_/\_/ \___|\___|_|\_\___/
//
//      by @eddietree


pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Base64.sol";

contract LifeInWeeksNFT is ERC721Tradable {

  bool public saleIsActive = true;
  bool public allowlistIsActive = true;

  uint256 public constant MAX_SUPPLY = 888;
  uint256 public constant PRICE_PER_TOKEN = 0.03 ether;

  uint constant numWeeksPerRow = 52;
  uint constant numYears = 90;
  /* 
  uint constant boxSize = 6;
  uint constant boxMargin = 3;
  uint constant paperPaddingX = 0;
  uint constant paperPaddingY = 0;
  uint constant totalWidth = paperPaddingX*2 + boxSize*(numWeeksPerRow) + boxMargin*(numWeeksPerRow-1);
  uint constant totalHeight = paperPaddingY*2 + boxSize*(numYears) + boxMargin*(numYears-1);*/

  uint constant SECONDS_PER_YEAR = 31556926;
  uint constant SECONDS_PER_DAY = 86400;
  uint constant SECONDS_PER_WEEK = 604800 ;

  uint16[MAX_SUPPLY] private _tokenData;
  mapping(address => uint8) private _allowList;

  constructor(address _proxyRegistryAddress) ERC721Tradable("Your Life In Weeks NFT", "LIFEINWEEKS", _proxyRegistryAddress) public {  
    for(uint i = 0; i < MAX_SUPPLY; i+=1) {
      _tokenData[i] = 1969;
    }
  }

  function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
          _allowList[addresses[i]] = numAllowedToMint;
      }
  }

  function allowListNumAvailableToMint(address addr) external view returns (uint8) {
      return _allowList[addr];
  }

  function uintToString(uint v) public pure returns (string memory) {
      uint maxlength = 100;
      bytes memory reversed = new bytes(maxlength);
      uint i = 0;
      while (v != 0) {
          uint remainder = v % 10;
          v = v / 10;
          reversed[i++] = bytes1(uint8(48 + remainder));
      }
      bytes memory s = new bytes(i); // i + 1 is inefficient
      for (uint j = 0; j < i; j++) {
          s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
      }
      string memory str = string(s);  // memory isn't implicitly convertible to storage
      return str;
  }

  function getSVG(uint16 birthyear) public view returns (string memory) {

    uint256 nowTime = block.timestamp; // seconds since epoch (jan 1, 1970)
    uint currentyear = 1970 + (nowTime / SECONDS_PER_YEAR);
    uint currentWeek = ((nowTime % SECONDS_PER_YEAR) / SECONDS_PER_WEEK+1)%numWeeksPerRow;

    string memory weekStr = uintToString(currentWeek);
    string memory yearsDeltaStr = uintToString(currentyear-birthyear-1);
    string memory svg = string(abi.encodePacked("<svg width='calc(465 + 40)' height='calc(807 + 40)' style='background-color:white; border: 0px solid black' xmlns='http://www.w3.org/2000/svg'><defs><pattern id='PatternStroke' x='0' y='0' width='.019230769' height='.0111111'><rect x='0.5' y='0.5' width='6' height='6' style='fill:rgb(255,255,255);stroke-width:1;stroke:rgb(0,0,0)'  shape-rendering='crispEdges'/></pattern><pattern id='PatternFilledStart' x='0' y='0' width='calc(1/52)' height='calc(1/",yearsDeltaStr,")'><rect x='0.5' y='0.5' width='6' height='6' style='fill:rgb(0,0,0);'/></pattern><pattern id='PatternFilledLineYear' x='0' y='0' width='calc(1/",weekStr,")' height='1'><rect x='0.5' y='0.5' width='6' height='6' style='fill:rgb(0,0,0);'/></pattern><pattern id='PatternCurrentWeek' x='0' y='0' width='calc(1/1)' height='1'><rect x='0.5' y='0.5' width='6' height='6'><animate attributeType='XML' attributeName='fill' values='#000;#ff0;#000;#000' dur='1.5s' repeatCount='indefinite'/></rect></pattern></defs><g transform=' translate(20 20)'><rect fill='url(#PatternStroke)' width='465' height='807'/><rect fill='url(#PatternFilledStart)' width='465' height='calc(807*",yearsDeltaStr,"/90)'/><rect fill='url(#PatternFilledLineYear)' width='calc(465*(",weekStr,"/52))' height='calc(807*1/90)' y='calc(807*",yearsDeltaStr,"/90)'/><rect fill='url(#PatternCurrentWeek)' width='calc(465*(1/52))' height='calc(807*1/90)' x='calc(465*((",weekStr," - 1)/52))' y='calc(807*",yearsDeltaStr,"/90)'/><g style='font-family:monospace;font-size:11px;' text-anchor='end' fill='#999'><text x='-4' y='7' >1</text><text x='-4' y='calc(807*10/90)'>10</text><text x='-4' y='calc(807*20/90)'>20</text><text x='-4' y='calc(807*30/90)'>30</text><text x='-4' y='calc(807*40/90)'>40</text><text x='-4' y='calc(807*50/90)'>50</text><text x='-4' y='calc(807*60/90)'>60</text><text x='-4' y='calc(807*70/90)'>70</text><text x='-4' y='calc(807*80/90)'>80</text><text x='-4' y='calc(807*90/90)'>90</text></g></g></svg>"));

    return svg;
  }

  function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
      require(tokenId >= 1 && tokenId <= MAX_SUPPLY, "Not valid token range");

      uint16 birthyear = _tokenData[tokenId-1];
      string memory svg = getSVG(birthyear);
      //string memory birthyearStr = uintToString(birthyear);

      string memory json = Base64.encode(
          bytes(string(
              abi.encodePacked(
                  '{"name": ', '"Your Life in Weeks #',uintToString(tokenId),'",',
                  '"description": "your life in weeks is an 100% on-chain dynamic display of your entire life in weeks, living on the Ethereum blockchain. every week, one block is filled and this generative SVG is dynamically updated. each row is a year (total of 90 years) and each column is a week (52 weeks per year).",',
                  //'"attributes":[{"trait_type":"Birth Year", "value":"',birthyearStr,'"}],',
                  '"image_data": "', svg, '"}' 
              )
          ))
      );
      return string(abi.encodePacked('data:application/json;base64,', json));
  }

  /**
   * @dev Mint this object with your birth year (costs 0.03 ETH)
   * @param birthyear uint The year you were born
   */
  function mint(uint16 birthyear) public payable {
    require(saleIsActive, "Sale must be active to mint tokens");

    uint256 ts = totalSupply();
    uint8 numberOfTokens = 1;
    require(ts < MAX_SUPPLY, "Purchase would exceed max tokens");
    require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

    uint256 tokenId = ts;
    _tokenData[tokenId] = birthyear;
    mintTo(msg.sender);
  }

  function mintFreeAllowlist(uint16 birthyear) public {
    require(allowlistIsActive, "Sale must be active to mint tokens");

    uint256 ts = totalSupply();
    uint8 numberOfTokens = 1;

    require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
    require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

    _allowList[msg.sender] -= numberOfTokens;

    uint256 tokenId = ts;
    _tokenData[tokenId] = birthyear;
    mintTo(msg.sender);
  }

  function reserve(uint16 birthyear) public onlyOwner {
    uint256 ts = totalSupply();
    uint numberOfTokens = 1;
    require(ts + numberOfTokens <= MAX_SUPPLY, "Mint would exceed max tokens");

    uint256 tokenId = ts;
    _tokenData[tokenId] = birthyear;
    mintTo(msg.sender);
  }

  function gift(uint16 birthyear, address receipient) public onlyOwner {
    uint256 ts = totalSupply();
    uint numberOfTokens = 1;
    require(ts + numberOfTokens <= MAX_SUPPLY, "Mint would exceed max tokens");

    uint256 tokenId = ts;
    _tokenData[tokenId] = birthyear;
    mintTo(receipient);
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function getBirthYear(uint256 _tokenId) public view returns (uint) {
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "Not valid token range");
    return _tokenData[_tokenId-1];
  }

  function setSaleState(bool newState) public onlyOwner {
      saleIsActive = newState;
  }

  function setAllowlistState(bool newState) public onlyOwner {
      allowlistIsActive = newState;
  }

  function setBirthYear(uint256 _tokenId, uint16 birthyear) public  {
    uint256 ts = totalSupply();
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY && _tokenId <= ts, "Not valid token range");

    address ownerOfToken = ownerOf(_tokenId);
    require(ownerOfToken == msg.sender, "Not the owner");

    // make sure owner owns this token
    if (ownerOfToken == msg.sender) {
      _tokenData[_tokenId-1] = birthyear;
    }
  }

}