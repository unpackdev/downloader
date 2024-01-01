// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

import "./SonaAdmin.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProofLib.sol";
import "./SonaRewardToken.sol";
import "./IERC20Upgradeable.sol";
import "./ISplitMain.sol";
import "./IRewardGateway.sol";
import "./IWETH.sol";
import "./Initializable.sol";
import "./ZeroCheck.sol";

/// @title SonaRewards
/// @author @SonaEngineering
/// @notice The interface for Track Collectors and Artists to claim Rewards
contract SonaRewards is Initializable, SonaAdmin {
	using MerkleProofLib for bytes32[];
	using ZeroCheck for address;
	using ZeroCheck for address payable;
	/*//////////////////////////////////////////////////////////////
		STRUCTS
	//////////////////////////////////////////////////////////////*/

	struct RewardRoot {
		bytes32 hash;
		uint64 start;
		uint64 end;
	}

	/*//////////////////////////////////////////////////////////////
		MAPPINGS
	//////////////////////////////////////////////////////////////*/

	/// @notice A pseudo-array to hold each publish merkle root
	/// @dev This is a cleaner storage pattern for upgradable contracts compared to an actual array
	mapping(uint256 => RewardRoot) public rewardRoots;

	/// @notice the unix epoch timestamp representing the end of last period rewards were claimed for a given tokenId
	/// @dev this value can only monotonically increase, in order to prevent double claims
	mapping(uint256 => uint256) public amountClaimed;

	/*//////////////////////////////////////////////////////////////
		STATE
	//////////////////////////////////////////////////////////////*/

	/// @notice The id of the last RewardRoot published
	uint256 public lastRootId;

	address private _rewardVault;
	SonaRewardToken private _sonaRewardToken;
	IERC20 private _paymentToken;
	IWETH private _wETHToken;
	string private _claimLookupUrl;
	ISplitMain private _splitMain;

	/*//////////////////////////////////////////////////////////////
		EVENTS
	//////////////////////////////////////////////////////////////*/
	event IntegrationsUpdated(
		address sonaRewardToken,
		address paymentToken,
		address wETHToken,
		address rewardVault,
		string claimLookupUrl,
		ISplitMain splitMain
	);

	event RewardRootCreated(
		uint256 indexed rootId,
		bytes32 indexed hash,
		uint64 start,
		uint64 end
	);
	event RewardRootInvalidated(uint256 indexed rootId);

	event RewardsClaimed(
		uint256 indexed tokenId,
		address indexed claimant,
		uint256 indexed rootId,
		uint256 amount
	);
	/*//////////////////////////////////////////////////////////////
		ERRORS
	//////////////////////////////////////////////////////////////*/

	error RootNonexistent(uint256 rootId);
	error ClaimantNotHolder(address claimant, uint256 tokenId);
	error ClaimLengthMismatch();
	error InvalidProof();
	error InvalidClaimAttempt();
	error StartNotBeforeEnd(uint64 start, uint64 end);
	error RewardTransferFailed();
	error InvalidTokenInputs(address paymentToken, address wETHToken);
	error OffchainLookup(
		address sender,
		string[] urls,
		bytes callData,
		bytes4 callbackFunction,
		bytes extraData
	);

	/*//////////////////////////////////////////////////////////////
		CONSTRUCTOR
	//////////////////////////////////////////////////////////////*/

	/// @dev a proxiable base contract should not be initializable
	constructor() {
		_disableInitializers();
	}

	/// @notice the constructor-like function used for proxy contracts
	/// @dev Pass in either a non-zero paymentToken_ or wETHToken_ param. One and only one should be non-zero
	/// @param _eoaAdmin The administrator of proxy upgrades and RewardRoots
	/// @param sonaRewardToken_ The address of the SonaRewardToken NFT smart contract
	/// @param paymentToken_ The address of the reward token Collectors and Artists earn
	/// @param wETHToken_ The address of the wETH token if Collectors and Artists earn ETH
	/// @param rewardVault_ The holder of the reward token that has granted this contract enough of an allowance to operate
	/// @param claimLookupUrl_ The templated url returned via `OffchainLookup`. Must be EIP-3668 compliant
	function initialize(
		address _eoaAdmin,
		SonaRewardToken sonaRewardToken_,
		IERC20 paymentToken_,
		IWETH wETHToken_,
		address rewardVault_,
		string calldata claimLookupUrl_,
		ISplitMain splitMain_
	) public initializer {
		_setupRole(_ADMIN_ROLE, _eoaAdmin);
		_setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);

		_updateIntegrations(
			sonaRewardToken_,
			paymentToken_,
			wETHToken_,
			rewardVault_,
			claimLookupUrl_,
			splitMain_
		);
	}

	/*//////////////////////////////////////////////////////////////
		External Functions
	//////////////////////////////////////////////////////////////*/

	// receive function

	/// @dev only accept ETH from our registered `_wETHToken`
	receive() external payable {
		if (msg.sender != address(_wETHToken)) {
			revert();
		}
	}

	// Mint Roots

	/// @notice publish a merkle tree root and allow Reward claims
	/// @dev the subsequent start time should be equal to the last published end time for given period
	/// @param _root The hash of the merkle root to submit proofs against.
	/// @param _start The epoch start time (in seconds) for the reward period
	/// @param _end The epoch end time (in seconds) for the reward period
	function addRoot(
		bytes32 _root,
		uint64 _start,
		uint64 _end
	) public onlySonaAdmin {
		if (!(_start < _end)) revert StartNotBeforeEnd(_start, _end);
		unchecked {
			++lastRootId;
		}
		rewardRoots[lastRootId] = RewardRoot(_root, _start, _end);
		emit RewardRootCreated(lastRootId, _root, _start, _end);
	}

	/// @notice prevent claims against a published root
	/// @param _rootId The index number representing the root to be invalidated
	function invalidateRoot(uint256 _rootId) public onlySonaAdmin {
		if (_rootId > lastRootId) revert RootNonexistent(_rootId);
		rewardRoots[_rootId].hash = bytes32(type(uint256).max);
		emit RewardRootInvalidated(_rootId);
	}

	// Claim Funds

	/// @notice get the api endpoint and request payload to get merkle claim info
	/// @dev this should always revert and allows for a fast preflight response
	/// @param _tokenId The SonaRewardToken token ID
	/// @param _start The beginning of the time period to collect rewards for
	/// @param _end The end of the time period to collect rewards for
	function claimLookup(
		uint256 _tokenId,
		uint64 _start,
		uint64 _end
	) public view {
		string[] memory urls = new string[](1);
		urls[0] = _claimLookupUrl;
		revert OffchainLookup(
			address(this),
			urls,
			abi.encodeWithSelector(
				IRewardGateway.getRewardsforPeriod.selector,
				_tokenId,
				_start,
				_end
			),
			this.claimRewards.selector,
			""
		);
	}

	/// @notice collect tokens by presenting valid proofs and owning SONA number `_tokenId`
	/// @param _tokenId The SonaRewardToken for which rewards are being claimed
	/// @param _rootId the index number of the root to prove against
	/// @param _proofs the proofs to present with the claim
	/// @param _amount the quantity of tokens to be claimed
	function claimRewards(
		uint256 _tokenId,
		uint256 _rootId,
		bytes32[] calldata _proofs,
		uint256 _amount
	) public {
		_claimRewardsOne(_tokenId, _rootId, _proofs, _amount);
	}

	/// @notice collect rewards for SONA number `_tokenId` and distribute through a split
	/// @param _tokenId The SonaRewardToken for which rewards are being claimed
	/// @param _rootId the index number of the root to prove against
	/// @param _proofs the proofs to present with the claim
	/// @param _amount the quantity of tokens to be claimed
	/// @param _accounts the addresses in a split
	/// @param _percentAllocations the shares each account has in a split
	function claimRewardsAndDistributePayout(
		uint256 _tokenId,
		uint256 _rootId,
		bytes32[] calldata _proofs,
		uint256 _amount,
		address[] calldata _accounts,
		uint32[] calldata _percentAllocations
	) public {
		_claimRewardsOne(_tokenId, _rootId, _proofs, _amount);

		address payable payout = _getPayoutAddress(_tokenId, msg.sender);

		if (address(_paymentToken).isZero()) {
			_splitMain.distributeETH(payout, _accounts, _percentAllocations);
		} else {
			_splitMain.distributeERC20(
				payout,
				IERC20(_paymentToken),
				_accounts,
				_percentAllocations
			);
		}
	}

	/// @notice the contract owner can update state variables
	/// @param sonaRewardToken_ The address of the SonaRewardToken NFT smart contract
	/// @param paymentToken_ The address of the reward token Collectors and Artists earn
	/// @param wETHToken_ The address of the wETH token if Collectors and Artists earn ETH
	/// @param rewardVault_ The holder of the reward token that has granted this contract enough of an allowance to operate
	/// @param claimLookupUrl_ The templated url returned via `OffchainLookup`. Must be EIP-3668 compliant
	function updateIntegrations(
		SonaRewardToken sonaRewardToken_,
		IERC20 paymentToken_,
		IWETH wETHToken_,
		address rewardVault_,
		string calldata claimLookupUrl_,
		ISplitMain splitMain_
	) public onlySonaAdmin {
		_updateIntegrations(
			sonaRewardToken_,
			paymentToken_,
			wETHToken_,
			rewardVault_,
			claimLookupUrl_,
			splitMain_
		);
	}

	/*//////////////////////////////////////////////////////////////
		Internal Functions
	//////////////////////////////////////////////////////////////*/
	function _verifyClaim(
		uint256 _tokenId,
		uint256 _rootId,
		bytes32[] calldata _proof,
		uint256 _amount
	) internal returns (uint256 transferAmount) {
		RewardRoot storage root = rewardRoots[_rootId];
		uint256 amountClaimedPrior = amountClaimed[_tokenId];
		if (_amount <= amountClaimedPrior) revert InvalidClaimAttempt();
		bytes32 leaf = keccak256(
			bytes.concat(
				keccak256(abi.encode(_tokenId, _amount, root.start, root.end))
			)
		);
		if (_proof.verify(root.hash, leaf)) {
			amountClaimed[_tokenId] = _amount; // prevent reentrancy by updating this before transfer
			transferAmount = _amount - amountClaimedPrior;
			emit RewardsClaimed(_tokenId, msg.sender, _rootId, transferAmount);
			return transferAmount;
		}
		revert InvalidProof();
	}

	/// @notice collect tokens by presenting valid proofs and owning token number `_tokenId`
	/// @param _tokenId The SonaRewardToken for which rewards are being claimed
	/// @param _rootId the index numbers of the roots to prove against
	/// @param _proofs the proofs for each respective root
	/// @param _amount the amounts to be claimed from each respective root
	function _claimRewardsOne(
		uint256 _tokenId,
		uint256 _rootId,
		bytes32[] calldata _proofs,
		uint256 _amount
	) internal {
		if (_sonaRewardToken.ownerOf(_tokenId) != msg.sender)
			revert ClaimantNotHolder(msg.sender, _tokenId);
		uint256 transferAmount = _verifyClaim(_tokenId, _rootId, _proofs, _amount);
		address payoutAddress = _getPayoutAddress(_tokenId, msg.sender);
		if (address(_paymentToken).isNotZero()) {
			if (
				!_paymentToken.transferFrom(_rewardVault, payoutAddress, transferAmount)
			) revert RewardTransferFailed();
		} else {
			if (!_wETHToken.transferFrom(_rewardVault, address(this), transferAmount))
				revert RewardTransferFailed();
			_wETHToken.withdraw(transferAmount);
			payable(payoutAddress).transfer(transferAmount);
		}
	}

	function _updateIntegrations(
		SonaRewardToken sonaRewardToken_,
		IERC20 paymentToken_,
		IWETH wETHToken_,
		address rewardVault_,
		string calldata claimLookupUrl_,
		ISplitMain splitMain_
	) internal {
		if (
			(address(paymentToken_).isNotZero() && address(wETHToken_).isNotZero()) ||
			address(paymentToken_) == address(wETHToken_)
		) {
			revert InvalidTokenInputs(address(paymentToken_), address(wETHToken_));
		}
		_sonaRewardToken = sonaRewardToken_;
		_paymentToken = paymentToken_;
		_wETHToken = wETHToken_;
		_rewardVault = rewardVault_;
		_claimLookupUrl = claimLookupUrl_;
		_splitMain = splitMain_;
		emit IntegrationsUpdated(
			address(sonaRewardToken_),
			address(paymentToken_),
			address(wETHToken_),
			rewardVault_,
			claimLookupUrl_,
			splitMain_
		);
	}

	function _getPayoutAddress(
		uint256 _tokenId,
		address _holder
	) internal view returns (address payable payoutAddress) {
		address payable payout = _sonaRewardToken.getRewardTokenPayoutAddr(
			_tokenId
		);
		return payout.isNotZero() ? payout : payable(_holder);
	}
}
