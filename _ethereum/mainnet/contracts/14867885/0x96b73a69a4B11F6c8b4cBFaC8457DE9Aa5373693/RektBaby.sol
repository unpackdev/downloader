// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract RektBaby is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    bool public end = false;
    uint256 public max = 8800;
    uint256 public price = 0.005 ether;
    string boxURI;
    mapping(uint256 => bool) public opened;

	constructor() ERC721A("RektBaby", "RektBaby") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (opened[tokenId]) {
            return super.tokenURI(tokenId);
        } else {
            return boxURI;
        }
    }

 	function mint() external payable nonReentrant {
        require(!end);
        require(msg.sender == tx.origin);
        require(totalSupply() + 1 <= max);
    	require(_numberMinted(msg.sender) + 1 <= 10);
        if (totalSupply() > 1000) {
            require(msg.value == price);
        }
        _safeMint(msg.sender, 1);
    }

    function open(uint256 tokenId) external {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(isApprovedOrOwner, 'caller is not owner nor approved');

        opened[tokenId] = true;
    }

 	function mintfly(address lords, uint256 _quantity) public onlyOwner {
	    require(totalSupply() + _quantity <= max);
        _safeMint(lords, _quantity);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setBoxURI(string memory _uri) external onlyOwner {
        boxURI = _uri;
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
