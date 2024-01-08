//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract Bee is ERC721Enumerable, Ownable{    
    using SafeMath for uint256;

    string public DECK;
    uint public constant MAX_BEES = 10000;    
    uint public constant MAX_AIRDROP = 630;  
    
    uint256 public constant BEE_PRICE = 50000000000000000; //0.05 ETH

    uint256 public PREMINT_TIME;      
    uint256 public MINT_TIME;       
    uint256 public REVEAL_TIME;     

    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    string public _baseTokenURI = "https://api.buzzybeeshive.com/api/";
    bool public paused = false;
    
    uint256 public winnerBAYC = MAX_BEES; //when setted will show the winner bee, a number between 0 and 9999
    uint256 public airdropDone = 0;

    //Roadmap
    uint256 public timeToBuzzReached = MAX_BEES.mul(25).div(100);
    uint256 public beesAreBullishReached = MAX_BEES.mul(75).div(100);

    mapping(address => uint256) public whitelist;
    mapping(uint => address) public bullsWinners;

    constructor(uint256 _startDate) ERC721("Buzzy Bees Hive", "BEE"){
        PREMINT_TIME = _startDate;      
        MINT_TIME = PREMINT_TIME.add(86400);    // 1 day from premint
        REVEAL_TIME = MINT_TIME.add(604800);    // 1 week from public mint     
    }

    modifier mintIsOpen{
        if(msg.sender != owner()){
            require(!paused, "Pause");
        }
        _;
    }

    function mintBee(uint amount) public payable mintIsOpen {
        require(totalSupply().add(amount).add(MAX_AIRDROP).sub(airdropDone)  <= MAX_BEES, "Mint would exceed max supply");
        require(MINT_TIME <= block.timestamp, "Public mint is not open yet");
        require(amount <= 10, "Only 10 at a time");
        require(price(amount) <= msg.value, "Incorrect Ether value sent");
        doMint(msg.sender, amount);
        
        if (startingIndexBlock == 0 && (totalSupply() == MAX_BEES || block.timestamp >= REVEAL_TIME)) {
            startingIndexBlock = block.number;
        }
    }

    function premintBee(uint amount) public payable mintIsOpen {
        require(whitelist[msg.sender]>=amount, "You must be on the whitelist");
        require(totalSupply().add(amount).add(MAX_AIRDROP) <= MAX_BEES, "Mint would exceed max supply");
        require(PREMINT_TIME <= block.timestamp, "Premint not available yet");
        require(MINT_TIME > block.timestamp, "Public mint is open");
        require(preMintPrice(amount)  <= msg.value, "Incorrect Ether value sent");
        doMint(msg.sender, amount);
        whitelist[msg.sender] = whitelist[msg.sender].sub(amount);    
    }

    function doMint(address to, uint amount) internal {
        for(uint i = 0; i < amount; i++){
            _safeMint(to, totalSupply()); 
        }
    }

    function price(uint amount) public pure returns (uint256) {
        return BEE_PRICE.mul(amount);
    }
    function preMintPrice(uint amount) public pure returns (uint256) {
        return BEE_PRICE.sub(10000000000000000).mul(amount);
    }
      
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function flipState() public onlyOwner {
        paused = !paused;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "Something went wrong");
    }

    function fillWhiteList(address[] memory _users) public onlyOwner {
       uint size = _users.length;
     
       for(uint256 i = 0; i < size; i++){
          address user = _users[i];
          whitelist[user] = 3;
       }
    }

    function timeToBuzz(uint amount) public onlyOwner{
        require(totalSupply() >= timeToBuzzReached, "Not completed yed");
        require(airdropDone.add(amount) <= MAX_AIRDROP, "Exceeds max airdrop");
        uint winner;
        for(uint256 i = 0; i < amount; i++){
            winner = uint(keccak256(abi.encodePacked(i, block.number, block.difficulty, block.timestamp))) % timeToBuzzReached;
            airdropDone = airdropDone.add(1);
            doMint(ownerOf(winner), 1);
        }
    }

    function beesAreBullish(uint[] memory bulls) public onlyOwner{
        require(totalSupply() >= beesAreBullishReached, "Not finished");
        uint winner;
        for(uint256 i = 0; i < bulls.length; i++){
            winner = uint(keccak256(abi.encodePacked(bulls[i], block.number, block.difficulty, block.timestamp))) % beesAreBullishReached;
            bullsWinners[bulls[i]] = ownerOf(winner);
        }
    }

    function apeShakesTheHive(string memory buzzyWord) public onlyOwner{
        require(totalSupply() == MAX_BEES, "Not finished");
        require(winnerBAYC == MAX_BEES, "Winner has been chosen");
        winnerBAYC = uint(keccak256(abi.encodePacked(buzzyWord, block.number, block.difficulty, block.timestamp))) % MAX_BEES;
    }

    function setDeckHash(string memory deckHash) public onlyOwner {
        require(MINT_TIME > block.timestamp, "This must be done before public mint");
        DECK = deckHash;
    }
   
    function airdropMint(address to, uint amount) public onlyOwner {        
        require(totalSupply().add(amount).add(MAX_AIRDROP) <= MAX_BEES, "Mint would exceed max supply");
        for(uint i = 0; i < amount; i++){
            airdropDone = airdropDone.add(1);
            _safeMint(to, totalSupply());
        }
    }

    /**                                          
     * Set the starting index for the collection 
     */                                          
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_BEES;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_BEES;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }    

     /**
     * Set the starting index block for the collection manually
     */
    function setStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

     /**
     * Just in case we want to update to earlier dates
     */
    function updateDates(uint256 newDate) public onlyOwner {
        require(newDate > block.timestamp, "Time travel not allowed");
        require(newDate < PREMINT_TIME, "Must be earlier");
        
        PREMINT_TIME = newDate;     
        MINT_TIME = PREMINT_TIME.add(86400);       // 1 day from premint
        REVEAL_TIME = MINT_TIME.add(604800);       // 1 week from public mint
    }
  
}