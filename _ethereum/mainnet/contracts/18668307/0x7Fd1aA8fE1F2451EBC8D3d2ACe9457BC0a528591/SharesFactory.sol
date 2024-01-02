// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TradeableShares.sol";

/**
 * @title Shares Factory
 *
 * @notice Creates/deploys TradeableShares contracts
 *
 * @notice The factory manages protocol fees of the deployed TradeableShares contract:
 *      deployed contracts usually follow the protocol fees set on the factory
 *
 * @dev Based on the friend.tech FriendtechSharesV1.sol
 */
interface SharesFactory {
	/**
	 * @dev Enum of all possible TradeableShares implementations the factory can deploy
	 */
	enum ImplementationType {
		/// @dev ETHShares implementation
		ETH,
		/// @dev ERC20Shares implementation bound to the ERC20 payment token
		ERC20
	}

	/**
	 * @dev Shares deployment request is used to enable the TradeableShares
	 *      deployment with meta-transactions
	 * @dev See `executeDeploymentRequest()`
	 */
	struct SharesDeploymentRequest {
		/// @dev TradeableShares implementation type
		ImplementationType implementationType;
		/// @dev shares subject, owner of the curve
		TradeableShares.SharesSubject sharesSubject;
		/// @dev an address to mint the NFT defined by the subject if it doesn't exist
		address issuer;
		/// @dev how many shares to buy immediately after the deployment
		uint256 amount;
		/// @dev unix timestamp when the request becomes valid
		uint256 validFromTimestamp;
		/// @dev unix timestamp when the request expires (becomes invalid)
		uint256 expiresAtTimestamp;
		/// @dev nonce of the request (sequential number, increased by one)
		uint256 nonce;
	}

	/**
	 * @dev Fired in
	 *      `setProtocolFeeDestination`
	 *      `setProtocolFeePercent`
	 *      `setHoldersFeePercent`
	 *      `setSubjectFeePercent`
	 *      `setProtocolFee`
	 *
	 * @param protocolFeeDestination address where the protocol fee is sent
	 * @param protocolFeePercent protocol fee percent, value 10^18 corresponds to 100%
	 * @param holdersFeePercent shares holders fee percent, value 10^18 corresponds to 100%
	 * @param subjectFeePercent subject fee percent, value 10^18 corresponds to 100%
	 */
	event ProtocolFeeUpdated(
		address protocolFeeDestination,
		uint64 protocolFeePercent,
		uint64 holdersFeePercent,
		uint64 subjectFeePercent
	);

	/**
	 * @dev Fired in `deploySharesContract` and `registerSharesContract`
	 *
	 * @param creator shares creator, a.k.a. shares issuer, or current owner
	 * @param implementationContract newly deployed or registered TradeableShares contract
	 * @param holdersRewardsDistributor the shares holders fee destination, HoldersRewardsDistributor contract,
	 *      this can be zero if shares contract is deployed without the shares holders fee distribution
	 * @param implementationType type of the TradeableShares, see ImplementationType
	 * @param sharesSubject current shares subject
	 * @param newDeployment true if the factory deployed this TradeableShares contract,
	 *      false if TradeableShares contract was already deployed and factory just registered it
	 */
	event SharesContractRegistered(
		address indexed creator,
		TradeableShares indexed implementationContract,
		HoldersRewardsDistributor indexed holdersRewardsDistributor,
		ImplementationType implementationType,
		TradeableShares.SharesSubject sharesSubject,
		bool newDeployment
	);

	/**
	 * @dev Fired in `executeDeploymentRequest` and in `rewind`
	 */
	event NonceUsed(address indexed issuer, uint256 nonce);

	/**
	 * @notice Address of the already deployed TradeableShares implementation
	 *      to be used by the factory to deploy the TradeableShares contracts EIP-1167 clones
	 *
	 * @param _implementationType TradeableShares implementation type
	 * @return the address of the already deployed TradeableShares implementation corresponding
	 *      to the given implementation type
	 */
	function getSharesImplAddress(ImplementationType _implementationType) external view returns(address);

	/**
	 * @notice Address of the already deployed HoldersRewardsDistributor implementation
	 *      to be used by the factory to deploy the HoldersRewardsDistributor contracts EIP-1167 clones
	 *
	 * @dev If the HoldersRewardsDistributor implementation is missing, the TradeableShares contract
	 *      can still be deployed, not being attached to the HoldersRewardsDistributor
	 *
	 * @param _implementationType TradeableShares implementation type
	 * @return the address of the already deployed HoldersRewardsDistributor implementation corresponding
	 *      to the given implementation type
	 */
	function getDistributorImplAddress(ImplementationType _implementationType) external view returns(address);

	/**
	 * @notice Protocol fee destination is the address receiving the protocol fee
	 *
	 * @return feeDestination protocol fee destination, address
	 */
	function getProtocolFeeDestination() external view returns(address feeDestination);

	/**
	 * @notice Protocol fee percent is the percentage of the buy/sell transaction volume
	 *      sent to the protocol fee destination
	 *
	 * @dev The value has 18 decimals, 100% is represented as 10^18
	 *
	 * @return feePercent protocol fee percent
	 */
	function getProtocolFeePercent() external view returns(uint256 feePercent);

	/**
	 * @notice Shares holders fee percent is the percentage of the buy/sell transaction volume
	 *      sent to the shares holders rewards distributor contract
	 *
	 * @dev The value has 18 decimals, 100% is represented as 10^18
	 *
	 * @return feePercent shares holders fee percent
	 */
	function getHoldersFeePercent() external view returns(uint256 feePercent);

	/**
	 * @notice Subject fee percent is the percentage of the buy/sell transaction volume
	 *      sent to the subject issuer
	 *
	 * @dev The value has 18 decimals, 100% is represented as 10^18
	 *
	 * @dev Implementation may return different values for different callers,
	 *      for example it can read SharesSubject from the caller TradeableShares contract
	 *      and dynamically determine the subject fee
	 *
	 * @return feePercent subject fee percent
	 */
	function getSubjectFeePercent() external view returns(uint256 feePercent);

	/**
	 * @notice Sets the protocol fee destination
	 *
	 * @dev Implementation must check the consistency of the protocol fee destination and percent
	 *      set by this and `setProtocolFeePercent` functions
	 *
	 * @param feeDestination protocol fee destination to set
	 */
	function setProtocolFeeDestination(address feeDestination) external;

	/**
	 * @notice Sets the protocol fee percent
	 *
	 * @dev Implementation must check the consistency of the protocol fee destination and percent
	 *      set by this and `setProtocolFeeDestination` functions
	 *
	 * @param feePercent protocol fee percent to set, examples: 10^18 is 100%, 10^17 is 10%
	 */
	function setProtocolFeePercent(uint64 feePercent) external;

	/**
	 * @notice Sets the shares holders fee percent
	 *
	 * @param feePercent shares holders fee percent to set, examples: 10^18 is 100%, 10^17 is 10%
	 */
	function setHoldersFeePercent(uint64 feePercent) external;

	/**
	 * @notice Sets the subject fee percent
	 *
	 * @param feePercent subject fee percent to set, examples: 10^18 is 100%, 10^17 is 10%
	 */
	function setSubjectFeePercent(uint64 feePercent) external;

	/**
	 * @notice Sets all the fees at once:
	 *      protocolFeeDestination
	 *      protocolFeePercent
	 *      holdersFeePercent
	 *      subjectFeePercent
	 *
	 * @param protocolFeeDestination protocol fee destination to set
	 * @param protocolFeePercent protocol fee percent to set, examples: 10^18 is 100%, 10^17 is 10%
	 * @param holdersFeePercent shares holders fee percent to set, examples: 10^18 is 100%, 10^17 is 10%
	 * @param subjectFeePercent subject fee percent to set, examples: 10^18 is 100%, 10^17 is 10%
	 */
	function setProtocolFee(
		address protocolFeeDestination,
		uint64 protocolFeePercent,
		uint64 holdersFeePercent,
		uint64 subjectFeePercent
	) external;

	/**
	 * @notice Deploys the TradeableShares implementation for the specified subject;
	 *      the curve remains paused, no shares are being bought immediately
	 *
	 * @notice Tries minting the NFT defined by the subject if it doesn't exist
	 *
	 * @dev Implementation must guarantee only one TradeableShares contract per subject
	 *
	 * @param implementationType TradeableShares implementation type
	 * @param sharesSubject shares subject, owner of the curve
	 * @return deployed TradeableShares contract
	 */
	function deploySharesContractPaused(
		ImplementationType implementationType,
		TradeableShares.SharesSubject calldata sharesSubject
	) external returns(TradeableShares);

	/**
	 * @notice Deploys the TradeableShares implementation for the specified subject;
	 *      the curve launches immediately, the first share is issued to the subject issuer (NFT owner)
	 *
	 * @notice Tries minting the NFT defined by the subject if it doesn't exist
	 *
	 * @dev Implementation must guarantee only one TradeableShares contract per subject
	 *
	 * @param implementationType TradeableShares implementation type
	 * @param sharesSubject shares subject, owner of the curve
	 * @return deployed TradeableShares contract
	 */
	function deploySharesContract(
		ImplementationType implementationType,
		TradeableShares.SharesSubject calldata sharesSubject
	) external returns(TradeableShares);

	/**
	 * @notice Deploys the TradeableShares implementation for the specified subject;
	 *      allows to immediately buy any amount of shares (including zero)
	 *
	 * @notice Tries minting the NFT defined by the subject if it doesn't exist
	 *
	 * @dev Implementation must guarantee only one TradeableShares contract per subject
	 *
	 * @param implementationType TradeableShares implementation type
	 * @param sharesSubject shares subject, owner of the curve
	 * @param amount how many shares to buy immediately after the deployment
	 * @return deployed TradeableShares contract
	 */
	function deploySharesContractAndBuy(
		ImplementationType implementationType,
		TradeableShares.SharesSubject calldata sharesSubject,
		uint256 amount
	) external payable returns(TradeableShares);

	/**
	 * @notice Deploys the TradeableShares implementation for the specified subject;
	 *      allows to immediately buy any amount of shares (including zero)
	 *
	 * @notice Tries minting the NFT defined by the subject if it doesn't exist
	 *
	 * @dev Implementation must guarantee only one TradeableShares contract per subject
	 *
	 * @param implementationType TradeableShares implementation type
	 * @param sharesSubject shares subject, owner of the curve
	 * @param issuer an address to mint the NFT defined by the subject if it doesn't exist
	 * @param amount how many shares to buy immediately after the deployment
	 * @return deployed TradeableShares contract
	 */
	function mintSubjectAndDeployShares(
		ImplementationType implementationType,
		TradeableShares.SharesSubject calldata sharesSubject,
		address issuer,
		uint256 amount
	) external payable returns(TradeableShares);

	/**
	 * @notice Executes signed SharesDeploymentRequest; this is identical to executing `mintSubjectAndDeployShares`
	 *      on behalf of the signer and allows the transaction to be relayed so that the gas is payed by the
	 *      relayer
	 *
	 * @param req the deployment request to fulfill, containing same data as in `mintSubjectAndDeployShares`
	 * @param signature the deployment request EIP712 signature issued by the address allowed to execute
	 *      the request
	 * @return deployed TradeableShares contract
	 */
	function executeDeploymentRequest(
		SharesDeploymentRequest calldata req,
		bytes calldata signature
	) external payable returns(TradeableShares);

	/**
	 * @notice Gets current (unused) nonce for the given issuer address;
	 *      unused nonce is required to build the SharesDeploymentRequest and sign it
	 *      nonces increment by one after each use
	 *
	 * @param issuer the issuer address to get the nonce for
	 * @return current (unused) nonce; incremented by one after
	 *      each successful execution of the `executeDeploymentRequest` function
	 */
	function getNonce(address issuer) external view returns(uint256);

	/**
	 * @notice Rewinds forward the nonce for the issuer specified, used to
	 *      discard one or more signed requests to `executeDeploymentRequest`
	 *
	 * @dev Implementation must not allow to decrease the nonce, only increasing (rewinding)
	 *      must be possible
	 *
	 * @param issuer the issuer address to rewind the nonce for
	 * @param nonce the nonce value to rewind to
	 */
	function rewindNonce(address issuer, uint256 nonce) external;

	/**
	 * @notice Gets the already deployed TradeableShares contract
	 *
	 * @param sharesSubject shares subject, owner of the curve
	 * @return deployed TradeableShares contract
	 */
	function lookupSharesContract(
		TradeableShares.SharesSubject calldata sharesSubject
	) external view returns(TradeableShares);

	/**
	 * @notice Registers or re-registers the already deployed TradeableShares contract
	 *
	 * @dev Initial registration is usually done manually by authorized address,
	 *      Re-registration is usually done by the shares contract itself
	 *      and implementations must keep the access to this function open for
	 *      the already registered contracts
	 *
	 * @param shares already deployed TradeableShares contract
	 */
	function registerSharesContract(TradeableShares shares) external;

	/**
	 * @notice Executed only by the previously registered TradeableShares contracts
	 *      to notify the factory about the subject change.
	 *
	 * @dev The factory may throw if the subject is already taken by another contract
	 */
	function notifySubjectUpdated() external;
}

