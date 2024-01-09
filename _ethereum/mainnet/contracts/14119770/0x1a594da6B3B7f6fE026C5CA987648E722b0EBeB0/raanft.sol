// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
 
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC2981ContractWideRoyalties.sol";
 
contract RAANFT is ERC721A, ERC2981ContractWideRoyalties, Ownable {
    string public baseURI = "ipfs://QmNU8mP16fqDKMATZ35gpR7na2nufPgxXtYFJFdyYz6nKD?"; // Change ton ipfs://
    bool public saleActive = false;
    bool public whitelistOnly = true;
    bool public contractSealed = false;
    bytes32 private whitelistMerkleRoot = 0x719e195fa3f2af8263949a77dfcc87348341394599cd482f177db268757addac;
    bytes32 private previousBuyersRoot = 0xe0441d19f49682aad8021fd8794dcb751ba7a19ed30d36ea781448a92b19df60;

    // Price and supply definition
    uint256 public TOKEN_PRICE = 0.2 ether; 
    uint256 constant public TOKEN_MAX_SUPPLY = 6666;
  
    //  EIP 2981 Standard Implementation
    address constant public ROYALTY_RECIPIENT = 0xe9FA03EA36B5CC9db463Cdb8E440178e7E869BC4;
    uint256 constant public ROYALTY_PERCENTAGE = 500; // value percentage (using 2 decimals - 10000 = 100, 0 = 0)

    // Protection
    mapping (address => uint256) amountMinted;
    uint256 public mintLimit = 2;
 
    constructor () ERC721A("RAA-NFT", "RAANFT", 10) {
        _setRoyalties(ROYALTY_RECIPIENT, ROYALTY_PERCENTAGE);
    }
 
    // More gas efficient base URI system
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Toggle the sales
    function toggleSales() public onlyOwner {
        saleActive = !saleActive;
    }

    // Toggle the whiteliste
    function toggleWhitelist() public onlyOwner {
        whitelistOnly = !whitelistOnly;
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

    function setMintLimit(uint256 newLimit) public onlyOwner {
        require(!contractSealed, "Contract has been already sealed");
        mintLimit = newLimit;
    }
 
    // Mint
    function mint(bytes32[] calldata _merkleProof, bytes32[] calldata _merkleProofSpent, uint256 quantity) public payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(saleActive, "The sale is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); // To verify both whitelist

        // Checking whitelist
        if(whitelistOnly) {
            require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid proof.");
            require(amountMinted[msg.sender] + quantity <= mintLimit, "You can't mint more than that for now");

            if(MerkleProof.verify(_merkleProofSpent, previousBuyersRoot, leaf)) TOKEN_PRICE = 0.1 ether;
        } else {
            require(amountMinted[msg.sender] + quantity <= 10, "You can't mint more than 10");
        }

        require(msg.value >= TOKEN_PRICE * quantity, "Wrong price");
        require(totalSupply() + quantity <= TOKEN_MAX_SUPPLY, "No more RAANFT left");
        
 
        amountMinted[msg.sender] = amountMinted[msg.sender] + quantity;
        _safeMint(msg.sender, quantity);
    }
 
    // Airdrop
    function airdrop(address receiver, uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= TOKEN_MAX_SUPPLY, "No more RAANFT left");
        _safeMint(receiver, quantity);
    }

    function getPrice(bytes32[] calldata _merkleProof) public view returns(uint256) {
        uint256 tokenPrice = 0.2 ether;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if(whitelistOnly && MerkleProof.verify(_merkleProof, previousBuyersRoot, leaf)) tokenPrice = 0.1 ether;
        return tokenPrice;
    }

    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
		payable(ROYALTY_RECIPIENT).transfer(address(this).balance);
	}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    // EIP 2981 Standard Implementation
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }                                                                                                                                                                                                                                                                                
}          