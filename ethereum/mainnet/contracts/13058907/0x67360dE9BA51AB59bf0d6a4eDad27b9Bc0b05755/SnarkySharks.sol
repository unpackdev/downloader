// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Tag.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SnarkySharkz is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_MINT = 20;
    uint256 private PRICE = 0.08 ether;

    string public PROVENANCE;
    bool private provenanceSet;
    
    uint256 public startingIndex;

    bool private saleStarted;
    string public baseURI;

    address splitter = 0xC66aA7AA61cb8ED379681bc20a8b6b6F57947B5F;

    constructor() ERC721("SnarkySharkz", "SHARKZ") {
        saleStarted = false;
        provenanceSet = false;
    }

    modifier whenSaleStarted() {
        require(saleStarted,"Sale not active");
        _;
    }
    
    modifier whenSaleStopped() {
        require(saleStarted==false,"Sale already started");
        _;
    }
    
    modifier whenProvenanceSet() {
        require(provenanceSet==true,"Provenance not set");
        _;
    }
    
    function mint(uint256 numTokens) external payable whenSaleStarted {
        uint256 supply = totalSupply();
        require(numTokens <= MAX_MINT, "You cannot mint more than 20 Tokens at once!");
        require(supply.add(numTokens) <= MAX_SUPPLY, "Not enough Tokens remaining.");
        require(numTokens.mul(PRICE) <= msg.value, "Incorrect amount sent!");

        for (uint256 i; i < numTokens; i++) {
            _safeMint(msg.sender, supply.add(1).add(i));
        }
    }

    function startSale() external whenSaleStopped whenProvenanceSet onlyOwner {
        saleStarted = true;
        
        if (saleStarted && startingIndex == 0) {
            setStartingIndex();
        }
    }
    
    function stopSale() external whenSaleStarted onlyOwner {
        saleStarted = false;
    }

    function isSaleStarted() public view returns(bool) {
        return saleStarted;
    }
    
    function isSaleStopped() public view returns(bool) {
        return !saleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function getPrice() public view returns (uint256){
        return PRICE;
    }

    // Provenance must be set and locked before sale
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet,"Provenance already locked");
        PROVENANCE = provenanceHash;
    }
    
    function lockProvenance() public onlyOwner {
        require(!provenanceSet,"Provenance already locked");
        provenanceSet = true;
    }

    // List all tokens in a specific wallet
    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function reserveTokens(address _to, uint256 _reserveAmount) public whenSaleStopped() whenProvenanceSet() onlyOwner { 
        require(_to != address(0), "Cannot mint to null address");
        require(startingIndex != 0, "Starting index not set");
        uint supply = totalSupply();
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply.add(1).add(i));
        }
    }

    function setStartingIndex() public onlyOwner{
        require(startingIndex == 0, "Starting index is already set");

        // BlockHash only works for the most 256 recent blocks.
        uint256 _block_shift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift =  1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint(blockhash(_block_ref)) % MAX_SUPPLY;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(payable(splitter).send(balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
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