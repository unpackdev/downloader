// SPDX-License-Identifier: MIT

/*   
01100011 01110010 01111001 01110000 01110100 01101111 00100000 01100011 01110010 01101001 01101101 01101001 01101110 01100001 01101100 01110011

      ...                                                       s                
   xH88"`~ .x8X                   ..                           :8                
 :8888   .f"8888Hf    .u    .    @L           .d``            .88           u.   
:8888>  X8L  ^""`   .d88B :@8c  9888i   .dL   @8Ne.   .u     :888ooo  ...ue888b  
X8888  X888h       ="8888f8888r `Y888k:*888.  %8888:u@88N  -*8888888  888R Y888r 
88888  !88888.       4888>'88"    888E  888I   `888I  888.   8888     888R I888> 
88888   %88888       4888> '      888E  888I    888I  888I   8888     888R I888> 
88888 '> `8888>      4888>        888E  888I    888I  888I   8888     888R I888> 
`8888L %  ?888   !  .d888L .+     888E  888I  uW888L  888'  .8888Lu= u8888cJ888  
 `8888  `-*""   /   ^"8888*"     x888N><888' '*88888Nu88P   ^%888*    "*888*P"   
   "888.      :"       "Y"        "88"  888  ~ '88888F`       'Y"       'Y"      
     `""***~"`                          88F     888 ^                            
                                       98"      *8E                              
                                     ./"        '8>                              
                                    ~`           " 
      ...                          .                           .                                    ..    .x+=:.   
   xH88"`~ .x8X                   @88>                        @88>                            x .d88"    z`    ^%  
 :8888   .f"8888Hf    .u    .     %8P      ..    .     :      %8P      u.    u.                5888R        .   <k 
:8888>  X8L  ^""`   .d88B :@8c     .     .888: x888  x888.     .     x@88k u@88c.       u      '888R      .@8Ned8" 
X8888  X888h       ="8888f8888r  .@88u  ~`8888~'888X`?888f`  .@88u  ^"8888""8888"    us888u.    888R    .@^%8888"  
88888  !88888.       4888>'88"  ''888E`   X888  888X '888>  ''888E`   8888  888R  .@88 "8888"   888R   x88:  `)8b. 
88888   %88888       4888> '      888E    X888  888X '888>    888E    8888  888R  9888  9888    888R   8888N=*8888 
88888 '> `8888>      4888>        888E    X888  888X '888>    888E    8888  888R  9888  9888    888R    %8"    R88 
`8888L %  ?888   !  .d888L .+     888E    X888  888X '888>    888E    8888  888R  9888  9888    888R     @8Wou 9%  
 `8888  `-*""   /   ^"8888*"      888&   "*88%""*88" '888!`   888&   "*88*" 8888" 9888  9888   .888B . .888888P`   
   "888.      :"       "Y"        R888"    `~    "    `"`     R888"    ""   'Y"   "888*""888"  ^*888%  `   ^"F     
     `""***~"`                     ""                          ""                  ^Y"   ^Y'     "%                

01100011 01110010 01111001 01110000 01110100 01101111 00100000 01100011 01110010 01101001 01101101 01101001 01101110 01100001 01101100 01110011       
*/

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract CryptoCriminals is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdsMint;
  Counters.Counter private _tokenIdsRecruit;

  // Minting 
  uint public constant maxMintingSupply = 11111;
  uint public constant maxPresaleSupply = 3333;
  uint public constant maxRecruitingSupply = 11111;
  uint public constant reservedAmount = 100;
  uint public constant salePrice = 0.08 ether;
  uint public constant presalePrice = 0.069 ether;
  uint public reservedMintedAlready;
  uint private prs;

  // Recruiting 
  uint public constant recruitingPointThreshold = 10; 
  uint public recruitingTimeWindow = 3 days; 
  mapping (uint => uint) public lastRecruitTimeOfTokenID;
  mapping (uint => uint) public pointsOfToken;

  // Access 
  bool public presaleOpen = false;
  bool public saleOpen = false;
  bool public gangRecruitingOpen = false;
  bool public revealed = false;
  mapping(address => uint256) public whitelist;
  mapping(uint => bool) private lucky10s;

  // Metadata 
  string public baseUri = "https://cryptocriminals.mypinata.cloud/ipfs/" ;
  string public hiddenTokenURI = "https://cryptocriminals.mypinata.cloud/ipfs/QmYxJQFkr2DHKW3RGmVesHizvRR2a7ZL21BfJAzQvqXNNR";
  string public baseExtension  = ".json";
 
  constructor(uint[] memory listOf10s) ERC721("CryptoCriminals", "CC") {
    for(uint i = 0; i < listOf10s.length; i++){
      lucky10s[listOf10s[i]] = true;
    }
  }

  modifier onlyEOA() {
    require(msg.sender == tx.origin, "Only EOA");
    _;
  }

  function addToWhitelist(address[] memory addresses, uint amount) external onlyOwner {
    for(uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = amount;
    }
  }

  function mintSale(uint amount) external payable onlyEOA {
    require(saleOpen , "Sale not active");
    require(amount > 0, "wrong input amount");
    require(totalMinted() + amount <= maxMintingSupply - (reservedAmount - reservedMintedAlready), "max supply reached");
    require(msg.value == salePrice * amount, "sent incorrect price");
    _mintCC(msg.sender, amount);
  }

  function mintPresale(uint amount) external payable onlyEOA {
    require(presaleOpen , "PreSale not active");
    require(totalMinted() + amount <= maxPresaleSupply, "max supply reached");
    require(whitelist[msg.sender] >= amount, "not enough whitelist balance");
    require(msg.value == presalePrice * amount, "sent incorrect price");
    whitelist[msg.sender] -= amount;
    _mintCC(msg.sender, amount);
  }

  function mintReserved(address receiver, uint amount) external onlyOwner {
    require(totalMinted() + amount <= maxMintingSupply, "max reached");
    require(reservedMintedAlready + amount <= reservedAmount, "reserved max reached");
    reservedMintedAlready += amount;
    _mintCC(receiver, amount);
  }

  function _mintCC(address to, uint amount) private {
    for(uint i = 0; i < amount; i++){
      _tokenIdsMint.increment();
      uint _id = _tokenIdsMint.current();
      _mint(to, _id);
      uint _points = pointAssignment(_id);
      pointsOfToken[_id] = _points;
      prs += _points * _id;
    }
  }

  function _recruitCC(address to) private {
    _tokenIdsRecruit.increment();
    uint _id = _tokenIdsRecruit.current() + maxRecruitingSupply;
    uint _points = pointAssignment(_id);
    pointsOfToken[_id] = _points;
    _mint(to, _id);
    prs += _points * _id;
  }

  function recruitGangMember(uint[] memory tokenIds) external onlyEOA {
    require(gangRecruitingOpen, "recruiting not active");
    require(tokenIds.length > 0 && tokenIds.length <= 10, "wrong amount of tokenIds");
    require(totalRecruited() + 1 <= maxRecruitingSupply, "max supply recruited");
    require(tokenIDsNotDuplicated(tokenIds),"input contains duplicate tokenIDs");
    require(_tokenIDsOwnershipValid(tokenIds),"not owner of Tokens");
    require(tokenIDsPointsCanRecruit(tokenIds), "sum of tokenIDs points not enough");
    require(tokenIDsTimeCanRecruit(tokenIds),"tokenIDs not yet ready to recruit again");

    setTokensRecruitingTimer(tokenIds); 
    _recruitCC(msg.sender); 
  }

  function pointAssignment(uint tokenId) private view returns (uint){
    uint result;
    if(lucky10s[tokenId]){
      result = 10;
    }
    else {
      result = (uint(keccak256(abi.encodePacked(tokenId, prs,  block.timestamp)))) % 3 + 2;
    }
    return result;
  }

  function setTokensRecruitingTimer(uint[] memory tokenIds) private {
    for(uint i = 0; i < tokenIds.length; i++){
      lastRecruitTimeOfTokenID[tokenIds[i]] = block.timestamp;
    }
  }

  function setBaseExtension(string memory newBaseExtension) external onlyOwner {
    baseExtension = newBaseExtension;
  }

  function setBaseUri(string memory newBaseUri) external onlyOwner {
    baseUri = newBaseUri;
  }

  function setHiddenTokenURI(string memory newHiddenTokenURI) external onlyOwner {
    hiddenTokenURI = newHiddenTokenURI;
  }

  function setRecruitingTimeWindow(uint newRecruitingTimeWindow) external onlyOwner {
    recruitingTimeWindow = newRecruitingTimeWindow;
  }
  
  function switchGangRecruitingState() external onlyOwner {
    gangRecruitingOpen = !gangRecruitingOpen;
  }

  function switchPresaleState() external onlyOwner {
    presaleOpen = !presaleOpen;
  }

  function switchSaleState() external onlyOwner {
    saleOpen = !saleOpen;
  }

  function switchRevealState() external onlyOwner {
    revealed = !revealed;
  }

  // Recruiting TokenId validation
  function _tokenIDsOwnershipValid(uint[] memory tokenIds) private view returns (bool){
    for(uint i = 0; i < tokenIds.length; i++){
      if(ownerOf(tokenIds[i]) != msg.sender){
        return false;
      }
    }
    return true;
  }

  function tokenIDsPointsCanRecruit(uint[] memory tokenIds) public view returns (bool){
    uint sum;
    for(uint i = 0; i < tokenIds.length; i++){
      sum += pointsOfToken[tokenIds[i]];
    }
    if (sum >= recruitingPointThreshold){
      return true;
    } else{
      return false;
    }
  }

  function tokenIDsTimeCanRecruit(uint[] memory tokenIds) public view returns (bool){
    uint currentTime = block.timestamp;
    for(uint i = 0; i < tokenIds.length; i++){
      if(lastRecruitTimeOfTokenID[tokenIds[i]] + recruitingTimeWindow > currentTime ){
        return false;
      }
    }
    return true;
  }

  function tokenIDsNotDuplicated(uint[] memory tokenIds) public pure returns (bool){
    for(uint i = 0; i < tokenIds.length - 1; i++){
      for(uint j = i + 1; j < tokenIds.length; j++){
        if(tokenIds[i] == tokenIds[j]){
          return false;
        }
      }
    }
    return true;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory _tokenURI = "Token with that ID does not exist.";
    if (_exists(tokenId)){
      if(!revealed){
        _tokenURI = hiddenTokenURI;
      }
      else{
        _tokenURI = string(abi.encodePacked(baseUri, tokenId.toString(),  baseExtension));
      }
    }
    return _tokenURI;
  }
  
  function totalSupply() public view returns (uint){
    return _tokenIdsMint.current() + _tokenIdsRecruit.current();
  }

  function totalMinted() public view returns (uint){
    return _tokenIdsMint.current() ;
  }

  function totalRecruited() public view returns (uint){
    return _tokenIdsRecruit.current();
  }

  function getTokenIDsOfAddress(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentMintedTokenId = 1;
    uint256 ownedTokenIndex = 0;
    uint256 currentRecruitedTokenId = 11112;
    // checking minted tokens
    while (ownedTokenIndex < ownerTokenCount && currentMintedTokenId <= totalMinted()) {
      address currentTokenOwner = ownerOf(currentMintedTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentMintedTokenId;
        ownedTokenIndex++;
      }
      currentMintedTokenId++;
    }
    // checking recruited tokens
    while (ownedTokenIndex < ownerTokenCount && currentRecruitedTokenId <= totalRecruited() + maxRecruitingSupply) {
      address currentTokenOwner = ownerOf(currentRecruitedTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentRecruitedTokenId;
        ownedTokenIndex++;
      }
      currentRecruitedTokenId++;
    }
    return ownedTokenIds;
  }

  function getTokenIDsTimes(uint256[] memory usersTokenIDsArray) public view returns(uint256[] memory){
    uint resLength = usersTokenIDsArray.length;
    uint256[] memory tokenIDsTimes = new uint256[](resLength);
    for(uint i = 0 ; i < resLength; i++){
      tokenIDsTimes[i] = lastRecruitTimeOfTokenID[usersTokenIDsArray[i]];
    }
    return tokenIDsTimes;
  }

  function getTokenIDsPoints(uint256[] memory usersTokenIDsArray) public view returns(uint256[] memory){
    uint resLength = usersTokenIDsArray.length;
    uint256[] memory tokenIDsPoints = new uint256[](resLength);
    for(uint i = 0 ; i < resLength; i++){
      tokenIDsPoints[i] = pointsOfToken[usersTokenIDsArray[i]];
    }
    return tokenIDsPoints;
  }
  
  function withdraw() external onlyOwner {
    (bool success, ) = payable(0xf2E801D8CA027d5FE60aF1764796FcB65d043697).call{value: address(this).balance}("");
    require(success, "withdrawal failed");
  }
}
