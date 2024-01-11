// SPDX-License-Identifier: UNLICENSED

/**
* @title: Cucunci
* @author: 0xrms, 0xuntangle
* @notice: Fuits of Caper - Collection by 0xuntangle.com
*/

/**
                                                                
                                 !3                               
                                .B@!                              
                                J@@#.                             
                               ^@@@@Y                             
                               G@@@@@~                            
                              ?@@@@@@B                            
                             ^&@@@@@@@J                           
                             G@@@@@@@@@^                          
                            7@@@@@@@@@@G                          
                           :&@@@@@@@@@@@?                         
                           P@@@@@@@@@@@@&^                        
                          !@@@@@@@@@@@@@@G                        
                         .#@@@@@@@@@@@@@@@7                       
                         Y@@@@@@@@@@@@@@@@&:                      
                        ~@@@@@@@@@@@@@@@@@@P                      
                       .B@@@@@@@@@@@@@@@@@@@7                     
                       J@@@@@@@@@@@@@@@@@@@@#.                    
                      ^@@@@@@@@@@@@@@@@@@@@@@5                    
                      G@@@@@@@@@@@@@@@@@@@@@@@!                   
                     ?@@@@@@@@@@@@@@@@@@@@@@@@B                   
                    ^&@@@@@@@@@@@@@@@@@@@@@@G7:                   
                    P@@@@@@@@@@@@@@@@@@@@BJ^~? 7~                 
                   7@@@@@@@@@@@@@@@@@@#Y~^?B@~:&B                 
                  :&@@@@@@@@@@@@@@@&P!^7P@@@J G@@J                
                  5@@@@@@@@@@@@@@B?:!5&@@@@G J@@@@^               
                 !@@@@@@@@@@@@#J~~!:!P&@@@&:^@@@@@G               
                .#@@@@@@@@@&5!^?G@@&5!^7G@7.#@@@@@@?              
                Y@@@@@@@@G7^!P&@@@@@@@#Y~^ J@@@@@@@&^             
               ~@@@@@@BJ^~Y#@@@@@@@@@@@@@BJ~~Y#@@@@@G             
              .B@@@#Y~^JB@@@@@@@@@@@@@@@@@@@G7^!P&@@@7            
              Y@&P!^7G@@@@@@@@@@@@@@@@@@@@@@@@&5!^7G@@:           
             ^G?^!P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y~~YY           
             ..~5GBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBGY^.           
                                                      
*/

pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Pausable.sol";

import "./console.sol";

contract Cucunci is ERC721URIStorage, Pausable {
  address payable public owner;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint256 public totalMints = 1010;
  uint256 public specialMints = 10;
  uint256 public specialPrize = 1;
  uint256 public totalPrize = 0;
  uint256 public totalMinted;
  uint256 public totalSpecial;
  
  uint256 private seed;
  uint256 private mintSeed;

  event CucunciMinted(address sender, uint256 tokenId, uint256 seedPrize);

  event PrizeWin(address sender);

  constructor() payable ERC721 ("CUCUNCI", "CUC") {
    owner = payable(msg.sender);
    seed = (block.timestamp + block.difficulty) % 100;
    console.log("CUCUNCI, Fruits of Caper contract by 0xuntangle. SEED: ", seed);
    _tokenIds.increment();
    pause();
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function price() public pure returns(uint) {
	  return 3 * 10**16;  
  }

  function mintCucunci( string memory tokenUri) public payable whenNotPaused returns (uint256) {

    uint256 seedPrize = getMintSeed();

    if (seedPrize == seed) {
      totalPrize += 1;      
    }

    totalMinted += 1;

    uint256 newItemId = _tokenIds.current();

    require(totalMinted <= totalMints, "Limit of the supply mints reached!!! :( ");

    uint256 _price = this.price();
    require(msg.value >= _price, "Not enough Ethers paid");

    //SpecialMint
    if (seedPrize == seed && specialPrize == 0 && specialMints >= 1 && totalSpecial <= 10) {
      specialMints -= 1;
      totalSpecial += 1;

      //Mint special
      console.log("<<<!!!SPECIAL - MINT!!!>>>");

      require(specialMints >= 1);

      console.log("<<<!!! %s won a Prize ;))) !!!>>>", msg.sender);

      emit PrizeWin(msg.sender);      
        
      uint256 winnerAmount = 0.06 ether;
          
      require(
        winnerAmount <= address(this).balance,
        "Trying to withdraw more prize than the contract has."
      );

      (bool success, ) = (msg.sender).call{value: winnerAmount}("Ok");
      
      require(success, "Failed to withdraw prize from contract.");

    }

    console.log(tokenUri);
    
    _safeMint(msg.sender, newItemId);

    _setTokenURI(newItemId, tokenUri);

    console.log("A CUCUNCI NFT w/ ID %s has been minted to %s", newItemId, msg.sender);

    _tokenIds.increment();

    emit CucunciMinted(msg.sender, newItemId, seedPrize);

    console.log("Random # generated: %d", seedPrize);

    //>>>PRIZE!!!
    if (specialPrize >= 1 && seedPrize == seed) {
      //totalPrize += 1;

      require(specialPrize >= 1);

      console.log("<<<!!! %s won the Lottery Prize ;))) !!!>>>", msg.sender);

      emit PrizeWin(msg.sender);

      specialPrize -= 1;      
        
      uint256 prizeAmount = 0.3 ether;
          
      require(
        prizeAmount <= address(this).balance,
        "Trying to withdraw more prize than the contract has."
      );

      (bool success, ) = (msg.sender).call{value: prizeAmount}("Ok");
      
      require(success, "Failed to withdraw prize from contract.");
    }

    //return newItemId;
    return seedPrize;
  }

  function getTotalMinted() public view returns (uint256) {
    console.log("We have %d n# Cucunci's total minted!", totalMinted);
    return totalMinted;
  }

  function getTotalPrize() public view returns (uint256) {
    console.log("We have n# %d times the lottery prize came out!", totalPrize);
    return totalPrize;
  }

  function getTotalSpecial() public view returns (uint256) {    
    console.log("Second's Prize left: ", specialMints);
    return specialMints;
  }

  function getLotterySeed() public view returns (uint256) {    
    console.log("Lottery SEED is: ", seed);
    return seed;
  }

  function getMintSeed() public payable returns (uint256) {   
    mintSeed = (block.difficulty + block.timestamp ) % 100; 
    console.log("Mint SEED is: ", mintSeed);
    return mintSeed;
  }

  function getTotalSpecialPrize() public view returns (uint256) {    
    console.log("Special First Lottery Prize left: ", specialPrize);
    return specialPrize;
  }

  function mintUntangleEdition( string memory tokenUri ) public onlyOwner returns (uint256) {
    require(isOwner(), "You can not mint the owner edition");

    uint256 newItemId = _tokenIds.current();

    totalMinted += 1;

    _safeMint(msg.sender, newItemId);

    _setTokenURI(newItemId, tokenUri);

    console.log("A CUCUNCI UNTANGLE LTD NFT w/ ID %s has been minted to %s", newItemId, msg.sender);

    _tokenIds.increment();

    emit CucunciMinted(msg.sender, newItemId, newItemId);
    return newItemId;
  }

  function mintPromoEdition( string memory tokenUri ) public onlyOwner returns (uint256) {
    require(isOwner(), "You can not mint the promo edition");

    uint256 newItemId = _tokenIds.current();

    totalMinted += 1;

    _safeMint(msg.sender, newItemId);

    _setTokenURI(newItemId, tokenUri);

    console.log("A Promo Edition NFT w/ ID %s has been minted to %s", newItemId, msg.sender);

    _tokenIds.increment();

    emit CucunciMinted(msg.sender, newItemId, newItemId);
    return newItemId;
  }

  function fixURI( uint256 itemId, string memory tokenUri ) public onlyOwner returns (uint256) {
    _setTokenURI(itemId, tokenUri);
    return itemId;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function withdraw() public onlyOwner {
	  uint amount = address(this).balance;
	
	  (bool success, ) = msg.sender.call{value: amount}("");
	  require(success, "Failed to withdraw Balance");
  }

  function deposit() public payable {}

}
