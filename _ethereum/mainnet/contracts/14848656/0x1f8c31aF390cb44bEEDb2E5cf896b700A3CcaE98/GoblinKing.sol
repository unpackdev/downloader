// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract GoblinKing is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    bool public end = false;
    uint256 public max = 5895;
    uint256 public price = 0.009 ether;
    mapping(address => uint256) public users;

	constructor() ERC721A("Goblin King", "Goblin King") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

 	function mint() external payable nonReentrant {
        require(!end);
        require(msg.sender == tx.origin);
        require(totalSupply() + 1 <= max);
    	require(users[msg.sender] + 1 <= 5);
        if (totalSupply() > 1000) {
            require(msg.value == price);
        }
        _safeMint(msg.sender, 1);
        users[msg.sender] += 1;
    }

 	function mintfly(address lords, uint256 _quantity) public onlyOwner {
	    require(totalSupply() + _quantity <= max);
        _safeMint(lords, _quantity);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMax(uint256 _max) external onlyOwner {
        max = _max;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function sumthinboutfunds() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}
