//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract KillerKangarooz is ERC721, Ownable {

    using Strings for uint256;

    uint256 public tokenCount;
    string private baseURI;
    uint256 public publicSalePrice = 0.04 ether;
    uint256 public whitelistPrice = 0.02 ether;
    bool public whitelistSaleIsActive = false;
    bool public publicSaleIsActive = false;
    bytes32 public whitelistMerkleRoot;
    mapping(address => bool) private hasMintedWhitelist;

    address communityWallet = 0x4668C3142ae6cB78BD677a1e5d27053C90881008;
    
    constructor() ERC721("Killer Kangarooz", "KK") {
        baseURI = "ipfs://QmPHqEymyX9YrVpJEuPLPjQTfkNgHWT7LEZxU366pxAbo4";

        for (uint256 i; i < 3; i++) {
            tokenCount++;
            _safeMint(communityWallet, tokenCount);
        }
    }

    function _verify(
		bytes32[] memory proof,
		bytes32 merkleRoot
        ) internal view returns (bool) {
		return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
	}

    function mint(uint256 amount)
        external
        payable
    {
        require(publicSaleIsActive, "Public sale is not active");
        require(msg.value == publicSalePrice * amount, "Incorrect ETH value sent");
        require(amount < 11, "Cannot mint more than 10");
        require(tokenCount + amount <= 5000, "Max limit exceeded");

        for (uint256 i; i < amount; i++) {
            tokenCount++;
            _safeMint(msg.sender, tokenCount);
        }
    }

    function mintWhitelist(uint256 amount, bytes32[] calldata proof)
        external
        payable
    {
        require(whitelistSaleIsActive, "Whitelist sale is not active");
        require(!hasMintedWhitelist[msg.sender], "User has already minted");
        require(msg.value == whitelistPrice * amount, "Incorrect ETH value sent");
        require(amount < 6, "Cannot mint more than 5");
        require(tokenCount + amount <= 5000, "Max limit exceeded");
        require(_verify(proof, whitelistMerkleRoot), "Invalid proof");

        hasMintedWhitelist[msg.sender] = true;

        for (uint256 i; i < amount; i++) {
            tokenCount++;
            _safeMint(msg.sender, tokenCount);
        }
    }
    
    function setPublicSaleIsActive(bool _state) public onlyOwner {
		publicSaleIsActive = _state;
	}

    function setWhitelistSaleIsActive(bool _state) public onlyOwner {
		whitelistSaleIsActive = _state;
	}

    function setWhitelistMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function withdraw() public payable onlyOwner {
		(bool success, ) = communityWallet.call{value: address(this).balance}("");
		require(success);
	}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }
}