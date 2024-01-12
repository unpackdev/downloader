// SPDX-License-Identifier: MIT
// Created by devs@augmented-avatars.com

pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract TomorrowsWorldNFT is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;
    using MerkleProof for bytes32[];
	
    uint16 public constant presaleSupply = 2000;
	uint256 public constant maxSupply = 10000;

	string public baseURI;
	string private notRevealedURI;
    bytes32 private presaleMerkleRoot;
    address public theOwner;

    bool public privateMintStarted = true;
    bool public publicMintStarted = false;
	string public baseExtension = ".json";
	uint256 public mintCount = 0;
	uint256 public cost = 0.15 ether;
    uint256 public presaleCost = 0.1 ether;
    uint8 private presaleMaxItemsPerWallet = 10;
	bool public revealedState = false;

    address public TWNFT1Address = payable(0xa433979ac533fbBB8CDD718071fFB536540abC47);
    address public TWNFT2Address = payable(0x272be07205777975e7AE4a916e13c34ba62617Bd);
    address public TWAddress = payable(0x8dD9e957F3F7DE68bFB8f19452372d6eFcb31f74);
    address public PledgesAddress = payable(0x3E7349A2a9D2dB7CB9b7c08Bc847Da3131A29501);
    
    constructor(string memory _initBaseURI, string memory _initNotRevealedURI, bytes32 _root) ERC721A("Tomorrows World NFT", "TMWN") {
        setBaseURI(_initBaseURI);
		setNotRevealedURI(_initNotRevealedURI);
        presaleMerkleRoot = _root;
        theOwner = msg.sender;
    }

    // ===== Modifiers =====
    modifier whenPrivateMint() {
        require(privateMintStarted, "[Mint Status Error] Private mint not active.");
        _;
    }

    modifier whenPublicMint() {
        require(publicMintStarted, "[Mint Status Error] Public mint not active.");
        _;
    }

     // ===== Dev mint =====
    function devMint(uint8 quantity) external onlyOwner {
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");

        _mint(msg.sender, quantity);        
    }

    // ===== Private mint =====
    function privateMint(bytes32[] memory proof, uint8 quantity) external payable nonReentrant whenPrivateMint {
        require(msg.value >= presaleCost * quantity, "[Value Error] Not enough funds supplied for mint");
        require(totalSupply() + quantity < presaleSupply, "[Supply Error] Not enough left for this mint amount");
        require(_numberMinted(msg.sender) + quantity < presaleMaxItemsPerWallet, "[Holder Error] You have hit the max per wallet amount !");
        require(isAddressWhitelisted(proof, msg.sender), "[Whitelist Error] You are not on the whitelist");

        _mint(msg.sender, quantity);     

        // track mints
        mintCount += quantity;   
    }

    // ===== Public mint =====
    function mint(uint8 quantity) external payable nonReentrant whenPublicMint {
        require(msg.value >= presaleCost * quantity, "[Value Error] Not enough funds supplied for mint");
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");

        _mint(msg.sender, quantity);   

        // track mints
        mintCount += quantity;     

        sendFunds(msg.value);
    }

	// override _startTokenId() function ~ line 100 of ERC721A
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	// override _baseURI() function  ~ line 240 of ERC721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

	// override tokenURI() function ~ line 228 of ERC721A
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		if (revealedState == true) {
			return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
		} else {
			return notRevealedURI;//returns https://ipfs.io/{cid}/notRevealed.json
		}
	}

	// ---Helper Functions / Modifiers---
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

	modifier mintCompliance(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount < maxSupply, "[Supply Error] Not enough left for this mint amount");

        // Check if owner before checking mint status
        if(msg.sender != owner()) {
            if(!privateMintStarted) {
                // check mintActive
                require(publicMintStarted, "[Mint Status Error] Public mint not active.");
            } else {
                require(_numberMinted(msg.sender) + _mintAmount < presaleMaxItemsPerWallet, "[Holder Error] You have hit the max per wallet amount !");
            }
		}
		_;
	}

	modifier mintPriceCompliance(uint256 _mintAmount) {
        // Check if owner before calculating price
        if(msg.sender != owner()) {
            if(!privateMintStarted) {
                // sender has passed >= funds
                require(msg.value >= cost * _mintAmount, "[Value Error] Not enough funds supplied for mint");
            } else {
                require(msg.value >= presaleCost * _mintAmount, "[Value Error] Not enough funds supplied for mint");
            }
		}
		_;
	}

	// sendFunds function
	function sendFunds(uint256 _totalMsgValue) public payable {
		(bool s1,) = payable(TWNFT1Address).call{value: (_totalMsgValue * 20) / 100}("");
		(bool s2,) = payable(TWNFT2Address).call{value: (_totalMsgValue * 20) / 100}("");
		(bool s3,) = payable(TWAddress).call{value: (_totalMsgValue * 25) / 100}("");
		(bool s4,) = payable(PledgesAddress).call{value: (_totalMsgValue * 35) / 100}("");
		require(s1 && s2 && s3 && s4, "Transfer failed.");
	}

    function startPublicMint() external onlyOwner {
        publicMintStarted = true;
        privateMintStarted = false;
    }

    function setPresaleMaxItemsPerWallet(uint8 value) external onlyOwner {
        presaleMaxItemsPerWallet = value;
    }

    function setPresalePrice(uint256 value) external onlyOwner {
        presaleCost = value;
    }

    function setMintPrice(uint256 value) external onlyOwner {
        cost = value;
    }

    function setPresaleMerkleRoot(bytes32 value) external onlyOwner {
        presaleMerkleRoot = value;
    }

	// setBaseURI (must be public)
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

	//setNotRevealedURI
	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedURI = _notRevealedURI;
	}

	// withdraw
	function withdraw() external onlyOwner nonReentrant {
		sendFunds(address(this).balance);
	}

    // check if user is whitelisted
    
    function isAddressWhitelisted(bytes32[] memory proof, address _address) internal view returns (bool) {
        return proof.verify(presaleMerkleRoot, keccak256(abi.encodePacked(_address)));
    }

	// recieve
	receive() external payable {
		sendFunds(address(this).balance);
	}

	// fallback
	fallback() external payable {
		sendFunds(address(this).balance);
	}
    // setRevealState
	function setRevealedState() external onlyOwner {
		revealedState = true;
	}

}