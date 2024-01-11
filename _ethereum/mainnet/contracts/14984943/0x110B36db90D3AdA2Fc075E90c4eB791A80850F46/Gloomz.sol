// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
contract Gloomz  is ERC721A , Ownable{

  address  public constant DEV_ADDRESS = 0x8C124a29116da613993d876292aAb291eEFaA808;
  address public constant MANAGING_ADDR = 0x5aFD33DdBea46B1C9E31B0EeCF3d199eDdCeA15f;
  address public constant ARTIST_ADDR = 0xA8b7575f1CCE3864254eD790BC1Cb140D87cCDb9;
  address public constant COMMUNITY_MANAGER_ADDR = 0x8d04eec8d87Bf15007B5A00c97c15ECA9850378a;
  address public constant MARKETING_ADDR = 0xA32518031ce5764418397FD4e246163a1615abff;
  address public constant SECONDARY_ARTIST_ADDR = 0x4eD626561fa31ADAC1F7DC1B7c4608b85F9376F3;
  address public constant LEGAL_ADDR = 0x9A895862583e941271BD3421F9018b275dca2728;
  address public constant PARTNERSHIP_ADDR = 0x6DE8bca209E5DAf2FB02A7B978ED312D92c5bE5f;

  uint256 public constant MINT_PRICE = 0.01 ether;
  uint256 public constant MAX_PER_TX_FREE = 3;
  uint256 public constant MAX_PER_TX_PUBLIC = 10;
  uint256 public constant SUPPLY_CAP = 5555;
  uint256 public constant AMOUNT_FREE_MINTS = 2000;
  uint256 public  DEV_MINT_RESERVE = 200;
  bool public  saleOpen = false;
  uint public DEV_MINT_MINTED = 0;

  constructor()   ERC721A("Gloomz","GLOOMZ" )  {

  }



  function mintGloom(uint256 amount)  payable public  {
    require(saleOpen== true);
    uint256 ts = totalSupply();
    require(ts<SUPPLY_CAP);
    uint256 freeMints = AMOUNT_FREE_MINTS;
    uint256 reserve = DEV_MINT_RESERVE;
    uint256 supplyCap = ts+reserve+ amount ;
    int freeMintLeft = int(AMOUNT_FREE_MINTS)-int(ts);
    require(SUPPLY_CAP>= supplyCap);
    if(ts>= AMOUNT_FREE_MINTS ){
      require(amount<=MAX_PER_TX_PUBLIC);
      require(msg.value >= amount * MINT_PRICE);
    }else {require(amount<= MAX_PER_TX_FREE);}
    if(freeMintLeft<=int(amount) && freeMintLeft > 0 ){
      require(amount<=MAX_PER_TX_FREE);
      require(msg.value >= uint256(amount-uint256(freeMintLeft) )* MINT_PRICE);
    } if(freeMintLeft>= int(amount)){
    require(amount<=MAX_PER_TX_FREE);
  }


    _safeMint(msg.sender, amount);

  }
  function changeSaleState( ) external onlyOwner{
    saleOpen= !saleOpen;
  }
  function setMetadata(string memory baseURI) external onlyOwner {
    metadataBase = baseURI;
  }
  function _baseURI() internal view override returns(string memory ){
    return metadataBase;
  }

  function reduceDevReserve(uint newReserveAmount) external onlyOwner{
    require(newReserveAmount< DEV_MINT_RESERVE,"CANT INCREASE DEV MINT RESERVE");

    DEV_MINT_RESERVE = newReserveAmount;
  }
  function devMint(uint amount) external onlyOwner{
    require(amount + DEV_MINT_MINTED <= DEV_MINT_RESERVE);
    DEV_MINT_MINTED+=amount;
    _safeMint(msg.sender,amount);
  }
  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    uint256 DEV_CUT = totalBalance / 100 * 16;
    uint256 MANAGING = totalBalance / 100 * 15;
    uint256 ARTIST = totalBalance / 100 * 15;
    uint256 COMMUNITY_MANAGER = totalBalance / 100 * 15;
    uint256 MARKETING = totalBalance / 100 * 15;
    uint256 SECONDARY_ARTIST = totalBalance / 100 * 10;
    uint256 LEGAL = totalBalance / 100 * 7;
    uint256 PARTNERSHIP = totalBalance / 100 * 7;
    payable(DEV_ADDRESS).transfer(DEV_CUT);
    payable(MANAGING_ADDR).transfer(MANAGING);
    payable(ARTIST_ADDR).transfer(ARTIST);
    payable(COMMUNITY_MANAGER_ADDR).transfer(COMMUNITY_MANAGER);
    payable(MARKETING_ADDR).transfer(MARKETING);
    payable(SECONDARY_ARTIST_ADDR).transfer(SECONDARY_ARTIST);
    payable(LEGAL_ADDR).transfer(LEGAL);
    payable(PARTNERSHIP_ADDR).transfer(PARTNERSHIP);


  }
}
