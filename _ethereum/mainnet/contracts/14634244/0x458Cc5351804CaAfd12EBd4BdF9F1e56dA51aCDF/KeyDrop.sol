//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";

interface KeyIERC20 is IERC20 {
	function hasReachedCap() external view returns (bool);

	function mint(address to, uint256 amount) external payable returns (bool);

	function decimals() external view returns (uint8);
}

interface OneClubIERC721 is IERC721 {
	function whiteList(address redeemer) external view returns (uint256);

	function goldList(address redeemer) external view returns (uint256);
}

/** @title Membership Mining Program. */
contract MembershipMiningProgram is ReentrancyGuard, Pausable, Ownable {
	// defensive as not required from pragma ^0.8 onwards
	using SafeMath for uint256;

	// modifier to check if contract has been setup (after deployment)
	modifier isInitialised() {
		require(initialised == true, 'Contract has not yet been initialised');
		_;
	}

	// reward for goldlisters
	uint256 public constant GOLDLIST_CLAIM = 10 * 10**18;
	// cap on maximum amount of whitelist claims
	uint256 public constant WHITELIST_CAP = 500;
	// reward for whitelisters
	uint256 public constant WHITELIST_CLAIM = 6 * 10**18;

	// track amount of whitelisters
	uint256 public whiteListCounter = 0;

	// track initialisation of contract
	bool public initialised = false;

	// $KEY token
	KeyIERC20 public keyToken;
	// $1CLB token
	OneClubIERC721 public nftToken;

	// track claims
	mapping(address => bool) public claimed;

	/** @dev Initialises the contract with depencancies
	 * @param _nftToken address of the $1CLB contract.
	 * @param _keyToken address of the $KEY contract.
	 */
	function initialise(address _nftToken, address _keyToken) public onlyOwner {
		require(initialised == false, 'Contract is already initialised');
		nftToken = OneClubIERC721(_nftToken);
		keyToken = KeyIERC20(_keyToken);
		initialised = true;
	}

	/** @dev Pauses the contract
	 */
	function pause() public onlyOwner {
		_pause();
	}

	/** @dev Unpauses the contract
	 */
	function unpause() public onlyOwner {
		_unpause();
	}

	/** @dev Retrieve eligibility for claim
	 * @param redeemer address to check
	 * @return boolean value
	 */
	function isEligible(address redeemer) public view returns (bool) {
		bool isWhitelisted = nftToken.whiteList(redeemer) > 0;
		bool isGoldlisted = nftToken.goldList(redeemer) > 0;
		bool hasClaimed = claimed[redeemer] == true;
		return
			!keyToken.hasReachedCap() &&
			!hasClaimed &&
			(isWhitelisted || isGoldlisted);
	}

	/** @dev Claim free $KEY allocation
	 */
	function claim(address to) public whenNotPaused isInitialised {
		require(
			msg.sender == address(nftToken),
			'Caller must be $1CLB contract'
		);
		require(claimed[to] == false, 'Caller already claimed');
		bool isWhitelisted = nftToken.whiteList(to) > 0;
		bool isGoldlisted = nftToken.goldList(to) > 0;
		require(isWhitelisted || isGoldlisted, 'Caller has no claim');
		require(!keyToken.hasReachedCap(), 'No more keys left');

		if (isWhitelisted && !isGoldlisted) {
			require(
				whiteListCounter < WHITELIST_CAP,
				'Maximum number of white list claims reached'
			);
		}

		// mint amount of $KEY tokens to sender
		(bool success, bytes memory returnedData) = address(keyToken).call(
			abi.encodeWithSignature(
				'mint(address,uint256)',
				to,
				isGoldlisted ? GOLDLIST_CLAIM : isWhitelisted
					? WHITELIST_CLAIM
					: 0
			)
		);

		require(success, string(returnedData));

		// track claim
		claimed[to] = true;

		// increment whitelist counter to ensure cap
		if (isWhitelisted && !isGoldlisted) {
			whiteListCounter++;
		}
	}
}
