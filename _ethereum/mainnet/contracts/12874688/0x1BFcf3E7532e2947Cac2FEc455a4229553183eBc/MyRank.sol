// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract MyRank is ERC721Enumerable, Ownable {
    uint public constant MAX_RANK = 10000;
	string _baseTokenURI;

    constructor(string memory baseURI) ERC721("MyRank", "RANK")  {
        setBaseURI(baseURI);
    }


    function mintRANK(address _to, uint _count) public payable {
        require(totalSupply() + _count <= MAX_RANK, "Max limit");
        require(totalSupply() < MAX_RANK, "Sale end");
        require(_count <= 20, "Exceeds 20");
        require(msg.value >= price(_count), "Value below price");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }

    function price(uint _count) public view returns (uint256) {
        uint _id = totalSupply();
         if(_id <= 499 ){
            return 0;
        }
        
        return 10000000000000000 * _count; // 0.01 ETH
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
}