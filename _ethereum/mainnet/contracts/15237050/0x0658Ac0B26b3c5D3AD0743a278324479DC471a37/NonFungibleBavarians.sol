/*

                                                                   
                                                                    .5@&Y.                                                                  
                                                                   ^B@@#&G^                                                                 
                                                                  7&@@@##&B!                                                                
                                                                 Y@@@@@#####J.                                                              
                                                               :G@@@@@@#####&P:                                                             
                                                              !#@@@@@@@######&B!                                                            
                                                             J@@@@@@@@@#########J                                                           
                                                           :P@@@@@@@@@@#########&P:                                                         
                                                          ~#@@@@@@@@@@@##########&B~                                                        
                                                         J@@@@@@@@@@@@@#############?                                                       
                                                       :P@@@@@@@@@@@@@@#############&5:                                                     
                                                      :B@@@@@@@@@@@@@@@##############&G:                                                    
                                                       7B&&&@@@@@@@@@@@###########BBBG7                                                     
                                                        ^P&####&&&@@@@@######BBBBGGBP^                                                      
                                                         .Y#########&&&#BBBBGGGGGBBY.                                                       
                                                           7#&#########BGGGGGGGGBG7                                                         
                                                            ^G&########BGGGGGGBBP~                                                          
                                                             .Y&#######BGGGGGBBY:                                                           
                                                               7#######BGGGGBB?                                                             
                                                                ~G&####BGGBBP~                                                              
                                                                 .5&###BGBB5:                                                               
                                                                   ?###BBB?                                                                 
                                                                    ~B#BG!                                                                  
                                                                     :P5:                                                                   
           .^!J5PGGGGP5J!.                                             .                                                                    
        ^?G##B5J7~^^::P@@#^                                                                                                                 
     :JB@BY~!PY?:    ^#@@&^                                                               ::.                                               
   :5@@G#J  Y@@@G  .?&@@G^                                                               7@&#~                                              
  7&@#~ :: Y@@@B::?#@&P~                                                                 5@@&^                                              
  G@&:   .P@@@B?5&&P7:                                                                   .^~^                                               
  :?7   ^B@@@@@@@#PJ!.      :!?YJ?~.JJ7.   !JJ7:    :YP!    ^7JYJ7.!YJ~    7YJ^  ^?JJ^  YG5!      .~?YY?!.?Y?^   .JJ7:   :7Y5J:   .!JPP5P5^ 
       7&@@BJ?!^::P@@&?   ~P&@#J~!#G@@@Y   G@@@#:    5@5 .?B@@P!^Y##@@@^   G@@B!PB@@@7 ~@@@#.   :Y#@@5!~GB&@@#.  !@@@5 ~5P#@@@~  ?#@B?^.B@Y 
      ?@@@5.  .^^ G@@@# .5@@@Y.   B@@@&^  .#@@@&:   .B@^~#@@#~   ~@@@@5   ?@@@@P!B@@J ^#@@@7   ?&@@G:   Y@@@@?  :#@@&YPP!Y&@@Y  7@@#:  5@P. 
     ?@@&J^?Y5J7~Y@@@&7.G@@@7    7@@@#^   J@@@@5    5@7!@@@G:   .P@@@Y   !@@@&? J@@5 :#@@&7   Y@@@5    :#@@@7  .G@@@&G! Y@@@5   ^&@@#?:~^   
     J&@#557^  :P@@@G~ 5@@@?    !&@@B:  ~G@@@@&^  :P&!:&@@#:   .P@@@J  .?&@@#~  :?J^:B@@&!  :5@@@P    :B@@&!  :G@@@#7  Y@@@Y   7BP~J#@#Y:   
     ^BB!.   ~5@@@G!  .#@@G   :Y@@@G. ~PBY&@@@Y .?#G^ ?@@@!   !B@@@? .?#@@@B^       G@@&~ ^5B&@@&:  .?#@@&~ :Y&@@@Y.  7@@@5  7GG7~~  J@@5   
    .#@~.^75#@@BJ^     5@@B~?PGP@@@Y?GB?..&@@@J?GP~   ~&@@J!JGPB@@&7YBG@@@B:       .#@@B7PBY:7@@&7!YGP&@@G7P&@@@B~    J@@@?JBG!:B@?.^P@B^   
     ~JY5PG5J!:         !J5YJ!. !Y55J~    ~Y5Y?!:      :?Y5Y?^ .?55Y7::5P5^         :?Y5Y!.   ^J55J7: ^J55Y!~Y5?.     .75P5J^  :G#PPGY~       

*/

//SPDX-License-Identifier: MIT
//Creator: Sergey Kassil / 24acht GmbH

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./GenesisNFBToken.sol";


/**
@title Non-Fungible Bavarians ERC721 Contract 
@author Sergey K. / 24acht GmbH
@notice This Contract provides all the basic functionality for the Non-Fungible Bavarians.
@notice That includes Minting, Mint-Batches, Access Control, IPFS-URI, ID-Generation, etc.
@dev Contract build on ERC721 openzepplin implementation, OZ's Pausbale for regualting mint-on/off-turning and OZ's Counters for secure token count increments.
*/
contract NonFungibleBavarians is ERC721, Pausable {
  using Counters for Counters.Counter;

  //The maximal amount of mintable tokens - constant and thus unchangeable
  uint16 constant MAX_SUPPLY = 1100;

  //Amount of Genesis NFB Owners
  uint8 constant NUM_GNFB_OWNERS = 11;

  //Secure counter for the tokens' IDs
  Counters.Counter private _currentTokenId;
  
  //Storage space for Genesis NFB owners-array deep copy
  address[NUM_GNFB_OWNERS] public genesisOwners;

  //NFB project founders' (Björn, Manuel, Chris) team wallet address
  address constant _foundersTeamWallet = 0x41A777dC5b6530583413bd9B27C85334F5541cC4;

  //Address of the GenesisNFBToken smart contract
  address public genesisTokenAddress = 0x019dCCfF6cf26Bd6dDd21C82253770841dAC7A2b;

  //Reference to deployed Genesis NFB smart contract, for accessing gNFB owners
  GenesisNFBToken private _genesisContract = GenesisNFBToken(genesisTokenAddress);

  //Initial NFB Mint price in ETH - setter avaliable for founders
  uint256 public mintPrice = 0.25 ether;

  //Inital mint batch of tokens - must be resetted once it reaches 0, by a founder, to reactivate minting. 
  uint16 public currentMintBatch = 100;

  //Restriction on how many mints are allowed per wallet
  uint8 private _mintsPerWallet = 3;

  

  /**
  @dev start token count at 1
  @dev pass nonce value when deploying
   */
  constructor() ERC721("Non-Fungible Bavarians", "NFB") {
    _currentTokenId.increment();
    genesisOwners = getGenesisOwners();
  }

  /**
  @notice Check if any address holds an NFB or a Genesis NFB
   */
  function isTokenOwner(address toBeChecked) public view returns(bool) {
    for(uint8 i = 0; i < NUM_GNFB_OWNERS; i++) {
      if(toBeChecked == genesisOwners[i]) {
        return true;
      }
    }
    return balanceOf(toBeChecked) > 0;
  }


  /**
  @notice functions with the onlyFounder modifier can be only accessed by the projects founders
  @notice founders can either access the function via their gNFB-holding wallet or via their shared multi-sig
   */
  modifier onlyFounder() {
    require(msg.sender == _foundersTeamWallet 
    || msg.sender == genesisOwners[0] 
    || msg.sender == genesisOwners[1] 
    || msg.sender == genesisOwners[2],
    "Only the tokens original founders can call this function!");
    _;
  }



  /**
  @notice functiion that provides an array of the genesis NFB owners 
  @dev a call like "gNFBOwners = _genesisContract.owners();" doesn't work, due to technical reasons
  @dev therefore the elements must be copied one by one
  */
  function getGenesisOwners() public view returns(address[11] memory) {
    address[NUM_GNFB_OWNERS] memory gNFBOwners;
    for(uint8 i = 0; i < NUM_GNFB_OWNERS; i++) {
      gNFBOwners[i] = _genesisContract.owners(i);
    }
    return gNFBOwners;
  }

  /**
  @notice New tokens can be minted with this function. The payed price gets immediately tranferred to the founders team wallet.
  @dev Only callable when the mint batch is higher than  0 (else the contract gets paused and a new batch must be set in setNewMintBatch() )
  @dev Checks for correct amount payed, performs every write ops before interacting with the caller (_mint)
   */
  function mint() external payable whenNotPaused {
    require(msg.value >= mintPrice, "Not enough ETH payed for minting!");
    require(balanceOf(msg.sender) < _mintsPerWallet, "You cannot mint more than 3 NFBs");
    
    currentMintBatch--;

    if(currentMintBatch == 0) {
      _pause();
    }

    uint256 tokenId = _currentTokenId.current();
    _currentTokenId.increment();

    (bool success,) = _foundersTeamWallet.call{value: msg.value}("");
    require(success, "Failed to receive funds"); 

    _mint(msg.sender, tokenId);
  } 

  /**
  @notice This function is to be used, when a new batch of mintable tokens shall be issued
  */
  function setNewMintBatch(uint16 newBatch, uint256 newMintPriceInWei) external onlyFounder whenPaused { 
    require(newBatch > 0, "The new batch must have a minimum value of 1");

    uint256 tokensIssued = _currentTokenId.current();
    require(tokensIssued + newBatch <= MAX_SUPPLY, "The new batch must not exceed the maximum amount of mintable tokens!");

    if(newMintPriceInWei > 0) {
      setNewMintPrice(newMintPriceInWei);
    }
    
    currentMintBatch = newBatch;
    _unpause();
  }

  /**
  @notice mint price setter - can be used anytime
   */
  function setNewMintPrice(uint256 newMintPriceInWei) public onlyFounder {
    require(newMintPriceInWei > 0, "The mint price must not be zero!");
    mintPrice = newMintPriceInWei;
  }

  function pauseMinting() external onlyFounder {
    _pause();
  }

  function unpauseMinting() external onlyFounder {
    _unpause();
  }


  /** 
  @dev define base uri, which will later be used to create the full uri
  **/
  function _baseURI() override internal view returns(string memory) {
    return "ipfs://bafybeicydjp3xkmiv6pq34wkcl637n5slhy2kchw4y4guh6jz4wh6gstfu/";
  }

  /**
  * @dev Returns an URI for a given token ID
  */
  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return string(abi.encodePacked(
        _baseURI(),
        Strings.toString(tokenId),
        ".json"
    ));
  }

}


