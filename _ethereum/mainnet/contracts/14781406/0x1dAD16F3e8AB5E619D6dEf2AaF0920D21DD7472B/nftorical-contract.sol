// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

//NFTorical
contract NFTorical is ERC721, Ownable {
    uint256 public MAX_ELEMENTS; 

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    address public CREATOR = 0x92b0d5D4B8c74A3EADe139D4F04f0e24648931A4;

    string public baseTokenURI = "https://nftorical.s3.amazonaws.com/";

    constructor(uint256 maxElements) ERC721("NFTORICAL", "NFTORICAL") {
        MAX_ELEMENTS = maxElements;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalSupply() external view returns (uint) {
        return _tokenIdTracker.current();
    }

    function updateMaxElements(uint256 newMaxElements) public onlyOwner {
        require(newMaxElements > MAX_ELEMENTS, "New amount is lower than previous amount");
        MAX_ELEMENTS = newMaxElements;
        mint_batch();
    }

    function mint_batch() private {
        uint256 ACTUAL_ELEMENTS = _totalSupply();
        uint256 BATCH_SIZE = MAX_ELEMENTS - ACTUAL_ELEMENTS;

        for(uint256 i = 0; i < BATCH_SIZE; i++)
        {
            _mintAnElement(CREATOR);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
    }

    function transferToCreator() public onlyOwner{
        (bool success, ) = CREATOR.call{value:address(this).balance}("");
        require(success, "Transfer failed");
    }
}