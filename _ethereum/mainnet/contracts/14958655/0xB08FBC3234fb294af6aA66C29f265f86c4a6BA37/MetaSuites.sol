// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./ERC721A.sol"; //
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

   contract METAOFFICES is ERC721A, Ownable  {
    using SafeMath for uint256;
	using Strings for uint256;
    bytes32 public merkleRoot;
    
       
	uint256 public MAX_SUPPLY;
    uint256 public MAX_WL_SUPPLY;
    uint256 public MAX_WL_SUPPLY_S1 = 500;
    uint256 constant public MAX_SUPPLY_S2= 500;
	uint256 constant public MAX_SUPPLY_S3= 500;
    uint256 public MAX_MAIN_SUPPLY;
    uint256 public MAX_MAIN_WL_SUPPLY;
    uint256 public PRICE;
    uint256 constant public PRICE_S1 = 0.25 ether;
    uint256 constant public PRICE_S2 = 0.35 ether;
    uint256 constant public PRICE_S3 = 0.45 ether;
    uint256 public PRICE_MAIN;
    uint256 public PRICE_MAIN_WL;
    
    
    
    uint256 public giveawayLimit = 250;
    string public baseTokenURI;
    bool public whitelistSaleIsActiveS1;
    bool public saleIsActiveS1;
	bool public saleIsActiveS2;
	bool public saleIsActiveS3;
    bool public whitelistMainSaleIsActive;
    bool public MainSaleIsActive;
    
	address private wallet1 = 0x978A1DfB7DA46aFE35b2a31f3797b1AE8249438c; 
    address public Authorized = 0x978A1DfB7DA46aFE35b2a31f3797b1AE8249438c; 

    uint256 public maxPurchase = 1000;
    uint256 public maxWLPurchase = 1;
	uint256 public maxTxWL = 1;
	
    uint256 public maxTx = 5;

    constructor() ERC721A("MetaOffices", "MOFC") { }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyAuthorized {
        require(msg.sender == owner() || msg.sender == Authorized , "Not authorized");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
       
    function flipWLSaleStateS1() external onlyOwner {
        whitelistSaleIsActiveS1 = !whitelistSaleIsActiveS1;
        MAX_WL_SUPPLY = MAX_WL_SUPPLY_S1;
        PRICE = PRICE_S1;
    }
    
    function flipSaleStateS1() external onlyOwner {
        saleIsActiveS1 = !saleIsActiveS1;
		MAX_SUPPLY = MAX_WL_SUPPLY_S1.sub(totalSupply());
        PRICE = PRICE_S1;
    }

    function flipSaleStateS2() external onlyOwner {
        saleIsActiveS2 = !saleIsActiveS2;
		MAX_SUPPLY = MAX_WL_SUPPLY_S1 + MAX_SUPPLY_S2;
        PRICE = PRICE_S2;
    }
    
	
	 function flipSaleStateS3() external onlyOwner {
        saleIsActiveS3 = !saleIsActiveS3;
		MAX_SUPPLY = MAX_WL_SUPPLY_S1 + MAX_SUPPLY_S2 + MAX_SUPPLY_S3;
         PRICE = PRICE_S3;
    }


   
	
	 function flipMainWLSaleState(uint256 _MAX_MAIN_WL_SUPPLY,uint256 _priceWL) external onlyOwner {
         whitelistMainSaleIsActive = !whitelistMainSaleIsActive;
         MAX_WL_SUPPLY = _MAX_MAIN_WL_SUPPLY;
         PRICE = _priceWL;

    }
    
    function FlipMainMint(uint256 _MAX_MAIN_SUPPLY,uint256 _priceMain) external onlyOwner {
         MainSaleIsActive = !MainSaleIsActive;
         MAX_MAIN_SUPPLY = totalSupply().add(_MAX_MAIN_SUPPLY);
         PRICE_MAIN = _priceMain;
    }

    function FlipMainMintStatus() external onlyOwner {
         MainSaleIsActive = !MainSaleIsActive;
    }
    
    
    

    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }


	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    function whitelistMint(uint256 numberOfTokens, bytes32[] calldata merkleProof ) payable external callerIsUser {
        require(whitelistSaleIsActiveS1 || whitelistMainSaleIsActive, "Whitelist Sale must be active to mint");
        require(MAX_WL_SUPPLY >= 0, "Total WL Supply has been minted");
        require(numberOfTokens > 0 && numberOfTokens <= maxTxWL, "maxTxWL");
        require(msg.value == PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxWLPurchase,"Exceeds Max mints allowed per whitelisted wallet");

        // Verify the merkle proof
        require(MerkleProof.verify(merkleProof, merkleRoot,  keccak256(abi.encodePacked(msg.sender))  ), "Invalid proof");

		_safeMint(msg.sender, numberOfTokens);
		MAX_WL_SUPPLY = MAX_WL_SUPPLY.sub(numberOfTokens);
    }

 

    function mintFounderSeries(uint256 numberOfTokens) external payable callerIsUser {
        require(saleIsActiveS1 || saleIsActiveS2 || saleIsActiveS3, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Total Supply has been minted");
        require(msg.value == PRICE.mul(numberOfTokens), "Ether value sent is not correct");
		require(numberOfTokens > 0 && numberOfTokens <= maxTx, "maxTx exceeded");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxPurchase,"Exceeds Max mints allowed per wallet");

        _safeMint(msg.sender, numberOfTokens);
    }
    
    function mintMain(uint256 numberOfTokens) external payable callerIsUser {
        require(MainSaleIsActive, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_MAIN_SUPPLY, "Total Supply has been minted");
        require(msg.value == PRICE_MAIN.mul(numberOfTokens), "Ether value sent is not correct");
		require(numberOfTokens > 0 && numberOfTokens <= maxTx, "maxTx exceeded");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxPurchase,"Exceeds Max mints allowed per wallet");

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

	    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No balance");
        uint256 _amount = address(this).balance;
        (bool wallet1Success, ) = wallet1.call{value: _amount.mul(100).div(100)}("");
        require(wallet1Success, "Withdrawal failed.");
    }

    function giveAway(uint256 numberOfTokens, address to) external onlyOwner {
        require(giveawayLimit.sub(numberOfTokens) >= 0,"Giveaways exhausted");
        _safeMint(to, numberOfTokens);
        giveawayLimit = giveawayLimit.sub(numberOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }


    function setAuthorized(address _authorized) public onlyOwner {
        Authorized = _authorized;
    }

}