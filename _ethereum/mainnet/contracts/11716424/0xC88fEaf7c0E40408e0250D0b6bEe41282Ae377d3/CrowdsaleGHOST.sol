// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./GHOST.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./Context.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./FinalizableCrowdsale.sol";
import "./Crowdsale.sol";

/**
 * @dev Crowdsale for token, including:
 *
 * - ability to accept funds and forward them to pre-defined wallet
 * - mint tokens after funds accepted
 * - a pauser role that allows to stop all crowdsale functionality
 * - change wallet of the crowdsale (only when paused)
 * - change rate of the crowdsale (only when paused)
 * - change minimal amount of tokens to purchase (only when paused)
 * - fixed ghost cap ( CROWDSALE.cap() * 1.2 = TOKEN.cap(). Example: 40m for token and 32m for crowdsale )
 * - purchase can be done only if account has ERC721GHOSTPoI token
 * - must be 5 payees, who will take additional 20% of minted supply (right after finalization)
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deployes the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which let it grant both minter
 * and pauser roles to other accounts
 *
 *
 * Should be also capped, with maximum supply 32million of tokens. 
 * X / 20 * 10^6 * 10*18 (decimals) = X * 10^24 / 20
 * 32 / 20 * 10^6 * 10^18 (decimals) = 1.6 * 10^24 (for every payee)
 * TOTAL: ( 32 + 1.6 * 5 ) * 10^24 = 40 * 10^24 (token cap)
 */
contract CrowdsaleGHOST is Context, AccessControl, Crowdsale, Pausable, FinalizableCrowdsale {

	using SafeMath for uint256;
    	using SafeERC20 for IERC20;

	event NewPurchaseRate(uint indexed changeTime, address account, uint256 oldRate, uint256 newRate);
	event NewPurchaseMinimum(uint indexed changeTime, address account, uint256 oldMinimum, uint256 newMinimum);
	event NewWalletSet(uint indexed chengeTime, address account, address oldWallet, address newWallet);

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

	uint256 private _minimumTokens = 100000000000000000000000;     // ~$5,000 with ETH price of $580
	uint256 private _ghostRate     = 11600;                        // ~$0.05 for token with ETH price of $580
	uint256 private _ghostCap      = 32000000000000000000000000;   // 10^18 decimals, 32m of tokens
	address payable private _ghostWallet  = address(0);
	IERC721 private _ghostKyc;
	address[] private _payees;

	
	/**
	 * @dev Creates new instance of crowdsale.
	 * 
	 * The rate is the conversion between wei and the smallest and indivisible
	 * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
	 * with 3 decimals called FTS, 1 wei will give you 1 unit, or 0.001 FTS.
	 * Minumum amount of tokens can not be zero or less.
	 * All addresses of `payess` must be non-zero, not smart contracts addresses
	 *
	 * @param payees Addresses of payees to get external reward
	 * @param givenWallet Address where collected funds will be forwarded to
	 * @param token Address of the token being sold
	 */
	constructor (address[] memory payees, address payable givenWallet, IERC20 token, IERC721 ghostKyc) Crowdsale(_ghostRate, givenWallet, token) {
		require(payees.length == 5, "Should be 5 payees addresses");

		for (uint8 i = 0; i < payees.length; i++) {
			require(payees[i] != address(0), "Account is zero address");
			require(!Address.isContract(payees[i]), "Payee account is smart contract");
			
			_payees.push(payees[i]);
		}
		_ghostKyc = ghostKyc;
		_setMinimumTokens(_minimumTokens);	
		_changeRate(_ghostRate);
		_changeWallet(givenWallet);

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		_setupRole(MINTER_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, _msgSender());
	}


	/**
	 * @return The cap of the crowdsale.
	 */
	function cap() public view returns (uint256) {
		return _ghostCap;
	}


	/**
	 * @return Current crowdsale wallet
	 */
	function wallet() public view override returns (address payable) {
		return _ghostWallet;
	}


	/**
	 * @return Is there availiable tokens for crowdsale to mint.
	 */
	function capReached() public view returns (bool) {
		return _ghostCap <= 0;
	}


	/**
	 * @return Current GHOST rate
	 */
	function rate() public view override returns (uint256) {
		return _ghostRate;
	}


	/**
	 * @return Minimal amount of tokens to purchase.
	 */
	function minimumTokens() public view returns(uint256) {
		return _minimumTokens;
	}


	/** 
	 * @dev Extract payee address by index.
	 * Index should be between 0 and 4, total 5 payees guaranteed.
	 * @param _index Number of payee needed
	 */
	function payee(uint8 _index) public view returns (address) {
		require(_index >= 0 && _index < 5, "No payee found for that index");
		return _payees[_index];
	}


	/**
	 * @dev Change crowdsale wallet. Only pauser address can send.
	 * Can be executed only when crowdsale is paused.
	 *
	 * @param _wallet New crowdsale wallet.
	 */
	function changeWallet(address payable _wallet) public {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		require(paused(), "Crowdsale active: wallet change during crowdsale");
		_changeWallet(_wallet);
	}


	/**
	 * @dev Set minimal amount of tokens to be purchased.
	 * Only pauser address can execute.
	 * Can be executed only when crowdsale is paused.
	 *
	 * @param _value Minimal amount of tokens to purchase.
	 */
	function setMinimumTokens(uint256 _value) public {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		require(paused(), "Crowdsale active: minimum token amount change during crowdsale");
		_setMinimumTokens(_value);
	}

	
	/**
	 * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
	 * tokens. Desired cap should be decreased after successful purchase.
         *
	 * @param _beneficiary Address receiving the tokens
	 * @param _tokenAmount Number of tokens to be purchased
	 */
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal override {
		super._processPurchase(_beneficiary, _tokenAmount);

		_ghostCap = _ghostCap.sub(_tokenAmount);
	}
	

	/**
	 * @dev Function is private setter for new rate field.
	 * Reverts any zero-like value as rate.
	 *
	 * @param _value New rate needed for crowdsale.
	 */
	function _changeRate(uint256 _value) private {
		require(_value > 0, "New rate should be greater zero");
		uint256 tmp = _ghostRate;
		_ghostRate = _value;
		emit NewPurchaseRate(block.timestamp, msg.sender, tmp, _value);
	}
	

	/**
	 * @dev Change crowdsale wallet. New address should be non-zero account.
	 * Should throw if wallet is zero address.
	 *
	 * @param _wallet New address of crowdsale wallet.
	 */
	function _changeWallet(address payable _wallet) private {
		require(_wallet != address(0), "Crowdsale: wallet is the zero address");
		address tmp = _ghostWallet;
		_ghostWallet = _wallet;
		emit NewWalletSet(block.timestamp, msg.sender, tmp, _wallet);
	}


	/**
	 * @dev Setting minimal amount of tokens to be purchased.
	 * New minimum should be greater zero.
	 *
	 * @param _value New minimal amount of tokens to purchase.
	 */
	function _setMinimumTokens(uint256 _value) private {
		require(_value > 0, "Minimum amount of tokens can not be zero");
		uint256 tmp = _minimumTokens;
		_minimumTokens = _value;
		emit NewPurchaseMinimum(block.timestamp, msg.sender, tmp, _value);
	}


	/** 
	 * @dev Overrides function from FinalizationCrowdsale.sol file.
	 * the reason is to add extra 20% to payees in the end of crowdsale.
	 * should be called only by the owner of crowdsale (aka `pauser`)
	 */
	function _finalization() internal override {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		uint256 payment = IERC20(address(token())).totalSupply().div(20);
		require(payment >= 100, "Account is not due payment");

		for (uint8 i = 0; i < _payees.length; i++) {
			require(IERC721(address(_ghostKyc)).balanceOf(_payees[i]) == 1, "no KYC for payeer");
		}

		for (uint8 i = 0; i < _payees.length; i++) {
			GHOST(address(token())).mint(_payees[i], payment);
		}

		super._finalization();
	}

	/**
         * @dev Must be called after crowdsale ends, to do some extra finalization
         * work. Calls the contract's finalization function.
         */
	function finalize() public override {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		super.finalize();
	}


	/**
	 * @dev Unpause the crowdsale with new rate.
	 * Overloading `unpause` method in order to add new parameter.
	 *
	 * @param _value new rate for crowdsale
	 */
	function unpause(uint256 _value) public {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		require(paused(), "Crowdsale deactivated: pause previously");
		_changeRate(_value);

		super._unpause();
	}

	/**
	 * @dev Unpause without any changes.
	 *
	 */
	function unpause() public {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		require(paused(), "Crowdsale deactivated: pause previously");

		super._unpause();
	}


	/**
	 * @dev Pause the crowdsale.
	 */
	function pause() public {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		require(!paused(), "Crowdsale active: unpause previously");

		super._pause();
	}


	/**
	 * @dev overrides delievry by minimum tokens upon purchase.
	 * @param _beneficiary Token purchaser
	 * @param _tokenAmount Number of tokens to be minted
	 */
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal override {
		require(GHOST(address(token())).mint(_beneficiary, _tokenAmount), "MintedCrowdsale: minting failed");
	}
	

	/**
	 * @dev Validation of an incoming purchase. Use require 
	 * statements to revert state when conditions are not met.
	 * Crowdsale cap should not be reached.
	 * Crowdsale is not finalized yet.
	 * Minimal purchase should be checked.
	 * Cap should provide new purchaser to get tokens, 
	 * keep in mind about `payees extra`.
	 * Sender and beneficiary can not be smart contracts.
	 * 
	 * @param _beneficiary Address perfoming the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount ) internal view override {
		require(!capReached(), "Cap reached");
		require(!paused(), "Crowdsale stopped: token transfer while paused");
		require(!finalized(), "Crowdsale ended");
		require(!Address.isContract(msg.sender), "Sender is smart contract");
		require(!Address.isContract(_beneficiary), "Beneficiary is smart contract");
		require(_weiAmount.mul(_ghostRate) >= _minimumTokens, "Not enough to reach minimum payment");
		require(_ghostCap >= _weiAmount.mul(_ghostRate), "Not enough free tokens to distribute");
		require(IERC721(address(_ghostKyc)).balanceOf(msg.sender) == 1, "KYC not passed by sender");
		require(IERC721(address(_ghostKyc)).balanceOf(_beneficiary) == 1, "KYC not passed by beneficiary");
		

		super._preValidatePurchase(_beneficiary, _weiAmount);
	}


	/**
	 * @dev Overriding the old method. Calculates amount of tokens to purchase
	 * based on sent amount of wei.
	 *
	 * @param weiAmount Amount of wei sent to purchase tokens.
	 */
	function _getTokenAmount(uint256 weiAmount) internal view override returns (uint256) {
		return rate().mul(weiAmount);
	}


	/**
	 * @dev Determines how ETH is stored/forwarded on purchases.
	 * Overriden because of change `_wallet` to `_ghostWallet`.
	 */
	function _forwardFunds() internal override {
		_ghostWallet.transfer(msg.value);
	}

}
