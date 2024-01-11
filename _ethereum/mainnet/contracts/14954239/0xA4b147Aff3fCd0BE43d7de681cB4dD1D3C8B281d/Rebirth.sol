// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*                                                                     Rebirth
Afterlife.garden                                                                                                                                  2022
                          7B@@@@&P:                                                                                .5&@@@@#?.                         
                        J&@@@@@@@@@?                     .!YPG5J7:                  .!YPGP57:                     ~@@@@@@@@@@5.                       
                      7@@@@@@@@@@@@@P                  ^B@@@@@@@@@&^              :#@@@@@@@@@#~                  J@@@@@@@@@@@@@J                      
                    .B@@@@@@@@&&@@@@@&~               J@@@@@@@@@@@@@              &@@@@@@@@@@@@5               :#@@@@@&&@@@@@@@@&:                    
                   !@@@@@@@&7.   ~G@@@@&7.           7@@@@@@@@@@@@@@.             &@@@@@@@@@@@@@Y            !#@@@@B!.  .!#@@@@@@@J                   
                  P@@@@@@&!         ~G&@@@#7.        &@@@@@@@@@@@@@Y              !@@@@@@@@@@@@@@.       .!B@@@@G!.        ^&@@@@@@B                  
                 #@@@@@@5              .~Y#@@#?.     @@@@@@@@@@@@&~                ^&@@@@@@@@@@@@:    .7B@@&P!.              J@@@@@@&.                
               .&@@@@@@^            .^!?Y5PB&@@@&5^  &@@@@@@@@@@Y                    7@@@@@@@@@@@  ^Y#@@@&BP5Y?!^.            :&@@@@@@^               
              :@@@@@@#.         .!G&@@@@@@@@@@@@@@@@BB@@@@@@@@&:                      .#@@@@@@@@BG@@@@@@@@@@@@@@@@&G7.          G@@@@@@!              
             ^@@@@@@G         :G@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@.                         @@@@@@@&@@@@@@@@@@@@@@@@@@@@@@B^         Y@@@@@@!             
            ^@@@@@@Y        .G@@@@@@@@&G5?77JPB@@@@@@@@@@@@@@@J                        !@@@@@@@@@@@@@@@#PJ77?YG&@@@@@@@@#.        7@@@@@@7            
           ^@@@@@@?        ^@@@@@@@#7.          :Y@@@@@@@&JB@@@?                      !@@@#?&@@@@@@@P^          .!B@@@@@@@!        !@@@@@@7           
          :@@@@@@?        :@@@@@@@~                5@@@@@@& .Y&@G                    Y@@P: #@@@@@@G.               ^&@@@@@@!        !@@@@@@!          
         .@@@@@@J         &@@@@@@.                  ?@@@@@@P   ^GB:                .GB~   ?@@@@@@5                   &@@@@@@         !@@@@@@^         
        .&@@@@@Y         :@@@@@@7                    #@@@@@@      :                :.     &@@@@@&                    ^@@@@@@~         7@@@@@@:        
        #@@@@@G          ~@@@@@@^                    G@@@@@@.                             @@@@@@&                    .@@@@@@!          Y@@@@@@.       
       G@@@@@#           .@@@@@@P                   .@@@@@@&                              B@@@@@@.                   J@@@@@@:           G@@@@@#       
      J@@@@@@.            P@@@@@@J                  #@@@@@@?                              ^@@@@@@&.                 !@@@@@@#             &@@@@@P      
     ^@@@@@@^              #@@@@@@B:              7@@@@@@@P                                J@@@@@@@?              .G@@@@@@&.             .@@@@@@7     
     &@@@@@J                P@@@@@@@&J^.      .!P@@@@@@@@J                                  !@@@@@@@@G!:      .^?#@@@@@@@B                !@@@@@@.    
    G@@@@@#                  ^#@@@@@@@@@@&&&&@@@@@@@@@@G.                                    .P@@@@@@@@@@&&&&&@@@@@@@@@&!                  G@@@@@#    
   !@@@@@@:                    ^P&@@@@@@@@@@@@@@@@@@&Y.                                        .J&@@@@@@@@@@@@@@@@@@@G~                    .@@@@@@J   
   @@@@@@P                        :?G&@@@@@@@@@&#P7:            .~J5P5~        ^5P5J!.            .!P#&@@@@@@@@@&GJ^                        ?@@@@@@.  
  P@@@@@@.                             ..::::..               .B@@@@@@B        P@@@@@@#.                .::::..                              &@@@@@B  
 .@@@@@@5                                                     5@@@@@@5          J@@@@@@B                                                     7@@@@@@^ 
 G@@@@@@:                                                     .#@@#?.            .7B@@&^                                                     .@@@@@@# 
.@@@@@@&                                                                                                                                      B@@@@@@^
J@@@@@@G                                          .:^7J555J?!:.                        .:~?J555Y7~.                                           Y@@@@@@G
#@@@@@@B                                    .~?5B&@@@@@@@&#BBBBGY^                  :JGBBBB#&@@@@@@@&#PJ~:                                    5@@@@@@@
@@@@@@@@:                            .^!YG&@@@@@@@@@#Y^.        :7?                ?7:        .^JB@@@@@@@@@&B57^.                            .@@@@@@@@
@@@@@@@@@Y.                   .^!YG#&@@@@@@@@@@@&5~.                                               ^Y&@@@@@@@@@@@@&GY7^.                   .?@@@@@@@@@
#@@@@@@@@@@&P?!~::::^~!?YPB#&@@@@@@@@@@@@@@@@#?:                                                      .7B@@@@@@@@@@@@@@@@&#BPY?!~^::::^!?P#@@@@@@@@@@@
.B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G!.                                                             ~P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:
  ~#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y^                                                                    :?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7  
    .JB@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~.                                                                          .~5#@@@@@@@@@@@@@@@@@@@@@@@@@@@#J:    
        :!JG#&&@@@@@@@@@@@&&BGY7^.                                                                                  .:!JPB#&@@@@@@@@@@@@&#GY!:     
Luna Ikuta                                                                                                                                    Teknique
                                                               Welcome to The Afterlife                                                            */

import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Rebirth is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenCounter;

  address private constant REMEMBER_ME = 0xCCB9D89e0F77Df3618EEC9f6BF899Be3B5561A89;
  uint256 public constant FLOWER_PRICE_REGULAR = 0.25 ether;
  uint256 public constant FLOWER_PRICE_REMEMBER_ME_HOLDER = 0.025 ether;
  uint256 public constant BETTA_MOONLIGHT_PRICE = 0.035 ether;
  
  address public luna;
  address public teknique;

  bool public isFlowerMintActive;
  bool public isBettaMintActive;
  bool public isMoonlightMintActive;
  bool public areMintsAndURIsLocked;
  bool public revealOneHappened;
  bool public revealTwoHappened;
  bool public revealThreeHappened;
  bool public revealFourHappened;
  bool public isSpiritTalismanClaimed; // 1/1
  uint256 public numPlatinumTalismansClaimed; // 1/10
  uint256 public numGoldTalismansClaimed; // 1/15
  uint256 public numSilverTalismansClaimed; // 1/20
  uint256 public numBronzeTalismansClaimed; // 1/25
  mapping (uint256 => bool) private _goldsUsedToClaimTriumph;
  
  string private _baseURIExtended;
  string private _flowerOneTokenURI = "1"; 
  string private _flowerTwoTokenURI = "2";
  string private _flowerThreeTokenURI = "3";
  string private _flowerFourTokenURI = "4";
  string private _flowerFiveTokenURI = "5";
  string private _bronzeBouquetOneTokenURI = "6";
  string private _bronzeBouquetTwoTokenURI = "7";
  string private _bronzeBouquetThreeTokenURI = "8";
  string private _bronzeTalismanTokenURI = "9";
  string private _bettaTokenURI = "10";
  string private _flowerOneBettaTokenURI = "11";
  string private _flowerTwoBettaTokenURI = "12";
  string private _flowerThreeBettaTokenURI = "13";
  string private _flowerFourBettaTokenURI = "14";
  string private _flowerFiveBettaTokenURI = "15";
  string private _silverBouquetOneTokenURI = "16";
  string private _silverBouquetTwoTokenURI = "17";
  string private _silverBouquetThreeTokenURI = "18";
  string private _silverTalismanTokenURI = "19";
  string private _moonlightTokenURI = "20";
  string private _flowerOneEclipsedTokenURI = "21";
  string private _flowerTwoEclipsedTokenURI = "22";
  string private _flowerThreeEclipsedTokenURI = "23";
  string private _flowerFourEclipsedTokenURI = "24";
  string private _flowerFiveEclipsedTokenURI = "25";
  string private _goldBouquetTokenURI = "26";
  string private _goldTalismanTokenURI = "27";
  string private _triumphTokenURI = "28";
  string private _triumphBettaTokenURI = "29";
  string private _triumphEclipsedTokenURI = "30";
  string private _flowerOneBettaEclipsedTokenURI = "31";
  string private _flowerTwoBettaEclipsedTokenURI = "32";
  string private _flowerThreeBettaEclipsedTokenURI = "33";
  string private _flowerFourBettaEclipsedTokenURI = "34";
  string private _flowerFiveBettaEclipsedTokenURI = "35";
  string private _triumphBettaEclipsedTokenURI = "36";
  string private _platinumBouquetTokenURI = "37";
  string private _stoneTalismanTokenURI = "38";
  string private _platinumTalismanTokenURI = "39";
  string private _spiritTalismanTokenURI  = "40";

  constructor(address _luna, address _teknique) ERC721("Rebirth", "REBIRTH") {
    luna = _luna;
    teknique = _teknique;
  }
 
  // * * * * * * * * * * * * * * * * * * * * * * MINTING * * * * * * * * * * * * * * * * * * * * * *
  function mintFlower(uint256 numberOfTokens)
    external
    payable
    nonReentrant
  {
    require(isFlowerMintActive && numberOfTokens > 0, "MF1");
    IERC721 rememberMe = IERC721(REMEMBER_ME);
    uint256 rememberMeBalance = rememberMe.balanceOf(msg.sender);
    uint256 numCollectorsSeedsRedeemable = rememberMeBalance * 5;
    if (rememberMeBalance > 0 && balanceOf(msg.sender) < numCollectorsSeedsRedeemable) {
      require(FLOWER_PRICE_REMEMBER_ME_HOLDER * numberOfTokens <= msg.value && 
        balanceOf(msg.sender) + numberOfTokens <= numCollectorsSeedsRedeemable, "MF2");
    } else {
      require(FLOWER_PRICE_REGULAR * numberOfTokens <= msg.value, "MF3");
    }

    uint256 tokenId;
    uint256 nonce;
    uint256 randomNum;
    string memory _newTokenURI;
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _newTokenURI = _flowerFiveTokenURI;
      nonce = (i + 7) % 13;
      randomNum = random(nonce);
      if(randomNum < 200) {
        _newTokenURI = _flowerOneTokenURI;
      } else if (randomNum < (400) ) {
        _newTokenURI = _flowerTwoTokenURI;
      } else if (randomNum < (600) ) {
        _newTokenURI = _flowerThreeTokenURI;
      } else if (randomNum < (800) ) {
        _newTokenURI = _flowerFourTokenURI;
      }
      tokenId = nextTokenId();
      _safeMint(msg.sender, tokenId);
      _setTokenURI(tokenId, _newTokenURI);
    }
  }
  
  function mintMoonlight(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    isCorrectPayment(BETTA_MOONLIGHT_PRICE, numberOfTokens)
  {
    require(isMoonlightMintActive && numberOfTokens > 0, "MM");
    uint256 tokenId;
    for (uint256 i = 0; i < numberOfTokens; i++) {
     tokenId = nextTokenId();
      _safeMint(msg.sender, tokenId);
      _setTokenURI(tokenId, _moonlightTokenURI);
    }
  }

  function mintBetta(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    isCorrectPayment(BETTA_MOONLIGHT_PRICE, numberOfTokens)
  {
    require(isBettaMintActive && numberOfTokens > 0, "MB");
    uint256 tokenId;
    for (uint256 i = 0; i < numberOfTokens; i++) {
      tokenId = nextTokenId();
      _safeMint(msg.sender, tokenId);
      _setTokenURI(tokenId, _bettaTokenURI);
    }
  }

  // * * * * * * * * * * * * * * * * * * * * JOURNEY CONTROL * * * * * * * * * * * * * * * * * * * *
  function setBaseURIExtended(string calldata baseURINew, uint256 revealNumber) external onlyAfterlife {
    require(!areMintsAndURIsLocked, "J1");
    _baseURIExtended = baseURINew;
    if(revealNumber == 1) {
      if(!revealOneHappened) {
        revealOneHappened = true;  
      }
    } else if (revealNumber == 2) {
      if(!revealTwoHappened) {
        revealTwoHappened = true;  
      }
    } else if (revealNumber == 3) {
     if(!revealThreeHappened) {
        revealThreeHappened = true;  
      }
    } else if (revealNumber == 4) {
      if(!revealFourHappened) {
        revealFourHappened = true;  
      }
    }
  }
  function setIsFlowerMintActive(bool _isFlowerMintActive) external onlyAfterlife {
    require(_isFlowerMintActive != isFlowerMintActive && (!_isFlowerMintActive || !areMintsAndURIsLocked), "J2");
    isFlowerMintActive = _isFlowerMintActive;
  }
  function setIsBettaMintActive(bool _isBettaMintActive) external onlyAfterlife {
    require(_isBettaMintActive != isBettaMintActive && (!_isBettaMintActive || !areMintsAndURIsLocked), "J3");
    isBettaMintActive = _isBettaMintActive;
  }
  function setIsMoonlightMintActive(bool _isMoonlightMintActive) external onlyAfterlife {
    require(_isMoonlightMintActive != isMoonlightMintActive && (!_isMoonlightMintActive || !areMintsAndURIsLocked), "J4");
    isMoonlightMintActive = _isMoonlightMintActive;
  }
  function lockMintsAndURIs() external onlyAfterlife {
    require(!areMintsAndURIsLocked, "J5");
    areMintsAndURIsLocked = true;
  }

  // * * * * * * * * * * * * * * * * * * * * * * Evolution * * * * * * * * * * * * * * * * * * * * * *
  // https://bafybeiasicqus44wyxb725g4cfyc552t6n7vl3ljg7ynq5tphezyhwjozm.ipfs.nftstorage.link/
  function evolve(uint256 tokenIdOne, uint256 tokenIdTwo) external nonReentrant {
    require(revealThreeHappened, "L1");
    string memory tokenOneURI = tokenURI(tokenIdOne);
    string memory tokenTwoURI = tokenURI(tokenIdTwo);
    require(compareURIs(tokenTwoURI, _moonlightTokenURI) || compareURIs(tokenTwoURI, _bettaTokenURI), "L2");
    string memory newURI;
    if(compareURIs(tokenTwoURI, _moonlightTokenURI)) {
      // * * * * * * * * * * * * * * * * * * *  SECRET GARDEN * * * * * * * * * * * * * * * * * * * *
      // https://bafybeidikmewa2awa2da47peuhwfzqai4zwlepoypusdbr3rzpz6iqeomm.ipfs.nftstorage.link/
      // Once a Gold Bouquet Is Claimed, The Ability to Combine Two Moonlights Will Unlock In The
      // "Lab" -> "Evolution" UI of https://Afterlife.garden. 
      // For Each Gold Bouquet Owned, One Triumph Can Be Claimed By Combining Two Moonlights. 
      // After the Triumph Is Claimed, The Ability To Combine Moonlights Dissapears...
      if(compareURIs(tokenOneURI, _moonlightTokenURI)) {
        uint256 balance = balanceOf(msg.sender);
        bool hasUnusedGold = false;
        uint256 i = 0;
        string memory uriAtIndex;
        uint256 tokenIdAtIndex;
        while (i < balance && !hasUnusedGold) {
          tokenIdAtIndex = tokenOfOwnerByIndex(msg.sender, i);
          uriAtIndex = tokenURI(tokenIdAtIndex);
          if(compareURIs(uriAtIndex, _goldBouquetTokenURI) && !_goldsUsedToClaimTriumph[tokenIdAtIndex]) {
            hasUnusedGold = true;
          }
          i++;
        }
        require(hasUnusedGold, "L3");
        _goldsUsedToClaimTriumph[tokenIdAtIndex] = true;
        newURI = _triumphTokenURI;
      } else {
        newURI = getNewURIWithMoonlight(tokenOneURI);
      }
    } else if(compareURIs(tokenTwoURI, _bettaTokenURI)) {
      newURI = getNewURIWithBetta(tokenOneURI);
    } 
    _setTokenURI(tokenIdOne, newURI);
    _burn(tokenIdTwo);
  }

  function hasUnusedGoldBouquet(address senderAddress) external view returns (bool) {
    bool hasUnusedGold = false;
    uint256 i = 0;
    string memory uriAtIndex;
    uint256 tokenIdAtIndex;
    uint256 balance = balanceOf(senderAddress);
    while (i < balance && !hasUnusedGold) {
      tokenIdAtIndex = tokenOfOwnerByIndex(senderAddress, i);
      uriAtIndex = tokenURI(tokenIdAtIndex);
      if(compareURIs(uriAtIndex, _goldBouquetTokenURI) && !_goldsUsedToClaimTriumph[tokenIdAtIndex]) {
        hasUnusedGold = true;
      }
      i++;
    }
    return hasUnusedGold;
  } 

  // * * * * * * * * * * * * * * * * * * * * * * FESTIVAL * * * * * * * * * * * * * * * * * * * * * *
  // https://bafybeia3bt5cttyakx4fbwx7dsihqvtnvk2zvexuw2g3gv7nluxwnobmbe.ipfs.nftstorage.link/
  function arrange(uint256 arrangement) external nonReentrant {
    require(revealTwoHappened, "B1");
    uint256 balance = balanceOf(msg.sender);
    require(balance > 4, "B2");
    require(arrangement < 4, "B3");
    
    uint256 randomNum = random(((block.timestamp % 10) + 7) % 13);
    string[5] memory flowerURIs = [_flowerOneTokenURI, _flowerTwoTokenURI, _flowerThreeTokenURI, _flowerFourTokenURI, _flowerFiveTokenURI];
    string memory bouquetURI = _bronzeBouquetOneTokenURI;
    if(randomNum < 200) {
      bouquetURI = _bronzeBouquetThreeTokenURI;
    } else if (randomNum < 500) {
      bouquetURI = _bronzeBouquetTwoTokenURI;
    }
    // Arrangements: 0 - Bronze, 1 - Silver, 2 - Gold, 3 - Platinum
    if(arrangement == 1) {
      flowerURIs[0] = _flowerOneBettaTokenURI;
      flowerURIs[1] = _flowerTwoBettaTokenURI;
      flowerURIs[2] = _flowerThreeBettaTokenURI;
      flowerURIs[3] = _flowerFourBettaTokenURI;
      flowerURIs[4] = _flowerFiveBettaTokenURI;
      if(randomNum < 290) {
        bouquetURI = _silverBouquetThreeTokenURI;
      } else if(randomNum < 620) {
        bouquetURI = _silverBouquetTwoTokenURI;
      } else {
        bouquetURI = _silverBouquetOneTokenURI;
      }
    }
    if(arrangement == 2) {
      flowerURIs[0] = _flowerOneEclipsedTokenURI;
      flowerURIs[1] = _flowerTwoEclipsedTokenURI;
      flowerURIs[2] = _flowerThreeEclipsedTokenURI;
      flowerURIs[3] = _flowerFourEclipsedTokenURI;
      flowerURIs[4] = _flowerFiveEclipsedTokenURI;
      bouquetURI = _goldBouquetTokenURI;
    } 
    if(arrangement == 3) {
      flowerURIs[0] = _flowerOneBettaEclipsedTokenURI;
      flowerURIs[1] = _flowerTwoBettaEclipsedTokenURI;
      flowerURIs[2] = _flowerThreeBettaEclipsedTokenURI;
      flowerURIs[3] = _flowerFourBettaEclipsedTokenURI;
      flowerURIs[4] = _flowerFiveBettaEclipsedTokenURI;
      bouquetURI = _platinumBouquetTokenURI;
    } 

    // Iterate over user's owned tokens & count number of tokens that
    // match the uris of flowers trying to be combined
    uint256[5] memory matchingFlowers;
    bool hasFlowerOne = false;
    bool hasFlowerTwo = false;
    bool hasFlowerThree = false;
    bool hasFlowerFour = false;
    bool hasFlowerFive = false;
    uint256 numMatchingFlowers = 0;
    string memory uriAtIndex;
    uint256 tokenIdAtIndex;
    uint256 i = 0;
    while (i < balance && !(hasFlowerOne && hasFlowerTwo && hasFlowerThree && hasFlowerFour && hasFlowerFive)) {
      tokenIdAtIndex = tokenOfOwnerByIndex(msg.sender, i);
      uriAtIndex = tokenURI(tokenIdAtIndex);
      if(!hasFlowerOne && compareURIs(uriAtIndex, flowerURIs[0])) {
        matchingFlowers[numMatchingFlowers] = tokenIdAtIndex;
        hasFlowerOne = true;
        numMatchingFlowers++;
      }
      if(!hasFlowerTwo && compareURIs(uriAtIndex, flowerURIs[1])) {
        matchingFlowers[numMatchingFlowers] = tokenIdAtIndex;
        hasFlowerTwo = true;
        numMatchingFlowers++;
      }
      if(!hasFlowerThree && compareURIs(uriAtIndex, flowerURIs[2])) {
        matchingFlowers[numMatchingFlowers] = tokenIdAtIndex;
        hasFlowerThree = true;
        numMatchingFlowers++;
      }
      if(!hasFlowerFour && compareURIs(uriAtIndex, flowerURIs[3])) {
        matchingFlowers[numMatchingFlowers] = tokenIdAtIndex;
        hasFlowerFour = true;
        numMatchingFlowers++;
      }
      if(!hasFlowerFive && compareURIs(uriAtIndex, flowerURIs[4])) {
        matchingFlowers[numMatchingFlowers] = tokenIdAtIndex;
        hasFlowerFive = true;
        numMatchingFlowers++;
      }
      i++;
    }
    require(numMatchingFlowers > 4, "B4");
    // Update the first matching flower to have new uri for the alpha. Burn the next two tokens.
    _setTokenURI(matchingFlowers[0], bouquetURI);
    bool talismanClaimed = false;
    if(arrangement == 3) {
      talismanClaimed = true;
      // First to Claim Platinum Bouquet Gets The Spirit Talisman
      if(!isSpiritTalismanClaimed) {
        isSpiritTalismanClaimed = true;
        _setTokenURI(matchingFlowers[1], _spiritTalismanTokenURI);
      } else if(numPlatinumTalismansClaimed < 10) {
        // Next Ten to Claim Platinum Bouquet Get The Platinum Talisman
        numPlatinumTalismansClaimed += 1;
        _setTokenURI(matchingFlowers[1], _platinumTalismanTokenURI);
      } else {
        _setTokenURI(matchingFlowers[1], _stoneTalismanTokenURI);
      }
    } else if(arrangement == 2) {
      if(numGoldTalismansClaimed < 15) {
        talismanClaimed = true;
        numGoldTalismansClaimed += 1;
        _setTokenURI(matchingFlowers[1], _goldTalismanTokenURI);
      }
    } else if(arrangement == 1) {
      if(numSilverTalismansClaimed < 20) {
        talismanClaimed = true;
        numSilverTalismansClaimed += 1;
        _setTokenURI(matchingFlowers[1], _silverTalismanTokenURI);
      }
    } else {
      if(numBronzeTalismansClaimed < 25) {
        talismanClaimed = true;
        numBronzeTalismansClaimed += 1;
        _setTokenURI(matchingFlowers[1], _bronzeTalismanTokenURI);
      }
    }
    if(!talismanClaimed) {
      _burn(matchingFlowers[1]);
    }
    _burn(matchingFlowers[2]);
    _burn(matchingFlowers[3]);
    _burn(matchingFlowers[4]);
  }

  // * * * * * * * * * * * * * * * * * * * * * * HELPERS * * * * * * * * * * * * * * * * * * * * * *
  function compareURIs(string memory a, string memory b) private view returns (bool) {
    return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(_baseURIExtended, b)));
  }

  function nextTokenId() private returns (uint256) {
    _tokenCounter.increment();
    return _tokenCounter.current();
  }

  function random(uint256 nonce) private view returns (uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase, nonce)))) / (block.timestamp + nonce)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(nonce, msg.sender)))) / (block.timestamp - nonce)) +
        block.number
    )));
    return (seed - ((seed / 1000) * 1000));
  }

  function getNewURIWithMoonlight(string memory uri) private view returns (string memory) {
    if(compareURIs(uri, _flowerOneTokenURI)) {
      return _flowerOneEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerTwoTokenURI)) {
      return _flowerTwoEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerThreeTokenURI)) {
      return _flowerThreeEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerFourTokenURI)) {
      return _flowerFourEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerFiveTokenURI)) {
      return _flowerFiveEclipsedTokenURI;
    }
    if(compareURIs(uri, _triumphTokenURI)) {
      return _triumphEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerOneBettaTokenURI)) {
      return _flowerOneBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerTwoBettaTokenURI)) {
      return _flowerTwoBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerThreeBettaTokenURI)) {
      return _flowerThreeBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerFourBettaTokenURI)) {
      return _flowerFourBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerFiveBettaTokenURI)) {
      return _flowerFiveBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _triumphBettaTokenURI)) {
      return _triumphBettaEclipsedTokenURI;
    }
    return uri;
  }

  function getNewURIWithBetta(string memory uri) private view returns (string memory) {
    if(compareURIs(uri, _flowerOneTokenURI)) {
      return _flowerOneBettaTokenURI;
    }
    if(compareURIs(uri, _flowerTwoTokenURI)) {
      return _flowerTwoBettaTokenURI;
    }
    if(compareURIs(uri, _flowerThreeTokenURI)) {
      return _flowerThreeBettaTokenURI;
    }
    if(compareURIs(uri, _flowerFourTokenURI)) {
      return _flowerFourBettaTokenURI;
    }
    if(compareURIs(uri, _flowerFiveTokenURI)) {
      return _flowerFiveBettaTokenURI;
    }
    if(compareURIs(uri, _triumphTokenURI)) {
      return _triumphBettaTokenURI;
    }
    if(compareURIs(uri, _flowerOneEclipsedTokenURI)) {
      return _flowerOneBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerTwoEclipsedTokenURI)) {
      return _flowerTwoBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerThreeEclipsedTokenURI)) {
      return _flowerThreeBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerFourEclipsedTokenURI)) {
      return _flowerFourBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _flowerFiveEclipsedTokenURI)) {
      return _flowerFiveBettaEclipsedTokenURI;
    }
    if(compareURIs(uri, _triumphEclipsedTokenURI)) {
      return _triumphBettaEclipsedTokenURI;
    }
    return uri;
  }

  // * * * * * * * * * * * * * * * * * * * * * MODIFIERS * * * * * * * * * * * * * * * * * * * * *
  modifier onlyAfterlife() {
    require(_msgSender() == luna || _msgSender() == teknique, "M1");
    _;
  }
  modifier onlyTeknique() {
    require(_msgSender() == teknique, "M2");
    _;
  }
  modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
    require(price * numberOfTokens <= msg.value, "M3");
    _;
  }

  // * * * * * * * * * * * * * * * * * * * * * WITHDRAWING * * * * * * * * * * * * * * * * * * * * *
  function withdraw() external onlyAfterlife {
    uint256 splitAmount = address(this).balance / 2;
    payable(luna).transfer(splitAmount);
    payable(teknique).transfer(splitAmount);
  }

  // * * * * * * * * * * * * * * * * * * * * * FAILSAFES * * * * * * * * * * * * * * * * * * * * * *
  function setLuna(address _luna) external onlyAfterlife {  
    luna = _luna;
  }

  function setTeknique(address _teknique) external onlyTeknique {  
    teknique = _teknique;
  }

  // * * * * * * * * * * * * * * * * * * * * * PLUMBING * * * * * * * * * * * * * * * * * * * * *
  function _baseURI() internal view override returns (string memory) {
    return _baseURIExtended;
  }

  // Required Boilerplate Solidity overrides
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override(ERC721, ERC721Enumerable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
      super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory)
  {
      return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}