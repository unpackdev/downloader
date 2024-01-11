// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC2981.sol";
import "./ReentrancyGuard.sol";

contract YetiLabzQuartak is ERC721A, Ownable, ReentrancyGuard {

    bytes32 public root;
    address private royaltyAddress = 0x7C366E27a52B4cfD44197cb60D0cBa3Ed1Ff6DDD;
    uint96 private royaltyBasisPoints = 700;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public maxPerWallet = 50;
    uint256 public mintRate = 0.0001 ether;
    uint public MAX_SUPPLY = 700;
    bool public revealed = false;
    bool public whitelist = true;

    string public contractURI = "ipfs://QmfRuZ24VMfGcZKdTDhufyAiyY2TKh9QT9TU6WiPH9dGbC";
    string public baseURI = "ipfs://QmSe8UVmVqbfg2HM9Mib8UZbog22xsNU6mMs7W8jg5xeCH/";

    constructor() ERC721A("YetiLabz Quartak", "YLZ") {
	}
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
			require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
			string memory baseURI_ = _baseURI();

			if (revealed) {
					return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
			} else {
					return string(abi.encodePacked(baseURI_, "pre-reveal.json"));
			}
	}

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
		return MerkleProof.verify(proof, root, leaf);
	}
	
    function setRoot(bytes32 root_) public onlyOwner {
			root = root_;
	}

	function setContractURI(string memory contractURI_) public onlyOwner {
			contractURI = contractURI_;
	}

	function setRevealed(bool _revealed) public onlyOwner {
			revealed = _revealed;
	}

    function setWhitelist(bool _whitelist) public onlyOwner {
			whitelist = _whitelist;
	}

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }
    
    function setMintrate(uint256 mintRate_)  public onlyOwner {
			mintRate = mintRate_;
	}

    function setMaxPerWallet(uint256 maxPerWallet_)  public onlyOwner {
			maxPerWallet = maxPerWallet_;
	}

    function _baseURI() internal view override returns (string memory) {
			return baseURI;
	}

	function setBaseURI(string memory baseURI_) public onlyOwner {
			baseURI = baseURI_;
	}

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function withdraw() public onlyOwner {
		require(address(this).balance > 0, "Balance is 0"); 
		payable(owner()).transfer(address(this).balance);
	}

    function safeMint(address to, uint256 quantity, bytes32[] memory proof) nonReentrant external payable {
		require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
		require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        require(balanceOf(msg.sender) + quantity <= maxPerWallet, "mints per wallet exceeded");

        if (whitelist) {
            require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not in Whitelist");
		} 
		
        _safeMint(to, quantity);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }
}
