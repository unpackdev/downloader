// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";

/**
 * @title Base implementation of the Bridge Agent
 *
 * Chain-specific Bridge Agents are meant to extend from this class
 * and also implement deposit() and claim() functions.
 *
 * Besides maximizing code reuse, bridge agents from different chains also
 * implement the same interface. The Bridge Backend uses the ABI of this class
 * to read agent data from blockchain, without relying on chain-specific
 * implementation details of agents.
 */
abstract contract AbstractBridgeAgent is Ownable, Pausable {
	using SafeERC20 for IERC20;
	using ECDSA for bytes32;

	// Each new release of bridge agent would have a new version
	uint8 public constant VERSION = 1;

	// Public key of signer that is used to sign bridge operations
	address public bridgeSigner;
	// Wallet where the bridge fee will be transferred
	address payable public treasurer;

	// Map that holds current token registrations, tokenSigners[token] = signer
	mapping(address => address) public tokenSigners;
	// Stores the list of paused tokens
	mapping(address => bool) public tokenPaused;
	// Remembers used signatures to avoid reuse and re-entry
	mapping(bytes32 => bool) internal signatureUsed;

	// Emitted when bridge signer is changed
	event SetBridgeSigner(
		address indexed previousBridgeSigner,
		address indexed newBridgeSigner
	);

	// Emitted when treasurer is changed
	event SetTreasurer(
		address payable indexed previousTreasurer,
		address payable indexed newTreasurer
	);

	// Emitted when a new token is registered or existing registration is updated
	event Register(
		address indexed token,
		address indexed baseToken,
		address indexed signer
	);

	// Emitted when amount of registered token is deposited
	event Deposit(
		uint256 toChain,
		address indexed token,
		address indexed fromWallet,
		address indexed toWallet,
		uint256 amount,
		uint256 fee
	);

	// Emitted when amount of registered token is claimed
	event Claim(
		bytes32 indexed depositTx,
		address indexed token,
		address indexed toWallet,
		uint256 amount
	);

	// Emitted when a token is migrated to a new agent contract version
	event Migrate(
		address indexed token,
		address indexed newAgent,
		uint256 balance
	);

	// Emitted when token is paused for this agent
	event TokenPaused(address indexed token, address indexed account);

	// Emitted when token is unpaused for this agent
	event TokenUnpaused(address indexed token, address indexed account);

	/**
	 * @dev Initializes the agent
	 * @param _bridgeSigner Public key of signer that is used to sign bridge operations
	 * @param _treasurer Wallet where the bridge fee will be transferred
	 */
	constructor(address _bridgeSigner, address payable _treasurer) Ownable() {
		setBridgeSigner(_bridgeSigner);
		setTreasurer(_treasurer);
	}

	/**
	 * @notice Pauses the whole agent
	 * All user-facing operations are not be possible while the agent is paused.
	 *
	 * Emits {Paused()}
	 *
	 * Requirements:
	 * - The agent should not be paused
	 * - Can only be called by the brigde agent owner
	 */
	function pause() external onlyOwner {
		_pause();
	}

	/**
	 * @notice Unpauses the agent
	 *
	 * Emits {Unpaused()}
	 *
	 * Requirements:
	 * - The agent should be paused
	 * - Can only be called by the brigde agent owner
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/**
	 * @notice Pauses a token
	 *
	 * @param token token to be paused
	 *
	 * Emits {TokenPaused()}
	 *
	 * No user-facing operations are available on a token when it's paused.
	 * The token also gets paused when it's being migrated to a newer version
	 * agent contract, see migrate().
	 *
	 * Requirements:
	 * - A token should not be currently paused
	 * - A token _doesn't_ have to be registered to be paused
	 * - Can only be called by the brigde agent owner
	 */
	function pauseToken(address token) external onlyOwner {
		_pauseToken(token);
	}

	/**
	 * @notice Unpauses a token
	 *
	 * @param token token to be unpaused
	 *
	 * Emits {TokenUnpaused()}
	 *
	 * Requirements:
	 * - A token should be paused
	 * - Can only be called by the brigde agent owner
	 */
	function unpauseToken(address token) external onlyOwner {
		_unpauseToken(token);
	}

	/**
	 * @dev Pauses a token – internal calls only
	 */
	function _pauseToken(address token) internal {
		require(!tokenPaused[token], "token is already paused");
		tokenPaused[token] = true;
		emit TokenPaused(token, msg.sender);
	}

	/**
	 * @dev Unpauses a token – internal calls only
	 */
	function _unpauseToken(address token) internal {
		require(tokenPaused[token], "token is not paused");
		tokenPaused[token] = false;
		emit TokenUnpaused(token, msg.sender);
	}

	/**
	 * @notice Sets a new bridge signer
	 *
	 * @param newBrigdeSigner Public key of signer that is used to sign bridge operations
	 *
	 * Emits {SetBridgeSigner()}
	 *
	 * Requirements:
	 * - Can only be called by the brigde agent owner
	 */
	function setBridgeSigner(address newBrigdeSigner) public onlyOwner {
		require(newBrigdeSigner != address(0), "empty bridge signer");
		emit SetBridgeSigner(bridgeSigner, newBrigdeSigner);
		bridgeSigner = newBrigdeSigner;
	}

	/**
	 * @notice Sets a new bridge treasurer
	 *
	 * @param newTreasurer Wallet where the bridge fee will be transferred
	 *
	 * Emits {SetTreasurer()}
	 *
	 * Requirements:
	 * - Can only be called by the brigde agent owner
	 */
	function setTreasurer(address payable newTreasurer) public onlyOwner {
		require(newTreasurer != address(0), "empty treasurer");
		emit SetTreasurer(treasurer, newTreasurer);
		treasurer = newTreasurer;
	}

	/**
	 * @dev Used to prevent signature reuse, re-entry, and check it's not expired
	 *
	 * @param sig signature
	 * @param sigExpire timestamp in milliseconds
	 *
	 * This modifier reverts if a signature is reused or expired
	 */
	modifier useSignature(bytes memory sig, uint256 sigExpire) {
		bytes32 sigHash = keccak256(sig);

		require(!signatureUsed[sigHash], "reused signature");
		signatureUsed[sigHash] = true;

		if (sigExpire > 0) {
			// sigExpire is in millis
			require(sigExpire > block.timestamp * 1000, "expired signature");
		}

		_;
	}

	/**
	 * @notice Registers a token in this agent.
	 *
	 * @param token address of a token to be registered
	 * @param baseToken address of a token in the main chain
	 * @param signer public key of a signer owned by token owner to sign token operations
	 * @param bridgeSig signature issued by the Bridge Service
	 * @param sigExpire nonce/expiration issued by the Bridge Service
	 *
	 * Emits {Register()}
	 *
	 * Prior to cross-chain transfer opertaions been made, a token needs to be
	 * registered in the agent, presumably by its owner. It cannot be called directly
	 * by anyone though. The Bridge Service validates token ownership and issues
	 * a signature {bridgeSig} that allows registration.
	 *
	 * This function can also be used to "re-register" a token that is already
	 * registered. This can be needed in two cases:
	 * 1. To set a new {signer} for a token.
	 * 2. To unregister a token. For this, pass address(0) as a {signer}.
	 *
	 * This function is payable(), receiving service fee in the form of ether.
	 * The actual fee value is obtained from the Bridge Service along with {bridgeSig}
	 * and {sigExpire}.
	 *
	 * NOTE: In the main chain (ETH) the {baseToken} parameter should have the
	 * same value as {token}. This parameter is needed for sub-chains like BSC
	 * so that the Bridge Service can index Register events and make proper routing
	 * for the users.
	 *
	 * Requirements:
	 * - Agent must not be paused.
	 * - {token} must not be paused.
	 * - {token} and {baseToken} cannot be empty addresses.
	 * - {bridgeSig} cannot be reused and {sigExpire} must be after the current block time.
	 */
	function register(
		address token,
		address baseToken,
		address signer,
		bytes memory bridgeSig,
		uint256 sigExpire
	) external payable useSignature(bridgeSig, sigExpire) whenNotPaused {
		require(token != address(0), "token is empty");
		require(baseToken != address(0), "baseToken is empty");
		require(!tokenPaused[token], "token is paused");

		// Check signature
		{
			bytes32 messageHash = keccak256(
				abi.encode(
					address(this),
					_msgSender(),
					token,
					baseToken,
					signer,
					msg.value,
					sigExpire
				)
			);
			bytes32 ethHash = messageHash.toEthSignedMessageHash();
			require(
				ethHash.recover(bridgeSig) == bridgeSigner,
				"invalid bridge signature"
			);
		}

		tokenSigners[token] = signer;

		// User pays fee to the bridge
		if (msg.value > 0) {
			treasurer.transfer(msg.value);
		}

		emit Register(token, baseToken, signer);
	}

	/**
	 * @notice Migrates a token to another agent contract
	 *
	 * @param token registered token to be migrated
	 * @param newAgent address of a new agent to transfer balance to
	 * @param tokenSig signature issued by a token owner
	 * @param bridgeSig signature issued by the Bridge Service
	 * @param sigExpire nonce/expiration issued by the Bridge Service
	 *
	 * Emits {Migrate()}
	 *
	 * This function is mostly needed when a new agent contract version is released.
	 * The token owner is responsible to call this function before registering a
	 * token {register()} on a new agent.
	 *
	 * Any token balance holded by this agent will be transferred to {newAgent}.
	 * Note that there is balance only in the ETH chain – in other subchains the balance
	 * is holded by the represented {SubchainToken}.
	 *
	 * Requirements:
	 * - Agent must not be paused.
	 * - {token} must be registered in this agent.
	 * - {token} must not be paused.
	 * - {tokenSig} and {bridgeSig} cannot be reused.
	 * - {sigExpire} must be after the current block time.
	 */
	function migrate(
		address token,
		address newAgent,
		bytes memory tokenSig,
		bytes memory bridgeSig,
		uint256 sigExpire
	)
		external
		useSignature(tokenSig, sigExpire)
		useSignature(bridgeSig, sigExpire)
		whenNotPaused
	{
		require(!tokenPaused[token], "token is paused");
		require(tokenSigners[token] != address(0), "token not registered");

		// check signature
		{
			bytes32 messageHash = keccak256(
				abi.encode(address(this), token, newAgent, sigExpire)
			);
			bytes32 ethHash = messageHash.toEthSignedMessageHash();
			require(
				ethHash.recover(tokenSig) == tokenSigners[token],
				"invalid token signature"
			);
			require(
				ethHash.recover(bridgeSig) == bridgeSigner,
				"invalid bridge signature"
			);
		}

		_pauseToken(token);

		// Transfer all the withhold balance of token to the new agent
		uint256 amount = IERC20(token).balanceOf(address(this));
		if (amount > 0) {
			IERC20(token).safeTransfer(newAgent, amount);
		}

		emit Migrate(token, newAgent, amount);
	}

	/**
	 * @dev Deposit a given amount to be claimed in another chain
	 *
	 * @param toChain chain ID in which the token amount will be claimed
	 * @param token address of a registered token to be deposited
	 * @param toWallet caller address that will claim the token from the {toChain}
	 * @param amount wei amount of token to be deposited/claimed
	 * @param bridgeSig signature issued by the Bridge Service
	 * @param sigExpire nonce/expiration issued by the Bridge Service
	 *
	 * See chain-specific implementation for more documentation.
	 */
	function deposit(
		uint256 toChain,
		address token,
		address toWallet,
		uint256 amount,
		bytes memory bridgeSig,
		uint256 sigExpire
	) external payable virtual;

	/**
	 * @dev Transfers a given amount of token from agent to a user
	 *
	 * @param depositTx deposit transaction hash from another chain
	 * @param token address of the local token to be claimed
	 * @param amount wei amount of token to be claimed
	 * @param tokenSig signature of the Token Owner (obtained via Bridge Service)
	 * @param bridgeSig signature of the Bridge Service
	 *
	 * See chain-specific implementation for more documentation.
	 */
	function claim(
		bytes32 depositTx,
		address token,
		uint256 amount,
		bytes memory tokenSig,
		bytes memory bridgeSig
	) external virtual;
}
