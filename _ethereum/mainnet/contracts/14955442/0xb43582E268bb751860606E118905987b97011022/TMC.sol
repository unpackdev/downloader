// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";

contract TheMillionareClub is ERC721A, PaymentSplitter {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    constructor() ERC721A("The Millionare Club - Hobotizen", "TMC") PaymentSplitter(addressList, splitList) {
        devWallet = msg.sender;
    }

	// Payment splitter
	address[] private addressList = [
		0x478b81132F7A428361DE2325B11d5fFCDb51e9b4, // Khang
		0x5889689cEAb19e7eE692edbB6Bc7F607053522aC, // Dev
        0x418a3c6DF48EDbEDc7C2B9C59cF7Baea2E57C260  // Dev
	];
	uint256[] private splitList = [190, 5, 5];
    string public _contractBaseURI;


    // Dev wallet to track onlyDev modifier
    address private devWallet;

    // Track max and current supply for all tiers
    uint256 public ballerMaxSupply = 10;
    uint256 public diamondMaxSupply = 400;
    uint256 public ballerCurrentSupply = 0;
    uint256 public diamondCurrentSupply = 0;

    // Track wallets for minting diamond tier
    mapping (address => uint256) private walletAmounts;
    // Track tokenIds to boolean for TMCStay
    mapping (uint256 => bool) public usedTMCStay;

    uint256 public maxWLMintPerWallet = 3;

    // Prices for baller tier and diamond tier
    uint256 public ballerPrice = 4 ether;
    uint256 public diamondWLPrice = 1.2 ether;           // Single WL price is 1.2 ether
    uint256 public diamondWLPriceMultiple = 1.0 ether;   // Multiple WL price is 1.0 ether
    uint256 public diamondPublicPrice = 2.5 ether;       // Public price is 2.5 ether

    // Tracks if sale is enabled for public and WL mint
    bool public saleEnabled = false;
    bool public wlSaleEnabled = false;

    // Merkle root used for WL
	bytes32 public root = 0x0fdaf93eeaad8bc2b2fc34f7ebf7e4ef5f88586bf878788ea5b620a2ea9c1799;


    // Used to lock the supply of all tiers
    bool private canChangeSupply = true;

    // Only dev modifier
    modifier onlyDev() {
		require(msg.sender == devWallet, "Only dev wallet is allowed to use this function");
		_;
	}

    // Setter functions
    function flipPublicSaleState() external onlyDev {
        saleEnabled = !saleEnabled;
    }

    function flipWLMintState() external onlyDev {
        wlSaleEnabled = !wlSaleEnabled;
    }

    function setBallerSupply(uint256 quantity) external onlyDev {
        require(canChangeSupply, "Supply is locked");
        ballerMaxSupply = quantity;
    }

    function setDiamondSupply(uint256 quantity) external  onlyDev {
        require(canChangeSupply, "Supply is locked");
        diamondMaxSupply = quantity;
    }

    function setBallerPrice(uint256 _price) external onlyDev {
        ballerPrice = _price;
    }

    function setDiamondPublicPrice(uint256 _price) external onlyDev {
        diamondPublicPrice = _price;
    }

    function setDiamondWLPrice(uint256 _price) external onlyDev {
        diamondWLPrice = _price;
    }

    function setDiamondWLPriceMultiple(uint256 _price) external onlyDev {
        diamondWLPriceMultiple = _price;
    }

    function lockSupply() external onlyDev {
        canChangeSupply = false;
    }

    function setMerkleRoot(bytes32 _root) external onlyDev {
		root = _root;
	}

    function setBaseURI(string memory newBaseURI) external onlyDev {
		_contractBaseURI = newBaseURI;
	}

    // Keep track of TMC stay
    function resetTMCStay(uint256[] calldata tokenIds) external onlyDev {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            usedTMCStay[i] = false;
        }
    }

    function useTMCStay(uint256[] calldata tokenIds) external {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "You are not the owner of the NFT to use this function");
            usedTMCStay[tokenIds[i]] = true;
        }
    }

    // Mint functions
    function mintBaller(uint256 quantity) external onlyDev {
        require(quantity + ballerCurrentSupply <= ballerMaxSupply, "Baller tier is sold out");
        _mint(msg.sender, quantity, '', true);
        ballerCurrentSupply += quantity;
    }

    function mintDiamondWL(uint256 quantity, uint256 tokenId, bytes32[] calldata proof) external payable {
        require(wlSaleEnabled, "WL sale has not started");
        require(quantity + diamondCurrentSupply <= diamondMaxSupply, "Diamond tier is sold out");
        require(quantity > 0, "Mint quantity must be greater than 0");
        require(isTokenValid(msg.sender, tokenId, proof), "Invalid WL proof");
        require(walletAmounts[msg.sender] + quantity <= maxWLMintPerWallet, "You will exceed the max amount per wallet");

        // Cheaper pricing for more than 1 WL mint
        if(quantity > 1) {
            require(msg.value >= quantity * diamondWLPriceMultiple, "Incorrect amount of ether sent");
        } else {
            require(msg.value >= quantity * diamondWLPrice, "Incorrect amount of ether sent");
        }
        // Verify merkle tree for WL mint
        require(isTokenValid(msg.sender, tokenId, proof), "Invalid WL proof");
        // Mint items
        _mint(msg.sender, quantity, '', true);
        // Keep track of diamond supply
        diamondCurrentSupply += quantity;
        // Store in walletAmounts mapping
        walletAmounts[msg.sender] += quantity;
    }

    function mintDiamond(uint256 quantity) external payable {
        require(saleEnabled, "Public sale has not started");
        require(quantity + diamondCurrentSupply <= diamondMaxSupply, "Diamond tier is sold out");
        require(quantity > 0, "Mint quantity must be greater than 0");
        require(msg.value >= diamondPublicPrice, "Incorrect amount of ether sent");
        _mint(msg.sender, quantity, '', true);
        // Keep track of diamond supply
        diamondCurrentSupply += quantity;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721AMetadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString()));
	}

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }
    
    // Merkle tree WL
    function isTokenValid(
		address _to,
		uint256 _tokenId,
		bytes32[] memory _proof
	) public view returns (bool) {
		// Construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));
		// Verify the proof supplied, and return the verification result
		return _proof.verify(root, leaf);
	}


}
