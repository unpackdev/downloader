// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./GenRand.sol";

contract BitPanda is ERC721Enumerable, Ownable, GenRand {
    using SafeMath for uint256;
    using Strings for uint256;

    string public constant BitPanda_Provenance = "";

    // This is the max number of pandas that can be claimed
    uint public constant MAX_TOKENS = 1111;
    // This is the max number of available pandas, must be a prime
    uint public constant MAX_PANDAS = 1993;
    uint public num_reserved = 5;
    bool public hasSaleStarted = false;
    bool public initialPhase = true;
    uint public createNumBlock;
    uint public constant initialPhaseNumBlocks = 6540 * 10;// After initialPhaseBlocks, random will be settled or first 318 tokens have been sold 
    uint public constant initialPhaseNumTokens = 741;

    //  will be set to a random number between [1, MAX_TOKENS-1]
    uint public multiplier = 1;
    // will be set to a random number between [0, MAX_TOKENS-1]
    uint public summand = 0;

    constructor(string memory baseURI) ERC721("BitPanda","BITPANDA") {
        _setBaseURI(baseURI);
        createNumBlock = block.number;
    }

    function isInitialPhaseEnd() public view returns(bool) {
        return !initialPhase;
    }

    function checkMultiplier() public view returns(uint256) {
        return multiplier;
    }
    
    function checkSummand() public view returns(uint256) {
        return summand;
    }
    
    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index=index.add(1)) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function calculatePrice(uint256 _id) public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(_id < MAX_TOKENS, "All tokens have been claimed");

        if (_id >= 1101) {
            return 1000000000000000000;        // 1101-1111:  1 ETH,     1000000000000000000
        } else if (_id >= 1051) {
            return 800000000000000000;         // 1051-1100:  0.80 ETH   800000000000000000
        } else if (_id >= 951) {  
            return 640000000000000000;         // 951-1050:  0.64 ETH    640000000000000000
        } else if (_id >= 751) {
            return 320000000000000000;         // 751-950:  0.32 ETH     320000000000000000
        } else if (_id >= 351) { 
            return 160000000000000000;         // 351-750: 0.16 ETH      160000000000000000
        } else if (_id >= 151) {
            return 80000000000000000;          // 151-350:  0.08 ETH     80000000000000000
        } else if (_id >= 51) {
            return 40000000000000000;          // 51-150:   0.04 ETH     40000000000000000
        } else {
            return 20000000000000000;          // 0 - 50   0.02 ETH      20000000000000000
        }
    }

    function totalPrice(uint256 _num) public view returns (uint256) {
//        uint256 tot = 0;
//        for(uint256 i=0;i<_num;i++){
//            tot += calculatePrice(totalSupply());
//        }
        // in case of price slippage, you can buy items with old price
        return calculatePrice(totalSupply()).mul(_num);
    }

   function adoptBitPanda(uint256 numPandas) public payable {
        require(totalSupply() < MAX_TOKENS, "Sale has already ended");
        require(numPandas > 0 && numPandas <= 10, "You can adopt minimum 1, maximum 5 pands");
        require(totalSupply().add(numPandas) <= MAX_TOKENS, "Exceeds MAX_TOKENS");
        require(msg.value >= totalPrice(numPandas), "Ether value sent is below the price");

        for (uint i = 0; i < numPandas; i=i.add(1)) {
            uint256 tokenId = nextRand(msg.sender, totalSupply()+1+len);
            _safeMint(msg.sender, tokenId);
        }

        // set randomness: either after 10 days, or first initialPhaseNumTokens tokens have been minted, whichever comes first
        if(initialPhase && (totalSupply()>=initialPhaseNumTokens || block.number>createNumBlock.add(initialPhaseNumBlocks)) ){
            initialPhase = false;
            setRandomness(msg.sender);
        }
    }

    function setRandomness(address from) private {
        multiplier = _random(from) % (MAX_PANDAS-1) + 1;
        summand = _random(from) % (MAX_PANDAS);
    }

    
//    function setBaseURI(string memory baseURI) public onlyOwner {
//        _setBaseURI(baseURI);
//    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint index = tokenId.mul(multiplier).add(summand) % MAX_PANDAS + 1;
        string memory baseURI = _baseURI();
        //return initialPhase ? baseURI : string(abi.encodePacked(baseURI, index.toString())) ;
        return string(abi.encodePacked(baseURI, index.toString())) ;
    }

    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function reserveGiveaway(uint256 numPandas) public onlyOwner {
        uint256 currentSupply = totalSupply();
        require(num_reserved >= numPandas, "Exceeded giveaway supply");
        require(currentSupply.add(numPandas) <= MAX_TOKENS, "Exceeds MAX_TOKENS");
        require(hasSaleStarted == false, "Sale has already started");
        // Reserved for people who helped this project and giveaways
        for (uint256  index = 0; index < numPandas; index=index.add(1)) {
            uint256 tokenId = nextRand(msg.sender, totalSupply()+1+len);
            _safeMint(owner(), tokenId);
            num_reserved --;
        }
    }
}
