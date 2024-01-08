// SPDX-License-Identifier: GPL-3.0
/* 
	Baushaus: https://www.baushaus.xyz/
*/
pragma solidity ^0.8.4;
import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract Louka is ERC721Enum, Ownable, PaymentSplitter, ReentrancyGuard, Pausable {
	using Strings for uint256;
	string public baseURI;
	//sale settings
	uint256 public maxMint = 10;
	uint256 public cost = 0.04 ether;
	uint256 public maxSupply = 500;
	bool public status = false;
	//share settings
	address[] private addressList = [
		// dev wallet
		0x48D2a000DcC70f09304c8c84f7a4B27758A93308,
		// owner wallet
		0x35Bd4D479ec88be9F1F9B6A6a6A488975669f5Cc
	];
	uint[] private shareList = [15,85];
	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initBaseURI
	) ERC721(_name, _symbol)
	PaymentSplitter( addressList, shareList ) {
		setBaseURI(_initBaseURI);
		pause();
	}

	function _baseURI() internal view virtual returns (string memory) {
		return baseURI;
	}

	function adminMint(uint256 _mintAmount) external nonReentrant onlyOwner {
		uint256 s = totalSupply();
		for (uint256 i = 0; i < _mintAmount; ++i) {
			_safeMint(msg.sender, s + i, "");
		}
	}

	function mint(uint256 _mintAmount) external payable nonReentrant whenNotPaused {
		uint256 s = totalSupply();
		require(_mintAmount > 0, "must be greater than zero");
		require(s < maxSupply, "Sold out");
		require(_mintAmount <= maxMint, "Exceeds max" );
		require(msg.value >= cost * _mintAmount, "Incorrect Eth");
		for (uint256 i = 0; i < _mintAmount; ++i) {
			_safeMint(msg.sender, s + i, "");
		}
		delete s;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
	}

	function setCost(uint256 _newCost) public onlyOwner {
		cost = _newCost;
	}

	function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
		maxSupply = _newMaxSupply;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
		maxMint = _newMaxMintAmount;
	}

	function withdraw() public payable onlyOwner {
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

	function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }
}
