// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract AlfheimLandsGenesis is ERC721A, Ownable {
	using Strings for uint256;

	uint256 public MAX_SUPPLY = 525;
	uint256 public FREE_PER_WALLET = 0;
	uint256 public MAX_PER_TX = 1;
	uint256 public MAX_PER_WALLET = 1;
	uint256 public price = 0.01 ether;

	bool public mintable = false;
	bool public blindbox = true;

	string private baseTokenURI;
	string private boxURI;

	constructor() ERC721A("AlfheimLands Genesis", "ALG") {
	}

    function mint(uint256 _count) external payable {
		uint256 supply = totalSupply();
		uint256 mintedByAddress = _numberMinted(_msgSender());

		require(mintable,  "Mint is not available yet");
		require(supply + _count <= MAX_SUPPLY, "Exceeds maximum supply");
		require(_count <= MAX_PER_TX, "Exceeds max per transaction");
		require(_count <= (MAX_PER_WALLET - mintedByAddress), "Exceeds max per wallet");

		if ( mintedByAddress < FREE_PER_WALLET && _count <= (FREE_PER_WALLET - mintedByAddress)  ) {
		    require(msg.value == 0, "Ether sent is incorrect");
		}
		else if (mintedByAddress >= FREE_PER_WALLET) {
		    require(msg.value == price * _count, "Ether sent is incorrect");
		}
		else {
		    require(msg.value == price * ( _count + mintedByAddress - FREE_PER_WALLET), "Ether sent is incorrect");
		}

		_safeMint(msg.sender, _count);
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(blindbox) {
        	return boxURI;
        }
        else {
        	string memory baseURI = _baseURI();
        	return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        }
    }

	function _baseURI() internal view override returns (string memory) {
		return baseTokenURI;
	}

    function flipMintable() external onlyOwner {
        mintable = !mintable;
	}

	function flipBlindBox() external onlyOwner {
		blindbox = !blindbox;
	}

	function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
	    baseTokenURI = _baseTokenURI;
	}

	function setBoxURI(string memory _boxURI) public onlyOwner {
	    boxURI = _boxURI;
	}

	function setMaxFree(uint256 _supply) public onlyOwner {
	    FREE_PER_WALLET = _supply;
	}

	function setPrice(uint256 _newPrice) external onlyOwner {
	    price = _newPrice;
	}

	function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
		MAX_PER_WALLET = _maxPerWallet;
	}

	function setMaxPerTx(uint256 _maxPerTX) external onlyOwner {
		MAX_PER_TX = _maxPerTX;
	}

	function burnTokens() public onlyOwner {
	    MAX_SUPPLY = totalSupply();
	}

	function withdraw() external onlyOwner {
		(bool success, ) = payable(_msgSender()).call{value: address(this).balance}("");
		require(success);
    }
}
