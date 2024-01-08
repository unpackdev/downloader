// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SVG721.sol";

contract Reflektioner is ERC721, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 999;
  uint256 public PRICE = 0.13 ether;
  uint256 public OPEN_BLOCK_NUMBER = 13462275;
  Counters.Counter private _tokenIdCounter;
  mapping(uint256 => bytes32) private _seeds;
  mapping(address => Counters.Counter) private _walletCounter;
  mapping(uint256 => Counters.Counter) private _hourlyCounts;
  string[15] private palettes = [
    'F08B26FBC86DBB4A403A151C81414B',
    'F08B26F1D9C3D9C3B3BB4A403A151C',
    '9dafa5F1D9C3e0c38ada391b2d2f23',
    '111111202c222f4131405742608772',
    'D9DFC62f4131608772B7CAADEDF0E9',
    '111111444444111111888888FBFCDD',
    '272643EEEEFFe3f6f52c698db2f7ef',
    '0f084b26408b3d60a7f7d6e0f2b5d4',
    '0f084b26408b3d60a781b1d5a0d2e7',
    '3d5a8098c1d9b2f7efee6c4d293241',
    'fe938ce6b89cead2ac9cafb74281a4',
    '3550706d597ab56576e56b6feaac8b',
    '335c67FBFCDDF08B269e2a2b540b0e',
    'f7d6e0f2b5d4F987C5FBAED286002d',
    '8C687FD1C2CCeff7f6f7d6e06d597a'
  ];
  string[2][3] private aspectRatios = [["1000", "1000"], ["711", "1000"], ["1000", "711"]];
  string public constant DESCRIPTION = "Generative abstract reflections of high dimensional rivers generated entirely on-chain. Reflektioner is the first step of a visual journey in a latent space of noisy reflections.";
  

  constructor() ERC721("Reflektioner", "REFL") {}


  function mint(uint256 numberOfTokens) public payable {
    require(isOpenForMint(), "Not open for minting yet!");
    require(totalSupply() < MAX_SUPPLY, "Sold out!");
    require(numberOfTokens > 0 && numberOfTokens <= 5, "You can mint between 1 and 5 tokens per transaction.");
    require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "This transaction would lead to too many tokens minted!");
    require(getCurrentPeriodCount() + numberOfTokens <= MAX_SUPPLY/3, "No more available to mint this period, please hold.");
    require(msg.value >= PRICE * numberOfTokens, "PRICE_NOT_MET");
    require(_walletCounter[msg.sender].current() + numberOfTokens <= 5, "This wallet has minted the max number!");
    

    for (uint256 i = 0; i < numberOfTokens; i++){
      uint256 tokenId = _tokenIdCounter.current();
      _safeMint(msg.sender, tokenId);

      _seeds[tokenId] = keccak256(abi.encodePacked(tokenId, msg.sender));
      _tokenIdCounter.increment();
      _hourlyCounts[block.timestamp / 8 hours].increment();
      _walletCounter[msg.sender].increment();
    }
  }

  function isOpenForMint() public view returns (bool){
    return block.number >= OPEN_BLOCK_NUMBER;
  }

  function getCurrentPeriodCount() public view returns (uint256){
    uint256 currentPeriod =  block.timestamp / 8 hours;
    return _hourlyCounts[currentPeriod].current();
  }

  function canMint(address minter) public view returns(bool){
    return ((getCurrentPeriodCount() < MAX_SUPPLY/3) && isOpenForMint() && (_tokenIdCounter.current() < MAX_SUPPLY) && (_walletCounter[minter].current() < 5));
  }

  function substring(uint256 start, uint256 end, string memory text) private pure returns (string memory) {
    bytes memory tmp = bytes(text);
    bytes memory a = new bytes(end-start);
    for(uint i=start;i<end;i++){
        a[i-start] = tmp[i];
    }
    return string(a);    
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for unminted token id");
    string memory name = string(abi.encodePacked("Reflektion #", tokenId.toString()));
    bytes32 h = _seeds[tokenId];
    
    uint256 th = 0;
    uint256 x;
    uint256[] memory p = new uint256[](64);
    uint256[2][32] memory shapes;
    for (uint256 i = 0; i < 32; i+=1) {
      p[i*2] = uint256(uint8(h[i] & 0x0f));
      p[i*2 + 1] = uint256(uint8(h[i] >> 4));
      shapes[i] = [p[i*2], th+p[i*2+1]];
      th += p[i*2+1];
    }
    string memory y;
    string[2] memory ar = aspectRatios[p[42]%3];

    string memory output = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ', ar[0] ,' ', ar[1], '" version="1.1"><defs>'));

    {
    for(uint256 i = 0; i < 4; i++){
      output = string(abi.encodePacked(output,
                                           '<linearGradient id="g', 
                                           i.toString(),
                                           '" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" style="stop-color:#',
                                           substring(i*6, (i+1)*6, palettes[p[13]%15]),
                                           '"/><stop offset="100%" style="stop-color:#', 
                                           substring((i+1)*6, (i+2)*6, palettes[p[13]%15]), 
                                           '"/></linearGradient>'));
    }
    }
    {
    output = string(abi.encodePacked(output, '<filter id="df"><feTurbulence baseFrequency="0.0',
                                        p[63]<11?'0':'', 
                                        (200 + p[63]*1100/15).toString(), 
                                        ', 0.',
                                        p[62] > 7 ? '0':'',
                                        (100 + p[62]*500/15).toString(),
                                        '" type="',
                                        p[25] > 7 ? 'turbulence': 'fractalNoise'
                                      )
                      );
    }
    {
      output = string(abi.encodePacked(output, 
        '" numOctaves="', 
        (p[61]/4 + 2).toString(), 
        '" result="t" seed="', 
        (uint256(h) % 9543129).toString(), 
        '"/><feDisplacementMap in2="t" in="SourceGraphic" scale="',
        (p[50] > 5) ? ((p[51] > 3)? "350" : "200") : ((p[51] > 4)? "130" : "180"),
        '" xChannelSelector="R"/></filter><clipPath id="c"><rect x="0" y="0" width="', 
        ar[0],
        '" height="',
        ar[1],
        '"/></clipPath></defs>'));
    }
    output = string(abi.encodePacked(output, 
      '<rect x="0" y="0" width="',
      ar[0],'" height="',
      ar[1],
      '" fill="url(#g',
      (uint256(keccak256(abi.encodePacked(p[33])))%4).toString() ,
      ')"></rect><g clip-path="url(#c)" filter="url(#df)">'));

    {
    for (uint256 i=0; i<32;i++){
      x = shapes[i][0]*500/15;
      if (p[50] > 5){
        // Circles
        y = (shapes[i][1]*1000/th).toString();
        output = string(abi.encodePacked(output,'<circle cx="', 
          (x).toString() ,
          '" cy="',
          y,
          '" r="200" fill="url(#g',
          (uint256(keccak256(abi.encodePacked(p[2*i])))%4).toString(),
          ')"/><circle cx="', 
          (500 + x).toString() ,
          '" cy="',
          y,
          '" r="200" fill="url(#g',
          (uint256(keccak256(abi.encodePacked(p[2*i + 1])))%4).toString(),
          ')"/>'));
      }
      else {
        // Strips
        y = ((shapes[i][1] - p[i*2+1])*1000/th).toString();
        bool yIsZero = keccak256(abi.encodePacked(y)) == keccak256(abi.encodePacked("0"));
        output = string(abi.encodePacked(output,'<rect x="-70" y="',
          yIsZero ? "-70" : y,
          '" width="',
          (x+70).toString(),
          '" height="',
          (p[50] < 11)? (yIsZero ? (p[i*2+1]*1000/th + 70).toString() : (p[i*2+1]*1000/th).toString()) : (x+70).toString(),
          '" fill="url(#g',
          (uint256(keccak256(abi.encodePacked(p[2*i])))%4).toString(),
          ')"/><rect x="')); 
        output=string(abi.encodePacked(output,
          x.toString() ,
          '" y="',
          yIsZero ? "-70" : y,
          '" width="',
          (1070-x).toString(),
          '" height="',
          (p[50] < 11) ? (yIsZero ? (p[i*2+1]*1000/th + 70).toString() : (p[i*2+1]*1000/th).toString()) : (1070-x).toString(),
          '" fill="url(#g',
          (uint256(keccak256(abi.encodePacked(p[2*i + 1])))%4).toString(),
          ')"/>'));
      }
    }
    }

    output = string(abi.encodePacked(output, '</g></svg>'));

    
    return SVG721.metadata(name, DESCRIPTION, output);
  }

  function reflektion(uint256 tokenId) public view returns (uint256){
    return uint256(_seeds[tokenId]) % 1234313;
  }

  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    PRICE = newPrice;
  }

  function setStartBlock(uint256 startBlock) public onlyOwner {
    OPEN_BLOCK_NUMBER = startBlock;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}