// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

//
//  _    _      _   _     __  __      _   _             _         _       
// | |  (_)__ _| |_| |_  |  \/  |__ _| |_| |_ ___ _ _  | |   __ _| |__ ___
// | |__| / _` | ' \  _| | |\/| / _` |  _|  _/ -_) '_| | |__/ _` | '_ (_-<
// |____|_\__, |_||_\__| |_|  |_\__,_|\__|\__\___|_|   |____\__,_|_.__/__/ 
//        |___/                                                           
//

contract KoiFishCollective is ERC721Enumerable, Pausable, Ownable {
    using SafeMath for uint256;

    string public KOI_PROVENANCE = "";
    
    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public constant koiPrice = 80000000000000000; // 0.08 ETH
    
    uint public constant maxKoiPurchase = 20;

    uint256 public MAX_KOI;

    bool public saleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    string private baseURI;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 saleStart) ERC721(name, symbol) {
        MAX_KOI = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart + (86400 * 9);
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
    
    // reserve koi
    function reserveKoi() public onlyOwner {
        uint numKoi = 30;

        require(totalSupply().add(numKoi) <= MAX_KOI, "Purchase would exceed max supply of Koi");

        uint supply = totalSupply();
        uint i;
        for (i = 0; i < numKoi; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    // Set provenance
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        KOI_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Pause sale if active, make active if paused
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Mint Koi
    function mintKoi(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Koi");
        require(numberOfTokens <= maxKoiPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_KOI, "Purchase would exceed max supply of Koi");
        require(koiPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_KOI) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // Set starting index block on last saleable token or on the first token sold after.
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_KOI || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    // Set the starting index for the collection
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_KOI;
        // Sanity check
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_KOI;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    // Set the starting index block for the collection, essentially unblocking
    // setting starting index
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}