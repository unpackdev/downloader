// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

/*
.########.....###....########..##..........###....##....##.########...######.
.##.....##...##.##...##.....##.##.........##.##...###...##.##.....##.##....##
.##.....##..##...##..##.....##.##........##...##..####..##.##.....##.##......
.########..##.....##.##.....##.##.......##.....##.##.##.##.##.....##..######.
.##.....##.#########.##.....##.##.......#########.##..####.##.....##.......##
.##.....##.##.....##.##.....##.##.......##.....##.##...###.##.....##.##....##
.########..##.....##.########..########.##.....##.##....##.########...######.
*/
contract Badlands is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;
	using ECDSA for bytes32;

	string private _baseTokenURI = "https://badlandsapi.azurewebsites.net/metadata/";
	string private _contractURI = "ipfs://QmTJy6wrASiaR4uMHL8Jc99qAnd6e1YXdqpQ9rvFtruiZC";

	uint256 public maxSupply = 10000;
	uint256 public maxPresale = 2000;
	bool public phaseTwoEnabled = false;

	bool public instantRevealActive = false;

	mapping(address => uint256) public usedAddress;

	//----------- Reward System -----------
	uint256 public rewardEndingTime = 0; //unix time
	uint256 public maxFreeNFTperID = 0;
	mapping(uint256 => uint256) public claimedPerID;
	uint256 public maxRewardTokenID = 2000; //early minters reward

	address private _signerAddress = 0x9C4e8753BF0EE1eea2776a2797143F8Aa5AfdD4f; //Backend Signer

	uint256 public pricePerToken = 90000000000000000; //0.09 ETH

	//triggers on gamification event
	event CustomThing(uint256 nftID, uint256 value, uint256 actionID, string payload);

	uint256 public publicAmountMinted;
	bool public saleLive = true;
	bool public presaleLive = true;
	bool public locked;

	constructor() ERC721("Blockchain Badlands", "BAD") {}

	function publicBuy(uint256 qty) external payable {
		require(saleLive, "sale not live");
		require(qty <= 20, "no more than 20 at once");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		require(pricePerToken * qty == msg.value, "exact amount needed");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	function presaleBuy(
		bytes32 hash,
		bytes memory sig,
		uint256 qty
	) external payable nonReentrant {
		require(presaleLive, "presale not live");
		require(matchAddresSigner(hash, sig), "no direct mint");
		require(hashTransaction(msg.sender, qty) == hash, "hash check failed");
		require(totalSupply() + qty <= maxPresale, "presale - out of stock");
		require(pricePerToken * qty == msg.value, "exact amount needed");
		require(qty <= 20, "no more than 20 at once");

		if (!phaseTwoEnabled) {
			require(usedAddress[msg.sender] + qty <= 5, "maximum 5 nfts");
			usedAddress[msg.sender] += qty;
		}

		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	/*
	 * Custom thing
	 */
	function customThing(
		uint256 nftID,
		uint256 id,
		string memory what
	) external payable {
		require(ownerOf(nftID) == msg.sender, "NFT ownership required");
		emit CustomThing(nftID, msg.value, id, what);
	}

	function setSignerAddress(address addr) external onlyOwner {
		_signerAddress = addr;
	}

	function hashTransaction(address sender, uint256 qty) private pure returns (bytes32) {
		bytes32 hash = keccak256(
			abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(sender, qty)))
		);
		return hash;
	}

	function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
		return _signerAddress == hash.recover(signature);
	}

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

	// if reward system is active
	function getReward(uint256 _nftID) public nonReentrant {
		require(_exists(_nftID), "NFT doesn't exist");
		require(ownerOf(_nftID) == msg.sender, "NFT ownership required");
		require(rewardEndingTime >= block.timestamp, "reward period ended");
		require(claimedPerID[_nftID] <= maxFreeNFTperID, "you already claimed");
		require(_nftID < maxRewardTokenID, "nft ID > max reward token ID");

		claimedPerID[_nftID] = claimedPerID[_nftID] + 1; //increase the claimedPerID

		_safeMint(msg.sender, totalSupply() + 1);
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
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		require(!locked, "locked functions");
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function reclaimERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function togglePresaleStatus() external onlyOwner {
		presaleLive = !presaleLive;
	}

	function toggleSaleStatus() external onlyOwner {
		saleLive = !saleLive;
	}

	function changeMaxPresale(uint256 _newMaxPresale) external onlyOwner {
		maxPresale = _newMaxPresale;
	}

	function togglePhaseTwo() external onlyOwner {
		phaseTwoEnabled = !phaseTwoEnabled;
	}

	function toggleInstantReveal() external onlyOwner {
		instantRevealActive = !instantRevealActive;
	}

	function changePrice(uint256 newPrice) external onlyOwner {
		pricePerToken = newPrice;
	}

	//if newTime is in the future, start the reward system [only owner]
	function setRewardEndingTime(uint256 _newTime) external onlyOwner {
		rewardEndingTime = _newTime;
	}

	function setMaxRewardTokenID(uint256 _newLimit) external onlyOwner {
		maxRewardTokenID = _newLimit;
	}

	function setMaxFreeNFTperID(uint256 _newLimit) external onlyOwner {
		maxFreeNFTperID = _newLimit;
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "you can only decrease it");
		maxSupply = newMaxSupply;
	}

	// admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) public onlyOwner {
		require(qty > 0, "minimum 1 token");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(to, totalSupply() + 1);
		}
	}

	// and for the eternity....
	function lockMetadata() external onlyOwner {
		locked = true;
	}
}
