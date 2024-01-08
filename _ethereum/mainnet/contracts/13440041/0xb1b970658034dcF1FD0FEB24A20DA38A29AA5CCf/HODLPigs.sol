// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract HODLPigs is ERC721, Pausable, Ownable, ERC721Enumerable {
    // Contract by Raid55 for HODLPIGS
    // HODLPIGS.com, worlds first NFT Ether Piggy Banks
    // Coded with constant and absolute dreed that I made a big mistake somewhere.

    // you can't get me int overflow hackers lmao
    using SafeMath for uint256;
    // Total ledger (from deposits, PigId -> eth)
    mapping(uint256 => uint256) public ledger;
    uint256 public totalLedger;
    // Price per pig
    uint256 public constant PIG_PRICE = 0.05 ether; //0.05
    // Max pig purchased in one Tx
    uint256 public constant MAX_PER_TX = 20;
    // total supply of pigs to be minted
    uint256 public constant ORIGINAL_SUPPLY = 10000;
    // timestamp when the index should get set
    // if token did not sell out by then
    uint256 public constant REVEAL_TIMESTAMP = 1635145200;
    // a hash of all the images hashed in it's
    // original generated sequence
    string public provenance = "75804417186d360a948d7734e3273fd210c60a3968ff9a83201439d9deb11270";
    // mint index that increments to 9999
    // prevents and mints after that
    uint256 public mintIdx = 0;
    // base uri that points to IPFS
    string public baseURI = "https://hodlpigs.com/public/pig/";
    // random block choosen to get starting index from
    uint256 public startingIndexBlock;
    // Random offset to keep sale random
    uint256 public startingIndex;
    // Locks URI of contract
    bool public locked = false;

    // Events
    event Deposit(address indexed from, uint256 indexed tokenId, uint256 value);
    event Cracked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 value
    );

    constructor() ERC721("HODLPIGS", "HDPIGS") {
        reservePigs();
        pause();
    }

    /*
     * deposit money into a pig's ledger
     */
    function deposit(uint256 tokenId) public payable {
        //check if pig exists
        require(_exists(tokenId), "Pig has been cracked or is not minted");

        ledger[tokenId] = ledger[tokenId].add(msg.value);
        totalLedger = totalLedger.add(msg.value);
        emit Deposit(msg.sender, tokenId, msg.value);
    }

    /*
     * Cracks pig, burning the NFT using the_burn command
     * sends the money the pig had in the ledger to the caller (pig owner)
     */
    function crackPig(uint256 tokenId) public {
        require(_exists(tokenId), "Pig has been cracked or is not minted");
        // require that the sender owns the token
        require(
            ownerOf(tokenId) == msg.sender,
            "Only owner can crack open a pig"
        );
        require(ledger[tokenId] > 0, "Pig is empty");

        // subtract balance
        uint256 balance = ledger[tokenId];
        ledger[tokenId] = 0;
        totalLedger = totalLedger.sub(balance);

        // scary stuff
        _burn(tokenId);
        // you can't get me re-entrency hackers lmao xd
        payable(msg.sender).transfer(balance);
        emit Cracked(msg.sender, tokenId, balance);
    }

    /*
     * mint pig, set starting index if last pig or past reveal
     */
    function mintPig(uint256 numberOfTokens) public payable whenNotPaused {
        require(numberOfTokens <= MAX_PER_TX, "Max of 10 tokens per transaction");
        require(
            mintIdx + numberOfTokens <= ORIGINAL_SUPPLY,
            "Purchase would exceed max supply"
        );
        require(
            msg.value >= numberOfTokens * PIG_PRICE,
            "Insuficient Ether Provided"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (mintIdx < ORIGINAL_SUPPLY) {
                _safeMint(msg.sender, mintIdx);
                mintIdx += 1;
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (
            startingIndexBlock == 0 &&
            (mintIdx == ORIGINAL_SUPPLY.sub(1) || block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    /*
     * to be called after final URI is set to freeze metadata
     */
    function freeze() public onlyOwner {
        require(!locked, "Contract already locked");
        locked = true;
    }

    /*
     * to set the final URI once reveal is done
     */
    function setBaseURI(string memory newURI) public onlyOwner {
        require(!locked, "Contract is locked");
        baseURI = newURI;
    }
    
    /*
     * just in case prov needs to be reset
     */
    function setProvenance(string memory newProv) public onlyOwner {
        require(!locked, "Contract is locked");
        provenance = newProv;
    }

    /*
     * Our own pigs for givaway, friends, and family
     */
    function reservePigs() public onlyOwner {
        require(mintIdx == 0, "can only reserve first 30 pigs");

        for (uint256 i = 0; i < 50; i++) {
            _safeMint(msg.sender, mintIdx);
            mintIdx += 1;
        }
    }

    /*
     * Drains smart contract wallet without
     * withdrawing the ledger funds
    */
    function drain() public onlyOwner {
        uint256 drainable = address(this).balance;

        drainable = drainable.sub(totalLedger);

        payable(msg.sender).transfer(drainable);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /*
     * Set starting index after starting block has been picked.
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % ORIGINAL_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % ORIGINAL_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index, i dont know why its here but here it is
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
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
