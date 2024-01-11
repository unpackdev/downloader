// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol"; 


contract MRGLIN is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2221;
    string private baseURI = "ipfs://QmRWmCcCwbh168CUWU7ELxH1a8Mv9rqPX8iZFmreTnJvzm/";
    bool public publicSale = false;
    mapping(address => uint256) public totalPublicMinted;
    uint256 public maxMints = 20;
    uint256 public mintprice = 0.002 ether;

    constructor() ERC721A("MRGLIN", "MRGLIN") {
        _safeMint(msg.sender, 1); 
    }

    modifier noBots(){
        require(tx.origin == msg.sender, "MRGLIN :: Please be yourself, not a contract.");
        _;
    }

    function publicMint(uint8 _quantity) payable external noBots() {
        require(msg.value >= mintprice * _quantity, "MRGLIN :: Not the right ETH amount.");
        require(_quantity > 0 && _quantity <= 5, "MRGLIN :: You can only mint 5 per transaction.");
        require(publicSale, "MRGLIN :: Public sale has yet to be activated or already has been activated and is over.");
        require(totalPublicMinted[msg.sender] + _quantity <= maxMints, "MRGLIN :: You reached your max mints");
        require(totalSupply() + _quantity <= maxSupply, "MRGLIN :: The supply cap is reached.");
        totalPublicMinted[msg.sender] += _quantity;

        _safeMint(msg.sender, _quantity);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function _startTokenId() internal view virtual override(ERC721A) returns(uint256) {
        return 1;
    }

    function setMetadata(string memory newUri) external onlyOwner {
        baseURI = newUri;
    }

    function activateSale(bool newSale) external onlyOwner {
        publicSale = newSale;
    }

    function transferFunds() public onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}