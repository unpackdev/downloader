// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LuckyLeprechaun is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 7777;
  uint256 public maxMintAmount = 20;
  uint public last_rand = 0;
  bool public paused = true;
  bool public revealed = false;
  string public notRevealedUri;
 
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(msg.value >= cost * _mintAmount);

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
      if(totalSupply() == 50){
      payout50();
      } else if (totalSupply() == 200){
        payout200();
      } else if (totalSupply() == 500){
        payout500();
      } else if (totalSupply() == 1000){
        payout1000();
      } else if (totalSupply() == 2000){
        payout2000();
      } else if (totalSupply() == 2500){
        payout2500();
      } else if (totalSupply() == 3000){
        payout3000();
      } else if (totalSupply() == 4000){
        payout4000();
      } else if (totalSupply() == 5000){
        payout5000();
      } else if (totalSupply() == 6000){
        payout6000();
      } else if (totalSupply() == 7000){
        payout7000();
      }
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
        return notRevealedUri;
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

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

function _randModulus(uint mod) internal returns(uint) {
  address last_hash;
  if(totalSupply() == 0){
    last_hash = 0x0000000000000000000000000000000000000000;
  } else {
    last_hash = ownerOf(totalSupply());
  }
  uint rand = uint(keccak256(abi.encodePacked(
      block.timestamp, 
      block.difficulty, 
      msg.sender,
      totalSupply(),
      last_hash,
      last_rand
      )
  )) % mod;
  last_rand = rand;
  return rand;
}

//---------------------------------------------------------Pay out functions --------------------------------------------------------
  /*
  ---------------------------------------------------------Pay out 1eth to winner---------------------------------------------------- 
  */
  function payout50() public payable onlyOwner {
    require(totalSupply() >= 50);
    uint rand = _randModulus(50);
    address winnerAdd = ownerOf(rand);
    (bool hs, ) = payable(winnerAdd).call{value: 1 ether}("");
    require(hs);
  }

  /*
  ----------------------------------------------------------Pay out 5eth to winner-----------------------------------------------------
  */
  function payout200() public payable onlyOwner{
    require(totalSupply() >= 200);
    uint rand = _randModulus(200);
    address winnerAdd = ownerOf(rand);
    (bool hs, ) = payable(winnerAdd).call{value: 5 ether}("");
    require(hs);
  }

    function payout500() public payable onlyOwner{
      require(totalSupply() >= 500);
      uint rand = _randModulus(500);
      address winnerAdd = ownerOf(rand);
      (bool hs, ) = payable(winnerAdd).call{value: 5 ether}("");
      require(hs);
  }

    function payout1000() public payable onlyOwner{
      require(totalSupply() >= 1000);
      uint rand = _randModulus(1000);
      address winnerAdd = ownerOf(rand);
      (bool hs, ) = payable(winnerAdd).call{value: 5 ether}("");
      require(hs);
  }

    function payout2000() public payable onlyOwner{
      require(totalSupply() >= 2000);
      uint rand = _randModulus(2000);
      address winnerAdd = ownerOf(rand);
      (bool hs, ) = payable(winnerAdd).call{value: 5 ether}("");
      require(hs);
  }

    function payout3000() public payable onlyOwner{
      require(totalSupply() >= 3000);
      uint rand = _randModulus(3000);
      address winnerAdd = ownerOf(rand);
      (bool hs, ) = payable(winnerAdd).call{value: 5 ether}("");
      require(hs);
  }

    function payout4000() public payable onlyOwner{
      require(totalSupply() >= 4000);
      uint rand = _randModulus(4000);
      address winnerAdd = ownerOf(rand);
      (bool hs, ) = payable(winnerAdd).call{value: 5 ether}("");
      require(hs);
  }

    function payout6000() public payable onlyOwner{
      require(totalSupply() >= 6000);
      uint rand = _randModulus(6000);
      address winnerAdd = ownerOf(rand);
      (bool hs, ) = payable(winnerAdd).call{value: 5 ether}("");
      require(hs);
  }

    function payout7000() public payable onlyOwner{
      require(totalSupply() >= 7000);
      uint rand = _randModulus(7000);
      address winnerAdd = ownerOf(rand);
      (bool hs, ) = payable(winnerAdd).call{value: 5 ether}("");
      require(hs);
  }

  /*
  ------------------------------------------------------------Pay out 10eth to winner--------------------------------------------- 
  */
  function payout2500() public payable onlyOwner {
    require(totalSupply() >= 2500);
    uint rand = _randModulus(2500);
    address winnerAdd = ownerOf(rand);
    (bool hs, ) = payable(winnerAdd).call{value: 10 ether}("");
    require(hs);
  }

    function payout5000() public payable onlyOwner {
    require(totalSupply() >= 5000);
    uint rand = _randModulus(5000);
    address winnerAdd = ownerOf(rand);
    (bool hs, ) = payable(winnerAdd).call{value: 10 ether}("");
    require(hs);
  }

//--------------------------------------------Pay out function for sell out--------------------------------------------------------------------------
/*
These functions will be triggered manually at the end of sale or upon sellout
Because of lack of delay function a script off-chain has been written to calls these with a delay to presever the randomness of the selections
*/
function payoutGrandPrize() public payable onlyOwner{
  require(totalSupply() == 7777);
  uint rand = _randModulus(7777);
  address winnerAdd = ownerOf(rand); 
  (bool hs, ) = payable(winnerAdd).call{value: 100 ether}("");
  require(hs);
}

function payout2ethSoldOut() public payable onlyOwner{
  require(totalSupply() == 7777);
  uint rand = _randModulus(7777);
  address winnerAdd = ownerOf(rand); 
  (bool hs, ) = payable(winnerAdd).call{value: 2 ether}("");
  require(hs);
}

function payout1ethSoldOut() public payable onlyOwner{
  require(totalSupply() == 7777);
  uint rand = _randModulus(7777);
  address winnerAdd = ownerOf(rand); 
  (bool hs, ) = payable(winnerAdd).call{value: 1 ether}("");
  require(hs);
} 



}
