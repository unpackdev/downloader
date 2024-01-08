// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

contract Beasts is ERC721Enumerable, Ownable {
	using Strings for uint256;

	string private _baseTokenURI = "https://api.hallowedbeasts.com/metadata/";
	string private _contractURI = "ipfs://QmYGvBaMMKPK8M7QXNJLaA8RSKiZtM1mgBj8fx2ptAcF89";

	uint256 public maxSupply = 10000;

	uint256 public pricePerToken = 50000000000000000; //0.05 ETH

	bool public saleLive = false;
	bool public locked; //metadata lock
	address private devWallet;
	string private ipfsProof;

	//should be handled only by highly trained personnel
	modifier onlyDev() {
		require(msg.sender == devWallet, "only dev can modify");
		_;
	}

	constructor() ERC721("Hallowed Beasts", "HB") {
		devWallet = msg.sender;
		transferOwnership(0x4ff302e0271c1bD299EEac2E9fcFcEE0F400f107);
	}

	function publicBuy(uint256 qty) external payable {
		require(saleLive, "not live");
		require(qty <= 20, "no more than 20");
		require(totalSupply() + qty <= maxSupply, "public sale out of stock");
		require(pricePerToken * qty == msg.value, "exact amount needed");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	// admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) public onlyOwner {
		require(qty > 0, "minimum 1 token");
		require(qty <= 20, "no more than 20");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(to, totalSupply() + 1);
		}
	}

	//----------------------------------
	//----------- other code -----------
	//----------------------------------
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function burn(uint256 tokenId) public virtual {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
		_burn(tokenId);
	}

	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) public onlyDev {
		require(!locked, "locked functions");
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyDev {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	// earnings withdrawal
	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function reclaimERC20(IERC20 erc20Token) public onlyDev {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) public onlyDev {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimERC1155(IERC1155 erc1155Token, uint256 id) public onlyDev {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
	}

	function toggleSaleStatus() external onlyOwner {
		saleLive = !saleLive;
	}

	function changePricePerToken(uint256 newPrice) external onlyOwner {
		pricePerToken = newPrice;
	}

	function setProvenance(string memory _ipfsProvenance) external onlyDev {
		bytes memory tempEmptyStringTest = bytes(ipfsProof);
		require(tempEmptyStringTest.length == 0, "ipfsProof already set");
		ipfsProof = _ipfsProvenance;
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "you can only decrease it");
		maxSupply = newMaxSupply;
	}

	// and for the eternity!
	function lockMetadata() external onlyOwner {
		locked = true;
	}
}
