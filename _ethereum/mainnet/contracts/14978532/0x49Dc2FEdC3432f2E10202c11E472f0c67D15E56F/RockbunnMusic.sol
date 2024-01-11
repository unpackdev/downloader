// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./console.sol";

contract RockbunnMusic is ERC721A, Ownable {

    string _baseTokenURI;
    uint256 public immutable maxBatchSizeA;
    uint256 public immutable collectionSizeA;
    address t1 = 0x5b137804dfa92CEd576595b73C3cB1F4258747d3; // Community Manager

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        string memory baseTokenURI
    ) ERC721A("RockbunnMusic", "RBM", maxBatchSize_, collectionSize_) {
        setBaseURI(baseTokenURI);
        maxBatchSizeA = maxBatchSize_;
        collectionSizeA = collectionSize_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function walletOfOwnerRange(address _owner, uint256 _startIndex, uint256 _endIndex) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        require( _endIndex > 0 && _startIndex >= 0, "Index must be positive value." );
        require( _endIndex <= tokenCount && _startIndex <= tokenCount, "Exceeds maximum Rockbunn Music supply." );
        require( _endIndex > _startIndex, "Invalid index, end index is less than start index." );
        
        uint256[] memory tokensId = new uint256[](_endIndex - _startIndex);
        uint256 tokenIndex = 0;
        for(uint256 i = _startIndex; i < _endIndex; i++) {
            tokensId[tokenIndex] = tokenOfOwnerByIndex(_owner, i);
            tokenIndex++;
        }
        return tokensId;
    }
    
    function adoptBatch() public onlyOwner() {
        uint256 tokenCount = totalSupply();
        require( tokenCount < collectionSizeA, "Exceeds maximum Rockbunn Music supply" );
        uint256 remainToken = collectionSizeA - tokenCount;
        if(remainToken < maxBatchSizeA) {
            _safeMint(t1, remainToken);
        } else {
            _safeMint(t1, maxBatchSizeA);
        }
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance;
        require(payable(t1).send(_each));
    }

}