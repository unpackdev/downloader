// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";

import "./console.sol";

/**
 * @title The Sale contract.
 *
 * For the UTU crowdsale, participants first need to go through KYC after which
 * they are allowed to exchange USDT for UTU tokens at a fixed price. Each
 * participant is only allowed to exchange <= 500 USDT.
 *
 * A Successful KYC check will grant the user a signature which the contract
 * uses for authorization. We impose a limit of only one purchase per address.
 *
 */

interface IUTUToken {
	function mint(address to, uint256 amount) external;
	function burn(uint256 amount) external;
}

contract Sale is Ownable {
	using SafeERC20 for ERC20;
	using SafeMath for uint256;
	using ECDSA for bytes32;

	struct Cart {
		uint256 amount;
		bool checkedOut;
	}

	address public utuToken;
	ERC20 public usdt;
	address public kycAuthority;
	address public treasury;

	uint256 public startTime;
	uint256 public endTime;

	// The following constants are all for the public sale.
	uint256 public maxContribution = 1242 * 10**6; // USDT uses 6 decimals.
	uint256 public minContribution = 200 * 10**6;
	uint256 public maxUSDT = 250000 * 10**6; // The sale is capped at 250000 USDT
	uint256 public maxUTU = 6250000 * 10**18;
	uint256 public utuPerUSDT = (6250000 / 250000) * 10**12;
	uint256 public usdtAvailable = maxUSDT;

	// Mapping from KYC address to withdrawal address.
	mapping(address => Cart) public publicContributors;

	// Private sale participants can claim their allocation after the public sale
	// finishes.
	bool public assigned;
	mapping(address => Cart) public privateContributors;

	event Contributed(address indexed kycAddress, address indexed sender, uint256 amount);
	event CheckOut(address indexed target, uint256 amount, bool indexed isPublic);

	/**
	 *  @param _utuToken address Token for sale
	 *  @param _usdt address USDT token used to contribute to sale
	 *  @param _kycAuthority address Address of the KYC signer
	 *  @param _treasury address Address of treasury receiving USDT
	 *  @param _startTime uint256 specifying the the starting time of the sale
	 */
	constructor(
		address _utuToken,
		ERC20 _usdt,
		address _kycAuthority,
		address _treasury,
		uint256 _startTime
	) public {
		utuToken = _utuToken;
		usdt = _usdt;
		kycAuthority = _kycAuthority;
		treasury = _treasury;
		startTime = _startTime;
		endTime = startTime + 2 days;
	}

	/*
	 * The KYC authority does sign(signHash(hash(kycAddr))) to authorize the
	 * given address. Someone could front-run us here and use the signature
	 * to buy. This is not a problem because the tokens will be minted to the
	 * kycAddr and thus the front-runner would just give us free tokens.
	 *
	 * @param _kycAddr address provided during kyc and receiver of tokens
	 * @param amount uint256 USDT to be exchanged for UTU
	 * @param signature bytes signature provided by the KYC authority
	 *
	 */
	function buy(address _kycAddr, uint256 amount, bytes memory signature) public {
		require(usdtAvailable > 0, 'UTU: no more UTU token available');
		require(isActive(), 'UTU: sale is not active');
		if (!isUncapped()) {
			require(amount <= maxContribution, 'UTU: above individual cap');
			require(publicContributors[_kycAddr].amount == 0, 'UTU: already bought');
		}
		require(amount >= minContribution, 'UTU: below individual floor');

		uint256 _usdtActual = amount > usdtAvailable ? usdtAvailable : amount;
		uint256 out = usdtToUTU(_usdtActual);
		usdtAvailable = usdtAvailable.sub(_usdtActual);

		bytes32 eh = keccak256(abi.encodePacked(_kycAddr)).toEthSignedMessageHash();
		require(ECDSA.recover(eh, signature) == kycAuthority, 'UTU: invalid signature');

		publicContributors[_kycAddr].amount = publicContributors[_kycAddr].amount.add(out);
		usdt.safeTransferFrom(msg.sender, treasury, _usdtActual);

		emit Contributed(_kycAddr, msg.sender, out);
	}

	/*
	 * After the public sale finishes anyone can mint for a given kycAddr, since
	 * funds are sent to that address and not the caller of the function.
	 *
	 * @param kycAddr address to mint tokens to.
	 */
	function checkoutPublic(address _kycAddr) public {
		require(block.timestamp > endTime, 'UTU: can only check out after sale');
		require(publicContributors[_kycAddr].amount > 0, 'UTU: no public allocation');
		require(!publicContributors[_kycAddr].checkedOut, 'UTU: already checked out');

		publicContributors[_kycAddr].checkedOut = true;
		IUTUToken(utuToken).mint(_kycAddr, publicContributors[_kycAddr].amount);

		emit CheckOut(_kycAddr, publicContributors[_kycAddr].amount, true);
	}

	/**
	 * Assign the amounts for the private sale participants.
	 *
	 *  @param _contributors Address[] All the private contributor addresses
	 *  @param _balances uint256[] All the private contributor balances
	 */
	function assignPrivate(
		address[] memory _contributors,
		uint256[] memory _balances
	) onlyOwner public {
		require(!assigned, "UTU: already assigned private sale");
		require(_contributors.length == _balances.length, "UTU: mismatching array lengths");
		for (uint32 i = 0 ; i < _contributors.length; i++) {
			require(privateContributors[_contributors[i]].amount == 0, 'UTU: already assigned');
			privateContributors[_contributors[i]] = Cart(_balances[i], false);
		}
		assigned = true;
	}

	/*
	 * After the public sale finishes the private sale participants get their tokens
	 * unlocked and can mint them.
	 *
	 */
	function checkoutPrivate(address _target) public {
		require(block.timestamp > endTime, 'UTU: can only check out after sale');
		require(privateContributors[_target].amount > 0, 'UTU: no private allocation');
		require(!privateContributors[_target].checkedOut, 'UTU: already checked out');

		privateContributors[_target].checkedOut = true;
		IUTUToken(utuToken).mint(_target, privateContributors[_target].amount);

		emit CheckOut(_target, privateContributors[_target].amount, false);
	}

	/*
	 * Calculate UTU allocation given USDT input.
	 *
	 * @param _usdtIn uint256 USDT to be converted to UTU.
	 */
	function usdtToUTU(uint256 _usdtIn) public view returns (uint256) {
		return _usdtIn.mul(utuPerUSDT);
	}

	/*
	 * Calculate amount of UTU coins left for purchase.
	 */
	function utuAvailable() public view returns (uint256) {
		return usdtAvailable.mul(utuPerUSDT);
	}

	/*
	 * Check whether the sale is active or not
	 */
	function isActive() public view returns (bool) {
		return block.timestamp >= startTime && block.timestamp < endTime;
	}

	/*
	 * Check whether the cap on individual contributions is active.
	 */
	function isUncapped() public view returns (bool) {
		return block.timestamp > startTime + 1 hours;
	}

	/**
	 * Recover tokens accidentally sent to the token contract.
	 *  @param _token address of the token to be recovered. 0x0 address will
	 *                        recover ETH.
	 *  @param _to address Recipient of the recovered tokens
	 *  @param _balance uint256 Amount of tokens to be recovered
	 */
	function recoverTokens(address _token, address payable _to, uint256 _balance)
		onlyOwner
		external
	{
		require(_to != address(0), "cannot recover to zero address");

		if (_token == address(0)) { // Recover Eth
			uint256 total = address(this).balance;
			uint256 balance = _balance == 0 ? total : Math.min(total, _balance);
			_to.transfer(balance);
		} else {
			uint256 total = ERC20(_token).balanceOf(address(this));
			uint256 balance = _balance == 0 ? total : Math.min(total, _balance);
			ERC20(_token).safeTransfer(_to, balance);
		}
	}
}

