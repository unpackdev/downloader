// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";

contract OCG is ERC721Enumerable, Ownable {
	using Strings for uint256;
	using MerkleProof for bytes32[];

	/**
	 * @notice Input data root, Merkle tree root for an array of (address, tokenId) pairs,
	 *      available for minting
	 */
	bytes32 public root;

	string public _contractBaseURI = "https://api.ocg.city/metadata/";
	string public _contractURI = "https://to.wtf/contract_uri/ocg/contract_uri.json";
	address private devWallet;
	uint256 public tokenPrice = 0.07 ether;
	uint256 public pricePerTokenPresale = 0.05 ether;
	bool public locked; //metadata lock
	uint256 public maxSupply = 5555;
	uint256 public maxSupplyPresale = 3333;

	uint256 public presaleStartTime = 1638295200; //update to correct
	uint256 public saleStartTime = 1638381600; //update to correct

	modifier onlyDev() {
		require(msg.sender == devWallet, "only dev");
		_;
	}

	constructor() ERC721("OCG", "OCG") {
		devWallet = msg.sender;
	}

	//whitelistBuy can buy
	function whitelistBuy(
		uint256 qty,
		uint256 tokenId,
		bytes32[] calldata proof
	) external payable {
		require(isTokenValid(msg.sender, tokenId, proof), "invalid proof");
		require(pricePerTokenPresale * qty == msg.value, "exact amount needed");
		require(block.timestamp >= presaleStartTime, "not live");
		require(totalSupply() + qty <= maxSupplyPresale, "presale out of stock");

		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	//regular public sale
	function buy(uint256 qty) external payable {
		require(qty <= 10, "max 10 at once");
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(block.timestamp >= saleStartTime, "not live");
		require(totalSupply() + qty <= maxSupply, "public sale out of stock");

		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	function isTokenValid(
		address _to,
		uint256 _tokenId,
		bytes32[] memory _proof
	) public view returns (bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));

		// verify the proof supplied, and return the verification result
		return _proof.verify(root, leaf);
	}

	function setMerkleRoot(bytes32 _root) external onlyDev {
		root = _root;
	}

	// admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) external onlyOwner {
		require(qty <= 10, "no more than 10");
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
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) external onlyDev {
		require(!locked, "locked functions");
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newuri) external onlyDev {
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

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimERC1155(IERC1155 erc1155Token, uint256 id) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
	}

	//in unix
	function setPresaleStartTime(uint256 _presaleStartTime) external onlyOwner {
		presaleStartTime = _presaleStartTime;
	}

	//in unix
	function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
		saleStartTime = _saleStartTime;
	}

	function changePricePerToken(uint256 newPrice) external onlyOwner {
		tokenPrice = newPrice;
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "decrease only");
		maxSupply = newMaxSupply;
	}

	function decreaseMaxPresaleSupply(uint256 newMaxPresaleSupply) external onlyOwner {
		require(newMaxPresaleSupply < maxSupplyPresale, "decrease only");
		maxSupplyPresale = newMaxPresaleSupply;
	}

	// and for the eternity!
	function lockMetadata() external onlyDev {
		locked = true;
	}
}
