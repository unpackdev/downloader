// contracts/NFTea.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title NFTEA contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract NFTea is ERC721, Ownable {
    using SafeMath for uint256;

    string public NFTea_EXISTENCE = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public constant TeaPrice = 150000000000000000; //0.15 ETH

    uint public constant maxTeaPurchase = 20;

    uint256 public MAX_Tea;

    bool public saleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 saleStart) public ERC721(name, symbol) {
        MAX_Tea = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart + (86400 * 7);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * Set some NFTEA aside
     */
    function reserveTEA() public onlyOwner {        
        uint supply = totalSupply();
        _safeMint(msg.sender, supply + 1);
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    } 

    /*     
    * Set existence once it's calculated
    */
    function setExistenceHash(string memory ExistenceHash) public onlyOwner {
        NFTea_EXISTENCE = ExistenceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    * Mints NFTEA
    */
    function mintTEA(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint TEA");
        require(numberOfTokens <= maxTeaPurchase, "Can only mint 50 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_Tea, "Purchase would exceed max supply of Tea");
        require(TeaPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_Tea) {
                _safeMint(msg.sender, mintIndex);
            }
            if (totalSupply() % 145 == 143){
                _safeMint(msg.sender, mintIndex+1);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_Tea || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }
    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_Tea;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_Tea;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}