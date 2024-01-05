// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract Hashcards is Ownable, ReentrancyGuard, IERC721Receiver, ERC721("Hashcards", "HCT") {
    
    using SafeMath for uint256;

    // uint256 public constant MAX_NFT_SUPPLY = 2100;
    string public PROOF_HASH = "f7a0f078ab1dfb70bba47fbb38816ff750a4c6392f84437f8bdf6329095e413c";
    uint256 public constant MAX_NFT_SUPPLY_PHASE_ONE = 900;
    uint256 public constant MAX_NFT_SUPPLY_PHASE_TWO = 1500;
    uint256 public constant MAX_NFT_SUPPLY_PHASE_THREE = 2100;
    
    bool public SALE_STARTED = false;
    uint256 public SALE_START_TIMESTAMP;
    uint256 public REVEAL_TIMESTAMP;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    
    enum Phase { ONE, TWO, THREE, END }
    Phase public currentPhase = Phase.ONE;

    constructor() {
        _setBaseURI("https://nft.round.xyz/");
        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex, abi.encodePacked(mintIndex));
    }

    modifier saleStarted() {
        require(SALE_STARTED == true, "Sale not started");
        _;
    }
    
    
    modifier nextPhase () {
        _;
        if(totalSupply() == MAX_NFT_SUPPLY_PHASE_ONE) {
            currentPhase = Phase(uint256(currentPhase) + 1);
        }
        if(totalSupply() == MAX_NFT_SUPPLY_PHASE_TWO){
            currentPhase = Phase(uint256(currentPhase) + 1);
        }
        if(totalSupply() == MAX_NFT_SUPPLY_PHASE_THREE){
            currentPhase = Phase(uint256(currentPhase) + 1);
            if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY_PHASE_THREE || block.timestamp >= REVEAL_TIMESTAMP)) {
                startingIndexBlock = block.number;
            }
        }
    }
    
    function mintCard(uint256 _noOfCards) nonReentrant saleStarted nextPhase public {
        
        require(currentPhase != Phase.END, "Sale Completed");
        
        if(currentPhase == Phase.ONE) {
            require (_noOfCards <= 5 && _noOfCards > 0, "Not valid no. of NFT");
            require(totalSupply().add(_noOfCards) <= MAX_NFT_SUPPLY_PHASE_ONE, "Exceeds MAX_NFT_SUPPLY_PHASE_ONE");
        
            for (uint i = 0; i < _noOfCards; i++) {
                uint mintIndex = totalSupply();
                _safeMint(msg.sender, mintIndex);
            }
        }
        
        if(currentPhase == Phase.TWO) {
            require (block.timestamp > (SALE_START_TIMESTAMP + 7 days));
            require (_noOfCards <= 3 && _noOfCards > 0, "Not valid no. of NFT");
            require(totalSupply().add(_noOfCards) <= MAX_NFT_SUPPLY_PHASE_TWO, "Exceeds MAX_NFT_SUPPLY_PHASE_TWO");
        
            for (uint i = 0; i < _noOfCards; i++) {
                uint mintIndex = totalSupply();
                _safeMint(msg.sender, mintIndex);
            }
            
        }
        
        if(currentPhase == Phase.THREE) {
            require (block.timestamp > (SALE_START_TIMESTAMP + 14 days));
            require (_noOfCards <= 3 && _noOfCards > 0, "Not valid no. of NFT");
            require(totalSupply().add(_noOfCards) <= MAX_NFT_SUPPLY_PHASE_THREE, "Exceeds MAX_NFT_SUPPLY_PHASE_THREE");
        
            for (uint i = 0; i < _noOfCards; i++) {
                uint mintIndex = totalSupply();
                _safeMint(msg.sender, mintIndex);
            }
            
        }
        
    }

    function mintCardDelegate(uint256 _noOfCards, address _receiver) nonReentrant saleStarted nextPhase public {
        
        require(currentPhase != Phase.END, "Sale Completed");
        
        if(currentPhase == Phase.ONE) {
            require (_noOfCards <= 5 && _noOfCards > 0, "Not valid no. of NFT");
            require(totalSupply().add(_noOfCards) <= MAX_NFT_SUPPLY_PHASE_ONE, "Exceeds MAX_NFT_SUPPLY_PHASE_ONE");
        
            for (uint i = 0; i < _noOfCards; i++) {
                uint mintIndex = totalSupply();
                _safeMint(_receiver, mintIndex);
            }
        }
        
        if(currentPhase == Phase.TWO) {
            require (block.timestamp > (SALE_START_TIMESTAMP + 7 days));
            require (_noOfCards <= 3 && _noOfCards > 0, "Not valid no. of NFT");
            require(totalSupply().add(_noOfCards) <= MAX_NFT_SUPPLY_PHASE_TWO, "Exceeds MAX_NFT_SUPPLY_PHASE_TWO");
        
            for (uint i = 0; i < _noOfCards; i++) {
                uint mintIndex = totalSupply();
                _safeMint(_receiver, mintIndex);
            }
            
        }
        
        if(currentPhase == Phase.THREE) {
            require (block.timestamp > (SALE_START_TIMESTAMP + 14 days));
            require (_noOfCards <= 3 && _noOfCards > 0, "Not valid no. of NFT");
            require(totalSupply().add(_noOfCards) <= MAX_NFT_SUPPLY_PHASE_THREE, "Exceeds MAX_NFT_SUPPLY_PHASE_THREE");
        
            for (uint i = 0; i < _noOfCards; i++) {
                uint mintIndex = totalSupply();
                _safeMint(_receiver, mintIndex);
            }
            
        }
        
    }

    function finalizeStartingIndex() saleStarted public {
        
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY_PHASE_THREE || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }    
        
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(keccak256(abi.encodePacked(blockhash(startingIndexBlock), keccak256(abi.encodePacked(block.timestamp)))))%1200;
        
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(keccak256(abi.encodePacked(blockhash(block.number-1), keccak256(abi.encodePacked(block.timestamp)))))%1200;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(666);
        }
    }    

    function startSale() public onlyOwner {
        require(SALE_STARTED == false, "Sale already started");
        SALE_STARTED = true;
        SALE_START_TIMESTAMP = block.timestamp;
        REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + 21 days;
    }

    function rescueStuckNFT(address _receiver, bool _status) public onlyOwner {
        IERC721(address(this)).setApprovalForAll(_receiver, _status);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}
