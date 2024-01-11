// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract BECN is ERC721A, Ownable  {
  using SafeMath for uint256;
	using Strings for uint256;
	uint256 public MAX_SUPPLY= 3000;
	uint256 public PRICE = 0.8 ether;
    uint256 public giveawayLimit = 2000;
    string public baseTokenURI;
    
    bool public saleIsActive;
	address private wallet1 = 0xc31b3696eAb93A3a53B10Dd1B21871903CB059e4; 
    address private wallet2 = 0xE608794bc746d1Feedb5A8396882ED68652489e4;

    uint256 public maxPurchase = 20;
    uint256 public maxTx = 10;

    constructor() ERC721A("Bitcoin Elite Club NFT", "BECN") { }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

   
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    function mintBECN(uint256 numberOfTokens) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Total Supply has been minted");
        require(msg.value == PRICE.mul(numberOfTokens), "Ether value sent is not correct");
		require(numberOfTokens > 0 && numberOfTokens <= maxTx, "10 pTX allowed");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxPurchase,"Exceeds Max mints allowed per wallet");
		_safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

	 function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw.");
        uint256 _amount = address(this).balance;
        (bool wallet1Success, ) = wallet1.call{value: _amount.mul(60).div(100)}("");
        (bool wallet2Success, ) = wallet2.call{value: _amount.mul(40).div(100)}("");
        require(wallet1Success && wallet2Success, "Withdrawal failed.");
    }

    function giveAway(uint256 numberOfTokens, address to) external onlyOwner {
        require(giveawayLimit.sub(numberOfTokens) >= 0,"Giveaways exhausted");
        _safeMint(to, numberOfTokens);
        giveawayLimit = giveawayLimit.sub(numberOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setMaxTxLimit(uint256 _txLimit) public onlyOwner {
        maxTx = _txLimit;
    }
	
    function setMaxPurchaseLimit(uint256 _limit) public onlyOwner {
        maxPurchase = _limit;
    }
	
	 function setMaxSupply(uint256 _limit) public onlyOwner {
        MAX_SUPPLY = _limit;
    }
	
	 function setGiveawayLimit(uint256 _limit) public onlyOwner {
        giveawayLimit = _limit;
    }

}