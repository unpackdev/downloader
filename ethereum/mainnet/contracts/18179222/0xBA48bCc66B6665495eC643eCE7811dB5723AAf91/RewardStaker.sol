// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import { 
	ISuperVerseStaker 
} from  "./interfaces/ISuperVerseStaker.sol";
import "./EIP712.sol";

error InvalidSignature ();
error AlreadyClaimed ();
error SweepingTransferFailed ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title 	SuperVerseDAO Gem Rewards Claim and Staking
	@author 0xthrpw <
	@author Tim Clancy <tim-clancy.eth>
	@author Rostislav Khlebnikov <@catpic5buck>

	This contract allows users to claim a reward proportional to the amount of 
	GEMS they had in the now deprecated SuperFarm GemStaker contract.  All 
	rewards are automatically staked in the SuperVerseStaker.

	@custom:date June 20th, 2023.
*/

contract RewardStaker is
	EIP712, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	/// A constant hash of the claim operation's signature.
	bytes32 constant public CLAIM_TYPEHASH = keccak256(
		"claim(address _claimant,address _asset,uint256 _amount)"
	);

	/// The name of the vault.
	string public name;

	/// The address permitted to sign claim signatures.
	address public immutable signer;

	/// The address of the staker.
	address public immutable staker;

	/// The address of the reward token.
	address public immutable rewardToken;

	/// A mapping for whether or not a specific claimant has claimed.
	mapping ( address => bool ) public claimed;

	/**
		An event emitted when a claimant claims tokens.

		@param claimant The address of the user receiving the tokens.
		@param caller The caller who claimed the tokens.
		@param amount The amount of tokens claimed.
	*/
	event Claimed (
		address indexed claimant,
		address indexed caller,
		uint256 amount
	);

	/**
		Construct a new vault by providing it a permissioned claim signer which may
		issue claims and claim amounts.

		@param _name The name of the vault used in EIP-712 domain separation.
		@param _signer The address permitted to sign claim signatures.
		@param _staker The address of the Impostors staker.
		@param _rewardToken The address of the reward Token.
	*/
	constructor (
		string memory _name,
		address _signer,
		address _staker,
		address _rewardToken
	) EIP712(_name, "1") {
		name = _name;
		signer = _signer;
		staker = _staker;
		rewardToken = _rewardToken;
		IERC20(rewardToken).approve(staker, type(uint256).max);
	}

	/**
		A private helper function to validate a signature supplied for token claims.
		This function constructs a digest and verifies that the signature signer was
		the authorized address we expect.

		@param _claimant The claimant attempting to claim tokens.
		@param _asset The address of the ERC-20 token being claimed.
		@param _amount The amount of tokens the claimant is trying to claim.
		@param _v The recovery byte of the signature.
		@param _r Half of the ECDSA signature pair.
		@param _s Half of the ECDSA signature pair.
	*/
	function _validClaim (
		address _claimant,
		address _asset,
		uint256 _amount,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) private view returns (bool) {
		bytes32 digest = keccak256(
			abi.encodePacked(
				"\x19\x01",
				DOMAIN_SEPARATOR,
				keccak256(
					abi.encode(
						CLAIM_TYPEHASH,
						_claimant,
						_asset,
						_amount
					)
				)
			)
		);

		// The claim is validated if it was signed by our authorized signer.
		return ecrecover(digest, _v, _r, _s) == signer;
	}

	/**
		Allow a caller to claim any of their available tokens and automatically
		stake them in the SuperVerseDAO staker if:
		1. the claim is backed by a valid signature from the trusted `signer`.
		2. the vault has enough tokens to fulfill the claim.
		3. the staker contract is approved to spend the correct tokens by the claimant

		@param _claimant The address of the user to claim tokens for.
		@param _amount The amount of tokens that the caller is trying to claim.
		@param _v The recovery byte of the signature.
		@param _r Half of the ECDSA signature pair.
		@param _s Half of the ECDSA signature pair.
	*/
	function claimAndStake (
		address _claimant,
		uint256 _amount,
		uint256 _provided,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) external nonReentrant {
	
		// Validate that the claimant has not already claimed.
		if (claimed[_claimant]) {
			revert AlreadyClaimed();
		}

		// Validiate that the claim was provided by our trusted `signer`.
		bool validSignature = _validClaim(
			_claimant,
			rewardToken,
			_amount,
			_v,
			_r,
			_s
		);
		if (!validSignature) {
			revert InvalidSignature();
		}

		// Mark the claim as fulfilled.
		claimed[_claimant] = true;

		// Transfer any provided tokens from the claimant.
		IERC20(rewardToken).safeTransferFrom(
			_claimant,
			address(this),
			_provided
		);

		// Stake the claim and any additional balance
		ISuperVerseStaker.InputItem[] memory emptyItems;
		ISuperVerseStaker(staker).stake(
			_amount + _provided, 
			_claimant,
			emptyItems
		);

		// Emit an event.
		emit Claimed(_claimant, msg.sender, _amount);
	}

	/**
		Grant the SuperVerseDAO staker an allowance to transfer a specified 
		'_amount' of reward tokens

		@param _amount The amount of token to approve.
	*/
	function approveStaker (
		uint256 _amount
	) external onlyOwner {
		IERC20(rewardToken).approve(staker, _amount);
	}

	/**
		Allow the owner to sweep either Ether or a particular ERC-20 token from the
		contract and send it to another address. This allows the owner of the shop
		to withdraw their funds after the sale is completed.

		@param _token The token to sweep the balance from; if a zero address is sent
			then the contract's balance of Ether will be swept.
		@param _destination The address to send the swept tokens to.
		@param _amount The amount of token to sweep.
	*/
	function sweep (
		address _token,
		address _destination,
		uint256 _amount
	) external onlyOwner nonReentrant {

		// A zero address means we should attempt to sweep Ether.
		if (_token == address(0)) {
			(bool success, ) = payable(_destination).call{ value: _amount }("");
			if (!success) { revert SweepingTransferFailed(); }

		// Otherwise, we should try to sweep an ERC-20 token.
		} else {
			IERC20(_token).transfer(_destination, _amount);
		}
	}
}

