//     ___                       ___           ___                 
//     /__/\        ___          /  /\         /__/\        ___     
//    |  |::\      /  /\        /  /::\       |  |::\      /  /\    
//    |  |:|:\    /  /:/       /  /:/\:\      |  |:|:\    /  /:/    
//  __|__|:|\:\  /__/::\      /  /:/~/::\   __|__|:|\:\  /__/::\    
// /__/::::| \:\ \__\/\:\__  /__/:/ /:/\:\ /__/::::| \:\ \__\/\:\__ 
// \  \:\~~\__\/    \  \:\/\ \  \:\/:/__\/ \  \:\~~\__\/    \  \:\/\
//  \  \:\           \__\::/  \  \::/       \  \:\           \__\::/
//   \  \:\          /__/:/    \  \:\        \  \:\          /__/:/ 
//    \  \:\         \__\/      \  \:\        \  \:\         \__\/  
//     \__\/                     \__\/         \__\/               
//
// @loedx


// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

// Import some OpenZeppelin Contracts.
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
// Oracle of ChainLink for random number
import "./VRFConsumerBase.sol";
import "./console.sol";


contract MiamiHome is ERC721, Ownable, VRFConsumerBase {
  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;
  string private _baseTokenURI;

// number of NFTs availables for minting
  uint256 public constant MAX_SUPPLY = 1250;
  uint256 public constant MAX_PER_MINT = 10;
  uint256 public nftPrice = 0.1 ether;

  bool public saleIsActive;
  bool public burnIsActive;

  address r1 = 0xD748A233C65C12898EA7c4F69a9105EE1dB838D4; // Property
  address r2 = 0x682C903aaa75aD57b98712Cf072C42fF8F83Ed1a; // TitleDAO
  address r3 = 0x55B423C0260291805A98F11031825C72f952b6C0; // Charity
  address r4 = 0x4dDCB995f9C34DDD2318B8094e9cCfe03150357C; // For the memes


  //randomness variables
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public randomResult;
    uint256 public tokenIdWinner;
    address public winnerAddress;

  constructor()
    // We need to pass the name of our NFTs token and it's symbol.
    ERC721 ("MiamiHome", "MIA")
    // We need to pass 2 variables for the chainlink oracle
    VRFConsumerBase( 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
         0x514910771AF9Ca656af840dff83E8264EcF986CA ) // LINK Token 
         {
    _nextTokenId.increment(); //Start Token Ids at 1
    saleIsActive = true;  // Set sale to inactive
    burnIsActive = false;  // Set burn to inactive
    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445; // for chainlink oracle
    fee = 2 * 10 ** 18; // 2 LINK (Varies by network)
  }
       
//RANDOM NUMBER FUNCTIONS

//Requests randomness 
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
       return requestRandomness(keyHash, fee);
    }

    //Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        // Used formula to get the random number in a range 
        //rand % (max - min + 1) + min 
        // max and min are the range, rand is randomResult
        tokenIdWinner = randomResult %(1250)+1  ; 
        // we select the address that has the tokenid in that moment and we saved it
        // even if it changes hands later, the winner is the address that was here. 
        winnerAddress = ownerOf(tokenIdWinner);
    }

// MINTING LIMITS PER ADDRESS

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 10;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }


  // MINTING FUNCTION
  function mint(uint256 numberOfTokens) public payable {
    require(saleIsActive, "Sale is not active");

    require(numberOfTokens > 0, "Quantity must be greater than 0.");

    require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");

    //For checking if we still have NFTs to mint
    require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "MiamiHome is sold out!");
    
    require(msg.value >= numberOfTokens * nftPrice, "Not enough ETH");

      // For checking the minting limit per address
    if (allowedMintCount(_msgSender()) >= numberOfTokens) {
      updateMintCount(_msgSender(), numberOfTokens);
    } else {
      revert("Minting limit exceeded per wallet");
    }

    // Actually mint the NFT 
    for (uint256 i = 0; i < numberOfTokens; i++) {
    _safeMint(msg.sender, _nextTokenId.current());
    // Increment the counter for when the next NFT is minted.
    _nextTokenId.increment();
    }
  }

      // Function to allow a user to burn their nft
    function burn(uint256 tokenId) public virtual {
        require(burnIsActive, "Burning is not active.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized to burn.");
        _burn(tokenId);
    }
  

    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    // Function to return how many tokens have been minted
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }
    
     // Function to override the baseURI function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Function to set the baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

     // Function to flip the sale on or off
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Function to flip burning on or off
    function toggleBurn() public onlyOwner {
        burnIsActive = !burnIsActive;
    }

    // Function to update the treasury address if its needed
    function updateTreasury(address newAddress) external onlyOwner {
        r1 = newAddress;
    }

    // Function to update for the mind behind the memes
    function updateMemes(address newAddress) external onlyOwner {
        r4 = newAddress;
    }

    // Function to withdraw ETH balance with splits
    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(r1).transfer((balance * 70) / 100);  // 70% - Property
        payable(r2).transfer((balance * 22) / 100);  // 22% - TitleDAO
        payable(r3).transfer((balance * 5) / 100);   // 5%  - Charity
        payable(r4).transfer((balance * 3) / 100);   // 3%  - MemeGoddess
        payable(r1).transfer(address(this).balance); // Transfer remaining balance to property
    }
}
