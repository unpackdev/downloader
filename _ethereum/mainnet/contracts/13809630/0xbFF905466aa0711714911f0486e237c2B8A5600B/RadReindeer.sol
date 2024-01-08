// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";

contract RadReindeer is ERC721Enumerable, Ownable, PaymentSplitter {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];
	using Counters for Counters.Counter;

	bytes32 public root; //merkle

	string public _contractBaseURI = "https://metadata-live.radreindeer.com/v1/metadata/";
	string public _contractURI = "ipfs://QmX8tvc1MKv8Ejnai7g32R6s5KKDUSfUjFDtu5CnFj35kY";
	address private devWallet;
	uint256 public tokenPrice = 0.035 ether;
	mapping(address => uint256) public usedAddresses; //max 3 per address for whitelist
	bool public locked; //metadata lock
	uint256 public maxSupply = 8000;
	uint256 public maxSupplyPresale = 3000;

	uint256 public presaleStartTime = 1639893600;
	uint256 public saleStartTime = 1639980000;

	address[] private addressList = [
		0x7695Ae3c76eA84b6A6b66Dc124e7b7Fe864e2423, //n
		0xB56b7DE403Cad004B02f67474043E7972049E3E1, //n's p
		0x415365B365d618aceA382Dd9A2eb5cDAd59f5Adc //a
	];
	uint256[] private shareList = [89, 10, 1];

	Counters.Counter private _tokenIds;

	//----------- Reward System ----------- //only used in case of emergency
	uint256 public rewardEndingTime = 0; //unix time
	uint256 public maxRewardTokenID = 2000; //can claim if you have < this tokenID
	uint256 public maxFreeNFTperID = 1;
	mapping(uint256 => uint256) public claimedPerID;

	modifier onlyDev() {
		require(msg.sender == devWallet, "only dev");
		_;
	}

	constructor() ERC721("Rad Reindeer", "RADR") PaymentSplitter(addressList, shareList) {
		devWallet = msg.sender;
	}

	//whitelistBuy can buy. max 3 tokens per whitelisted address
	function whitelistBuy(
		uint256 qty,
		uint256 tokenId,
		bytes32[] calldata proof
	) external payable {
		require(isTokenValid(msg.sender, tokenId, proof), "invalid proof");
		require(usedAddresses[msg.sender] + qty <= 3, "max 3 per wallet");
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(block.timestamp >= presaleStartTime, "not live");
		require(_tokenIds.current() + qty <= maxSupplyPresale, "whitelist sale out of stock");

		usedAddresses[msg.sender] += qty;

		for (uint256 i = 0; i < qty; i++) {
			_tokenIds.increment();
			_safeMint(msg.sender, _tokenIds.current());
		}
	}

	//regular public sale
	function buy(uint256 qty) external payable {
		require(qty <= 20, "max 20 at once");
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(block.timestamp >= saleStartTime, "not live");
		require(_tokenIds.current() + qty <= maxSupply, "public sale out of stock");

		for (uint256 i = 0; i < qty; i++) {
			_tokenIds.increment();
			_safeMint(msg.sender, _tokenIds.current());
		}
	}

	// if reward system is active
	function claimReward(uint256 _nftID) external {
		require(rewardEndingTime >= block.timestamp, "reward period not active");
		require(rewardEndingTime != 0, "reward period not set");
		require(claimedPerID[_nftID] < maxFreeNFTperID, "you already claimed");
		require(block.timestamp >= saleStartTime, "sale not live");
		require(ownerOf(_nftID) == msg.sender, "ownership required");
		require(_nftID <= maxRewardTokenID, "nftID not in range");

		claimedPerID[_nftID] = claimedPerID[_nftID] + 1; //increase the claimedPerID

		_tokenIds.increment();
		_safeMint(msg.sender, _tokenIds.current());
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
		require(_tokenIds.current() + qty <= maxSupply, "out of stock");
		for (uint256 i = 0; i < qty; i++) {
			_tokenIds.increment();
			_safeMint(to, _tokenIds.current());
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

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimERC1155(
		IERC1155 erc1155Token,
		uint256 id,
		uint256 amount
	) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, amount, "");
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
	function lockBaseURIandContractURI() external onlyDev {
		locked = true;
	}

	//if newTime is in the future, start the reward system [only owner]
	function setRewardEndingTime(uint256 _newTime) external onlyOwner {
		rewardEndingTime = _newTime;
	}

	//can claim if < maxRewardTokenID
	function setMaxRewardTokenID(uint256 _newMax) external onlyOwner {
		maxRewardTokenID = _newMax;
	}
}
