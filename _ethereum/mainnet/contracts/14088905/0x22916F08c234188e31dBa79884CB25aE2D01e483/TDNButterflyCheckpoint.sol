// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC721.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract TDNButterflyCheckpoint is ERC1155Burnable, Ownable {
    using ECDSA for bytes32;

    uint256 public constant GOLD_NINJA_SKULLY = 1;
    uint256 public constant BLUE_NINJA_SKULLY = 2;
    uint256 public constant GIMPDICKBUTT = 3;

    IERC721 public skullies;
    IERC721 public ninjas;

    string private _baseTokenURI = "ipfs://QmTz1MN4D98KJUbA6GpAuRF1KZcYwjTtt3BMEG3KqyuviJ/";
	string private _contractURI = "ipfs://QmTDoeVNzF1bkXAeuJkaA2z5YDiJwc4vg8jQXZtA22xekf";

    bool public mintActive;
    bool public whitelistedMintActive;

    mapping(address => bool) public minted;
    mapping(address => bool) public whitelistMinted;

    address private signerAddress;

    constructor(address _skullies, address _ninjas) ERC1155(_baseTokenURI) {
        skullies = IERC721(_skullies);
        ninjas = IERC721(_ninjas);
    }

    function mintOne() external {
        require(!minted[msg.sender], "already minted");
        require(mintActive, "mint not active");
        
        uint256 skulliesBalance = skullies.balanceOf(msg.sender);

        require(skulliesBalance > 0, "not eligible for mint 1 NFT");
        _mint(msg.sender, GOLD_NINJA_SKULLY, 1, "");

        minted[msg.sender] = true;
    }

    function mintTwo() external {
        require(!minted[msg.sender], "already minted");
        require(mintActive, "mint not active");

        uint256 ninjasBalance = ninjas.balanceOf(msg.sender);

        require(ninjasBalance >= 1 && ninjasBalance < 5, "not eligible to mint 2 NFTs");
        _mint(msg.sender, GOLD_NINJA_SKULLY, 1, "");
        _mint(msg.sender, BLUE_NINJA_SKULLY, 1, "");

        minted[msg.sender] = true;
    }

    function mintAll() external {
        require(!minted[msg.sender], "already minted");
        require(mintActive, "mint not active");

        uint256 ninjasBalance = ninjas.balanceOf(msg.sender);
        require(ninjasBalance >= 5, "not eligible for mint all NFTs");

        _mint(msg.sender, GOLD_NINJA_SKULLY, 1, "");
        _mint(msg.sender, BLUE_NINJA_SKULLY, 1, "");
        _mint(msg.sender, GIMPDICKBUTT, 1, "");
        minted[msg.sender] = true;
    }

    function adminMint(address receiver, uint256 id, uint256 qty) external onlyOwner {
        _mint(receiver, id, qty, "");
    }

    function whitelistedMint(
        bytes memory sig, 
        bytes32 hash,
        uint256 id,
        uint256 qty
    ) external {
        require(qty > 0, "minimum 1 token");
		require(whitelistedMintActive, "mint not live");
        require(!whitelistMinted[msg.sender], "already minted");
		require(matchAddresSigner(hash, sig), "no direct mint");
		require(hashTransaction(msg.sender, id, qty) == hash, "hash check failed");

        _mint(msg.sender, id, qty, "");
        whitelistMinted[msg.sender] = true;
    }

    // mint activation functions
    function setMintActive(bool active) external onlyOwner {
        mintActive = active;
    }

    function setWhitelistedMintActive(bool active) external onlyOwner {
        whitelistedMintActive = active;
    }

    function setSignerAddress(address signer) external onlyOwner {
        signerAddress = signer;
    }

    // set up metadata
    function setBaseURI(string memory URI) public onlyOwner {
		_baseTokenURI = URI;
	}

	function setContractURI(string memory URI) public onlyOwner {
		_contractURI = URI;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseTokenURI, uint2str(tokenId)));
	}

	function contractURI() public view returns(string memory) {
		return _contractURI;
	}

    // utility functions
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
		return signerAddress == hash.recover(signature);
	}

	function hashTransaction(address sender, uint id, uint256 qty) private pure returns(bytes32) {
		bytes32 hash = keccak256(
			abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(sender, id, qty)))
		);
		return hash;
	}

}