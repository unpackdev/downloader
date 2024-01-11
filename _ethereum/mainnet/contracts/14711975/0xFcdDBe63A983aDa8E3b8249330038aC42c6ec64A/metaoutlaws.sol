// SPDX-License-Identifier: MIT
// Contract audited and reviewed by @CardilloSamuel 
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC2981ContractWideRoyalties.sol";
 
contract METAOUTLAWS is ERC721A, ERC2981ContractWideRoyalties, Ownable {
    string public baseURI = "ipfs://QmQEmMiuHTZcmBs6yNacEgrGSA2GGijxaNsxu8E6Dk398u/";
    bool public saleActive = false;
    bool public preSaleOnly = true;
    bool public contractSealed = false;

    // Price and supply definition
    uint256 constant TOKEN_PRICE = 0.07 ether;
    uint256 constant WL_TOKEN_PRICE = 0.05 ether;
    uint256 constant TOKEN_MAX_SUPPLY = 10000;
    uint256 constant TOKEN_WL_SUPPLY = 50;
    uint256 public RESERVED_LEFT = 100;
  
    //  EIP 2981 Standard Implementation
    address constant public ROYALTY_RECIPIENT = 0x1300ca331BDE73841A26c83697aD5a2B7f00Db22;
    uint256 constant public ROYALTY_PERCENTAGE = 1000; // value percentage (using 2 decimals - 10000 = 100, 0 = 0)

    mapping(address => bool) public presaleList;
 
    constructor () ERC721A("MetaOutlaws", "MO", 20) {
        _setRoyalties(ROYALTY_RECIPIENT, ROYALTY_PERCENTAGE);
    }

    // Toggle the sales
    function toggleSales() public onlyOwner {
        saleActive = !saleActive;
    }

    // Toggle the whitelist
    function togglePresale() public onlyOwner {
        preSaleOnly = !preSaleOnly;
    }

	// Reveal function
    function reveal(string calldata _newUri) public onlyOwner {
        require(!contractSealed, "Contract has been sealed");
        baseURI = _newUri;
    }

    // Efficient and easy way to seal contract to avoid any future modification of baseUri
	function sealContract() public onlyOwner {
	    require(!contractSealed, "Contract has been already sealed");
		contractSealed = true;
	}
 
    // Mint
    function mint(uint256 quantity) public payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(saleActive, "The sale is not active");
        require(quantity > 0 && quantity <= 20, "You can't mint 0 or more than 20 at a time");
        if(preSaleOnly) require(presaleList[msg.sender], "You are not authorized in the presale");

        uint256 tokenPrice = (preSaleOnly) ? WL_TOKEN_PRICE : TOKEN_PRICE;
        uint256 tokenSupply = (preSaleOnly) ? TOKEN_WL_SUPPLY : TOKEN_MAX_SUPPLY;

        require(msg.value == tokenPrice * quantity, "Wrong price");
        require(totalSupply() + quantity <= tokenSupply, "No more token left");
        
        _safeMint(msg.sender, quantity); // Minting of the token(s)
    }
 
    // Airdrop
    function airdrop(address receiver, uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= TOKEN_MAX_SUPPLY, "No more token left");
        _safeMint(receiver, quantity);
    }

    // Reserve
    function sendReserved(address receiver, uint256 quantity) external onlyOwner{
        require(totalSupply() + quantity < TOKEN_MAX_SUPPLY, "Max Supply Reached.");
        require( (RESERVED_LEFT - quantity) >= 0, "Cannot mint more");
        _safeMint(receiver, quantity);
        RESERVED_LEFT = RESERVED_LEFT - quantity;
    }

    // Presale authorization
    function addPresaleList(address[] memory _wallets) public onlyOwner{
        for(uint i; i < _wallets.length; ++i)
            presaleList[_wallets[i]] = true;
    }

    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // EIP 2981 Standard Implementation
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }                                                                                                                                                                                                                                                                                
}