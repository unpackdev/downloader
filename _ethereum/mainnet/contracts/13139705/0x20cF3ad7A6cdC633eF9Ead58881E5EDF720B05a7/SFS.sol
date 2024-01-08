// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

/*
 * Sumatra Fitness Squad smart contract
 */
contract SumatraFitnessSquad is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	//toggle the minting
	bool public isMintingActive = false;

	uint256 public tokenIndex = 0;

	bool public instantRevealActive = false;

	uint256 public maxToMint = 10000;

	//----------- Reward System -----------
	uint256 public rewardEndingTime = 0; //unix time
	uint256 public maxFreeNFTperID = 1;
	mapping(uint256 => uint256) public claimedPerID;

	uint256 public priceForLessThan3 = 65000000000000000; //0.065 ETH each
	uint256 public priceForLessThan10 = 55000000000000000; //0.055 ETH each
	uint256 public priceForGreaterThan10 = 45000000000000000; //0.045 ETH each

	string private _baseTokenURI = "https://sfs.azurewebsites.net/metadata/";
	string private _contractURI = "ipfs://QmXHRRU95sV5VrpDNSYHKSoTvoxrhASEq6iKC8wJamE3am";

	//triggers on gamification event
	event CustomThing(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor() ERC721("Sumatra Fitness Squad", "SFS") {}

	/*
	 * buy max 20 tokens
	 */
	function buy(uint256 amount) public payable nonReentrant {
		require(amount > 0, "minimum 1 token");
		require(amount <= maxToMint - tokenIndex, "greater than max supply");
		require(isMintingActive, "minting is not active");
		require(amount <= 20, "max 20 tokens at once");
		uint256 expectedPrice = 2**256 - 1;
		if (amount >= 10) {
			expectedPrice = amount * priceForGreaterThan10;
		}
		if (amount < 10) {
			expectedPrice = amount * priceForLessThan10;
		}
		if (amount < 3) {
			expectedPrice = amount * priceForLessThan3;
		}

		require(expectedPrice == msg.value, "exact value in ETH needed");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	// if reward system is active
	function getReward(uint256 _nftID) public nonReentrant {
		require(rewardEndingTime >= block.timestamp, "reward period ended");
		require(claimedPerID[_nftID] < maxFreeNFTperID, "you already claimed");
		require(isMintingActive, "minting is not active");

		claimedPerID[_nftID] = claimedPerID[_nftID] + 1; //increase the claimedPerID

		_mintToken(_msgSender());
	}

	/*
	 * In case tokens are not sold, admin can mint them for giveaways, airdrops etc
	 */
	function adminMint(uint256 amount) public onlyOwner {
		require(amount > 0, "minimum 1 token");
		require(amount <= maxToMint - tokenIndex, "amount is greater than the token available");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	/*
	 * Internal mint function
	 */
	function _mintToken(address destinationAddress) private {
		tokenIndex++;
		require(!_exists(tokenIndex), "Token already exist.");
		_safeMint(destinationAddress, tokenIndex);
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

	/*
	 * Helper function
	 */
	function tokensOfOwner(
		address _owner,
		uint256 _start,
		uint256 _limit
	) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = _start; index < _limit; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	//used by admin to modify the price for 1 and 2 quantities[only owner]
	function modifyPriceLessThan3(uint256 _newPrice) public onlyOwner {
		priceForLessThan3 = _newPrice;
	}

	//used by admin to modify the price < 10 [only owner]
	function modifyPriceLessThan10(uint256 _newPrice) public onlyOwner {
		priceForLessThan10 = _newPrice;
	}

	//used by admin to modify the price >= 10 [only owner]
	function modifyPriceGreaterThan10(uint256 _newPrice) public onlyOwner {
		priceForGreaterThan10 = _newPrice;
	}

	//@dev toggle instant Reveal
	function stopInstantReveal() external onlyOwner {
		instantRevealActive = false;
	}

	function startInstantReveal() external onlyOwner {
		instantRevealActive = true;
	}

	/*
	 * Burn...
	 */
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

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	//toggle minting [only owner]
	function stopMinting() external onlyOwner {
		isMintingActive = false;
	}

	//toggle minting [only owner]
	function startMinting() external onlyOwner {
		isMintingActive = true;
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
	}

	// [only owner]
	function setBaseURI(string memory newBaseURI) public onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	// [only owner]
	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	//used by admin to lower the total supply [only owner]
	function lowerTotalSupply(uint256 _newTotalSupply) public onlyOwner {
		require(_newTotalSupply < maxToMint, "keeping it fair");
		maxToMint = _newTotalSupply;
	}

	//if newTime is in the future, start the reward system [only owner]
	function setRewardEndingTime(uint256 _newTime) external onlyOwner {
		rewardEndingTime = _newTime;
	}

	// [only owner]
	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	// [only owner]
	function reclaimERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

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
}
