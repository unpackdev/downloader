// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract MasksOfEther is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    uint256 private price = 0.08 ether;
    uint256 private maxBulkAmount = 30;

    string public MASKS_PROVENANCE = "";
    uint256 public startingIndex;


    uint256 public maxMasks = 10000;
    uint256 private _reserved = 100;

    string public baseURI;
    bool private _saleStarted;


    constructor() ERC721("Masks of Ether", "MASK") public {
        _saleStarted = false;
    }

    function createMask(uint256 _nbTokens) external payable {
        uint256 supply = totalSupply();
        require(_saleStarted, "The Sale is not active");
        require(_nbTokens <= maxBulkAmount, "You cannot mint more than 30 tokens at once!");
        require(supply + _nbTokens <= (maxMasks - _reserved), "Not enough Tokens available");
        require(_nbTokens * price <= msg.value, "You sent the incorrect amount of tokens");

        for (uint256 i; i < _nbTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function claimReserved(uint256 _number, address _receiver) external onlyOwner {
        require(_number <= _reserved, "You cannot claim more than the max reserved.");

        uint256 _tokenId = totalSupply();
        for (uint256 i; i < _number; i++) {
            _safeMint(_receiver, _tokenId + i);
        }

        _reserved = _reserved - _number;
    }


    function flipSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;

        if (_saleStarted && startingIndex == 0) {
            setStartingIndex();
        }
    }

    function saleStarted() public view returns(bool) {
        return _saleStarted;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function getReservedLeft() public view returns (uint256) {
        return _reserved;
    }
   
    // set this before sale
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        MASKS_PROVENANCE = provenanceHash;
    }

    function walletOfUser(address _user) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_user);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_user, i);
        }
        return tokensId;
    }


    function setmaxMasks(uint256 _total) public onlyOwner {
        maxMasks = _total;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    //must be called before sale start
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");

        // BlockHash only works for the most 256 recent blocks.
        uint256 _block_shift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift =  1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint(blockhash(_block_ref)) % maxMasks;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }


    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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