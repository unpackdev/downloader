// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155Receiver.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./ICatGems.sol";

contract CatGemsRewards is Ownable, Pausable, ReentrancyGuard {
	using Address for address payable;

	mapping(address => uint256) allowedNFTs; //contract - emissionRate

	mapping(bytes32 => uint256) public lastClaim;

	ICatGems public catGems;

	event RewardPaid(address indexed to, uint256 reward);

	constructor() {}

	function claim(uint256 _tokenId, address _nftContract) external nonReentrant {
		require(allowedNFTs[_nftContract] > 0, "contract not allowed");

		require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "not owning the nft");

		uint256 unclaimed = unclaimedRewards(_tokenId, _nftContract);

		bytes32 lastClaimKey = keccak256(abi.encode(_tokenId, _nftContract));
		lastClaim[lastClaimKey] = block.timestamp;

		emit RewardPaid(msg.sender, unclaimed);
		catGems.mint(msg.sender, unclaimed);
	}

	//like claim, but for many
	function claimRewards(uint256[] calldata _tokenIds, address[] memory _nftContracts)
		external
		nonReentrant
	{
		require(_tokenIds.length == _nftContracts.length, "invalid array lengths");

		uint256 totalUnclaimedRewards = 0;

		for (uint256 i = 0; i < _tokenIds.length; i++) {
			require(allowedNFTs[_nftContracts[i]] > 0, "contract not allowed");

			require(IERC721(_nftContracts[i]).ownerOf(_tokenIds[i]) == msg.sender, "not owning the nft");

			uint256 unclaimed = unclaimedRewards(_tokenIds[i], _nftContracts[i]);

			bytes32 lastClaimKey = keccak256(abi.encode(_tokenIds[i], _nftContracts[i]));
			lastClaim[lastClaimKey] = block.timestamp;

			totalUnclaimedRewards = totalUnclaimedRewards + unclaimed;
		}

		emit RewardPaid(msg.sender, totalUnclaimedRewards);
		catGems.mint(msg.sender, totalUnclaimedRewards);
	}

	//calculate unclaimed rewards for a token
	function unclaimedRewards(uint256 _tokenId, address _nftContract) public view returns (uint256) {
		uint256 lastClaimDate = getLastClaimedTime(_tokenId, _nftContract);
		uint256 emissionRate = allowedNFTs[_nftContract];

		//initial issuance?
		if (lastClaimDate == uint256(0)) {
			return 50000000000000000000; // 50 $CATGEM
		}

		//there was a claim
		require(block.timestamp > lastClaimDate, "must be smaller than block timestamp");

		uint256 secondsElapsed = block.timestamp - lastClaimDate;
		uint256 accumulatedReward = (secondsElapsed * emissionRate) / 1 days;
		return accumulatedReward;
	}

	//calculate unclaimed rewards for more
	function unclaimedRewardsBulk(uint256[] calldata _tokenIds, address[] memory _nftContracts)
		public
		view
		returns (uint256)
	{
		uint256 accumulatedReward = 0;
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			accumulatedReward = accumulatedReward + unclaimedRewards(_tokenIds[i], _nftContracts[i]);
		}
		return accumulatedReward;
	}

	/**
	 *	==============================
	 *  ~~~~~~~ READ FUNCTIONS ~~~~~~
	 *  ==============================
	 **/
	function getLastClaimedTime(uint256 _tokenId, address _contractAddress)
		public
		view
		returns (uint256)
	{
		bytes32 lastClaimKey = keccak256(abi.encode(_tokenId, _contractAddress));

		return lastClaim[lastClaimKey];
	}

	/**
	 *	==============================
	 *  ~~~~~~~ ADMIN FUNCTIONS ~~~~~~
	 *  ==============================
	 **/
	function setCatGemsToken(address _contract) external onlyOwner {
		catGems = ICatGems(_contract);
	}

	//stake only from this tokens
	function setAllowedNFTs(address _contractAddress, uint256 _emissionRate) external onlyOwner {
		allowedNFTs[_contractAddress] = _emissionRate;
	}

	//blocks staking but doesn't block unstaking / claiming
	function setPaused(bool _setPaused) public onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	function reclaimERC20(IERC20 token, uint256 _amount) external onlyOwner {
		uint256 balance = token.balanceOf(address(this));
		require(_amount <= balance, "incorrect amount");
		token.transfer(msg.sender, _amount);
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

	//owner can withdraw any ETH sent here //not used
	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}
