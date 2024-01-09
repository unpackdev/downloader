// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract PixaworldNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    string public PROVENANCE;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    bool public saleIsActive = false;
    string private _baseURIextended;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;

    constructor() ERC721("Pixaworld NFT", "PIXA") {
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }

        // If we haven't set the starting index and this is the last saleable token
        if (startingIndexBlock == 0 && totalSupply() == MAX_SUPPLY) {
            startingIndexBlock = block.number;
        }
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + n <= MAX_SUPPLY, "Reserve would exceed max tokens");

        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }

        // If we haven't set the starting index and this is the last saleable token
        if (startingIndexBlock == 0 && totalSupply() == MAX_SUPPLY) {
            startingIndexBlock = block.number;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURIextended;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_SUPPLY;
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

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
