// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721SpecExt.sol";
import "./UpgradeableAccessControl.sol";
import "./TypedStructLib.sol";
import "./SharesFactory.sol";
import "./ETHShares.sol";
import "./ERC20Shares.sol";
import "./HoldersRewardsDistributorV1.sol";

import "./Clones.sol";
import "./draft-EIP712Upgradeable.sol";

/**
 * @title Shares Factory V1
 *
 * @notice Role-based access control (RBAC) based implementation of the SharesFactory
 *
 * @dev Based on the friend.tech FriendtechSharesV1.sol
 */
contract SharesFactoryV1 is SharesFactory, UpgradeableAccessControl, EIP712Upgradeable {
	// libraries in use
	using ECDSAUpgradeable for bytes32;
	using SharesSubjectLib for TradeableShares.SharesSubject;
	using TypedStructLib for SharesDeploymentRequest;

	/**
	 * @dev ERC20 payment token address, effectively immutable (cannot be updated)
	 */
	ERC1363 private /* immutable */ paymentToken;

	/**
	 * @dev Protocol fee destination is the address receiving the protocol fee
	 */
	address private protocolFeeDestination;

	/**
	 * @dev Protocol fee percent with 18 decimals (10^18 = 100%)
	 */
	uint64 private protocolFeePercent;

	/**
	 * @dev Shares holders fee percent with 18 decimals (10^18 = 100%)
	 */
	uint64 private holdersFeePercent;

	/**
	 * @dev Subject fee percent with 18 decimals (10^18 = 100%)
	 */
	uint64 private subjectFeePercent;

	/**
	 * @dev An address receiving the ownership of the deployed TradeableShares contracts
	 *
	 * @dev This should be the MultiSig address, not to EOA and not the
	 *      RBAC managed smart contract, so that this address cannot act in a scalable way;
	 *      this reduces the risk of misuse, and/or malicious use
	 */
	address private sharesOwnerAddress;

	/**
	 * @dev Deployed shares contracts mapping, keeps track of the deployed contracts subjects
	 *      Maps SharesSubject => TradeableShares
	 */
	mapping(bytes32 => TradeableShares) private shares;

	/**
	 * @dev Reverse deployed shares contracts mapping, keeps track of the deployed contracts
	 *      Maps TradeableShares address => SharesSubject
	 */
	mapping(address => TradeableShares.SharesSubject) private subjects;

	/**
	 * @dev TradeableShares implementations mapping storing deployed TradeableShares
	 *      address for every supported implementation type, used by the factory to
	 *      deploy the TradeableShares contracts EIP-1167 clones
	 *
	 * @dev Maps TradeableShares ImplementationType => TradeableShares deployed implementation address
	 */
	mapping(ImplementationType => address) private sharesImplementations;

	/**
	 * @dev HoldersRewardsDistributor implementations mapping storing deployed HoldersRewardsDistributor
	 *      address for every supported implementation type, used by the factory to
	 *      deploy the HoldersRewardsDistributor contracts EIP-1167 clones
	 *
	 * @dev If available, HoldersRewardsDistributor implementation is attached to the shares contract
	 *      during the deployment, allowing it to send shares holders fees to the distributor
	 *
	 * @dev Maps TradeableShares ImplementationType => HoldersRewardsDistributor deployed implementation address
	 */
	mapping(ImplementationType => address) private distributorsImplementations;

	/**
	 * @dev Keeps track of the used nonces for every possible issuer
	 *      Maps address => number of used nonces
	 */
	mapping(address => uint256) private nonces;

	/**
	 * @notice Enables [TradeableShares] curve deployment functionality
	 * @dev Feature FEATURE_SHARES_DEPLOYMENT_ENABLED enables `deploySharesContractPaused`,
	 *      `deploySharesContract`, and `deploySharesContractAndBuy` functions
	 */
	uint32 public constant FEATURE_SHARES_DEPLOYMENT_ENABLED = 0x0000_0001;

	/**
	 * @notice Allows the [TradeableShares] curve deployer not to buy any shares on deployment;
	 *      if disabled the deployer always gets at least one share,
	 *      effectively launching the curve and allowing anyone to buy
	 *
	 * @dev Feature FEATURE_ALLOW_PAUSED_DEPLOYMENTS enables `deploySharesContractPaused` function
	 */
	uint32 public constant FEATURE_ALLOW_PAUSED_DEPLOYMENTS = 0x0000_0002;

	/**
	 * @notice Allows the [TradeableShares] curve deployer to exclusively buy
	 *      any amount of the initial shares; if disabled the deployer always gets
	 *      no more than only one share
	 *
	 * @dev Feature FEATURE_ALLOW_EXCLUSIVE_BUY enables `deploySharesContractAndBuy` function
	 */
	uint32 public constant FEATURE_ALLOW_EXCLUSIVE_BUY = 0x0000_0004;

	/**
	 * @notice Protocol fee manager sets protocol fee destination address (protocolFeeDestination)
	 *      and protocol fee percent (protocolFeePercent)
	 *
	 * @dev Role ROLE_PROTOCOL_FEE_MANAGER is required to execute
	 *      `setProtocolFeeDestination` and `setProtocolFeePercent` functions
	 */
	uint32 public constant ROLE_PROTOCOL_FEE_MANAGER = 0x0001_0000;

	/**
	 * @notice Shares holders fee manager sets shares holders fee percent (holdersFeePercent)
	 *
	 * @dev Role ROLE_HOLDERS_FEE_MANAGER is required to execute `setHoldersFeePercent` function
	 */
	uint32 public constant ROLE_HOLDERS_FEE_MANAGER = 0x0002_0000;

	/**
	 * @notice Subject fee manager sets subject fee percent (subjectFeePercent)
	 *
	 * @dev Role ROLE_PROTOCOL_FEE_MANAGER is required to execute `setSubjectFeePercent` function
	 */
	uint32 public constant ROLE_SUBJECT_FEE_MANAGER = 0x0004_0000;

	/**
	 * @notice Shares registrar deploys new and registers already deployed TradeableShares instances
	 *
	 * @dev Role ROLE_SHARES_REGISTRAR is required to execute `deploySharesContract`
	 *      and `registerSharesContract` functions
	 */
	uint32 public constant ROLE_SHARES_REGISTRAR = 0x0008_0000;

	/**
	 * @notice Factory deployment manager
	 *      - registers already deployed TradeableShares implementations to be used by the factory
	 *        to deploy the TradeableShares contracts EIP-1167 clones
	 *      - sets/unsets/updates the shares owner address `sharesOwnerAddress`
	 *
	 * @dev Role ROLE_SHARES_IMPLEMENTATION_REGISTRAR is required to execute functions:
	 *      - `setImplementationAddress`
	 *      - `setSharesOwnerAddress`
	 */
	uint32 public constant ROLE_FACTORY_DEPLOYMENT_MANAGER = 0x0010_0000;

	/**
	 * @dev Fired in setSharesOwnerAddress
	 *
	 * @param sharesOwnerAddress new shares owner address, or zero
	 */
	event SharesOwnerAddressUpdated(address indexed sharesOwnerAddress);

	/**
	 * @dev Fired in `setSharesImplAddress`
	 *
	 * @param implementationType TradeableShares implementation type
	 * @param implementationAddress the address of the already deployed TradeableShares implementation
	 *      corresponding to the given implementation type, or zero address
	 */
	event SharesImplAddressUpdated(ImplementationType implementationType, address implementationAddress);

	/**
	 * @dev Fired in `setDistributorImplAddress`
	 *
	 * @param implementationType HoldersRewardsDistributor implementation type
	 * @param implementationAddress the address of the already deployed HoldersRewardsDistributor implementation
	 *      corresponding to the given implementation type, or zero address
	 */
	event DistributorImplAddressUpdated(ImplementationType implementationType, address implementationAddress);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after proxy deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _paymentToken ERC20 payment token address to bind to, immutable
	 */
	function postConstruct(ERC1363 _paymentToken) public initializer {
		// execute parent initializer(s)
		__EIP712_init_unchained("SharesFactory", "1");
		_postConstruct(msg.sender);

		// verify token address is set
		require(address(_paymentToken) != address(0), "zero address");

		// set up the immutable ERC20 payment token contract
		paymentToken = _paymentToken;
	}

	/**
	 * @notice ERC1363 payment token contract which the factory uses to deploy the `ERC20` curve type
	 *
	 * @dev Immutable, client applications may cache this value
	 *
	 * @return ERC1363 payment token contract
	 */
	function getPaymentToken() public view returns(ERC1363) {
		// return the (effectively) immutable value from the storage
		return paymentToken;
	}

	/**
	 * @notice An address receiving the ownership of the deployed TradeableShares contracts
	 *
	 * @dev This should be the MultiSig address, not to EOA and not the
	 *      RBAC managed smart contract, so that this address cannot act in a scalable way;
	 *      this reduces the risk of misuse, and/or malicious use
	 *
	 * @return currently active shares owner address, or zero if not set
	 */
	function getSharesOwnerAddress() public view returns(address) {
		// read it from the storage
		return sharesOwnerAddress;
	}

	/**
	 * @notice Sets/unsets/updates the shares owner address `sharesOwnerAddress`, which is
	 *      an address receiving the ownership of the deployed TradeableShares contracts
	 *
	 * @dev This should be the MultiSig address, not to EOA and not the
	 *      RBAC managed smart contract, so that this address cannot act in a scalable way;
	 *      this reduces the risk of misuse, and/or malicious use
	 *
	 * @dev Once changed/set, the address affects only new TradeableShares deployments
	 *
	 * @param _sharesOwnerAddress new shares owner address to set, or zero to unset
	 */
	function setSharesOwnerAddress(address _sharesOwnerAddress) public {
		// verify the access permission
		require(isSenderInRole(ROLE_FACTORY_DEPLOYMENT_MANAGER), "access denied");

		// update the storage (note: this address is allowed to be zero)
		sharesOwnerAddress = _sharesOwnerAddress;

		// emit an event
		emit SharesOwnerAddressUpdated(_sharesOwnerAddress);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function getSharesImplAddress(ImplementationType _implementationType) public view returns(address) {
		// read the result from storage
		return sharesImplementations[_implementationType];
	}

	/**
	 * @notice Sets the address of the already deployed TradeableShares implementation
	 *      to be used by the factory to deploy the TradeableShares contracts EIP-1167 clones
	 *
	 * @param _implementationType TradeableShares implementation type
	 * @param _implementationAddress address of the already deployed TradeableShares implementation
	 *      corresponding to the given implementation type
	 */
	function setSharesImplAddress(ImplementationType _implementationType, address _implementationAddress) public {
		// verify the access permission
		require(isSenderInRole(ROLE_FACTORY_DEPLOYMENT_MANAGER), "access denied");

		// register/update/deregister implementation
		sharesImplementations[_implementationType] = _implementationAddress;

		// emit an event
		emit SharesImplAddressUpdated(_implementationType, _implementationAddress);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function getDistributorImplAddress(ImplementationType _implementationType) public view returns(address) {
		// read the result from storage
		return distributorsImplementations[_implementationType];
	}

	/**
	 * @notice Sets the address of the already deployed HoldersRewardsDistributor implementation
	 *      to be used by the factory to deploy the HoldersRewardsDistributor contracts EIP-1167 clones
	 *
	 * @param _implementationType HoldersRewardsDistributor implementation type
	 * @param _implementationAddress address of the already deployed HoldersRewardsDistributor implementation
	 *      corresponding to the given implementation type
	 */
	function setDistributorImplAddress(ImplementationType _implementationType, address _implementationAddress) public {
		// verify the access permission
		require(isSenderInRole(ROLE_FACTORY_DEPLOYMENT_MANAGER), "access denied");

		// register/update/deregister implementation
		distributorsImplementations[_implementationType] = _implementationAddress;

		// emit an event
		emit DistributorImplAddressUpdated(_implementationType, _implementationAddress);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function getProtocolFeeDestination() public view returns(address feeDestination) {
		// read the result from storage
		return protocolFeeDestination;
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function getProtocolFeePercent() public view returns(uint256 feePercent) {
		// read the result from storage
		return protocolFeePercent;
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function getHoldersFeePercent() public view returns(uint256 feePercent) {
		// read the result from storage
		return holdersFeePercent;
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function getSubjectFeePercent() public view returns(uint256 feePercent) {
		// read the result from storage
		return subjectFeePercent;
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function setProtocolFeeDestination(address _feeDestination) public {
		// verify the access permission
		require(isSenderInRole(ROLE_PROTOCOL_FEE_MANAGER), "access denied");
		// verify state change doesn't result into the discrepancy
		require(_feeDestination != address(0) || protocolFeePercent == 0, "protocolFeePercent must be set to zero first");

		// update contract's state
		protocolFeeDestination = _feeDestination;

		// emit an event
		emit ProtocolFeeUpdated(_feeDestination, protocolFeePercent, holdersFeePercent, subjectFeePercent);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function setProtocolFeePercent(uint64 _feePercent) public {
		// verify the access permission
		require(isSenderInRole(ROLE_PROTOCOL_FEE_MANAGER), "access denied");
		// verify state change doesn't result into the discrepancy
		require(_feePercent == 0 || protocolFeeDestination != address(0), "protocolFeeDestination must be set first");

		// update contract's state
		protocolFeePercent = _feePercent;

		// emit an event
		emit ProtocolFeeUpdated(protocolFeeDestination, _feePercent, holdersFeePercent, subjectFeePercent);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function setHoldersFeePercent(uint64 _feePercent) public {
		// verify the access permission
		require(isSenderInRole(ROLE_HOLDERS_FEE_MANAGER), "access denied");

		// update contract's state
		holdersFeePercent = _feePercent;

		// emit an event
		emit ProtocolFeeUpdated(protocolFeeDestination, protocolFeePercent, _feePercent, subjectFeePercent);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function setSubjectFeePercent(uint64 _feePercent) public {
		// verify the access permission
		require(isSenderInRole(ROLE_SUBJECT_FEE_MANAGER), "access denied");

		// update contract's state
		subjectFeePercent = _feePercent;

		// emit an event
		emit ProtocolFeeUpdated(protocolFeeDestination, protocolFeePercent, holdersFeePercent, _feePercent);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function setProtocolFee(
		address _protocolFeeDestination,
		uint64 _protocolFeePercent,
		uint64 _holdersFeePercent,
		uint64 _subjectFeePercent
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_PROTOCOL_FEE_MANAGER | ROLE_HOLDERS_FEE_MANAGER | ROLE_SUBJECT_FEE_MANAGER), "access denied");

		// verify state change doesn't result into the discrepancy
		require(_protocolFeePercent == 0 || _protocolFeeDestination != address(0), "zero address");

		// update contract's state
		protocolFeeDestination = _protocolFeeDestination;
		protocolFeePercent = _protocolFeePercent;
		holdersFeePercent = _holdersFeePercent;
		subjectFeePercent = _subjectFeePercent;

		// emit an event
		emit ProtocolFeeUpdated(_protocolFeeDestination, _protocolFeePercent, _holdersFeePercent, _subjectFeePercent);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function deploySharesContractPaused(
		ImplementationType _implementationType,
		TradeableShares.SharesSubject calldata _sharesSubject
	) public returns(TradeableShares) {
		// delegate to `deploySharesContractAndBuy`
		return deploySharesContractAndBuy(_implementationType, _sharesSubject, 0);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function deploySharesContract(
		ImplementationType _implementationType,
		TradeableShares.SharesSubject calldata _sharesSubject
	) public returns(TradeableShares) {
		// delegate to `deploySharesContractAndBuy`
		return deploySharesContractAndBuy(_implementationType, _sharesSubject, 1);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function deploySharesContractAndBuy(
		ImplementationType _implementationType,
		TradeableShares.SharesSubject calldata _sharesSubject,
		uint256 _amount
	) public payable returns(TradeableShares) {
		// delegate to `mintSubjectAndDeployShares`
		return mintSubjectAndDeployShares(_implementationType, _sharesSubject, msg.sender, _amount);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function mintSubjectAndDeployShares(
		ImplementationType _implementationType,
		TradeableShares.SharesSubject calldata _sharesSubject,
		address _issuer,
		uint256 _amount
	) public payable returns(TradeableShares) {
		// delegate to unsafe `__mintSubjectAndDeployShares`
		return __mintSubjectAndDeployShares(_implementationType, _sharesSubject, _issuer, _amount, msg.sender);
	}

	/**
	 * @dev Deploys the TradeableShares implementation for the specified subject;
	 *      allows to immediately buy any amount of shares (including zero)
	 *
	 * @dev Tries minting the NFT defined by the subject if it doesn't exist
	 *
	 * @dev Unsafe, uses the specified `_authorizedBy` to check the access permission, which
	 *      is either msg.sender, or the derived signer (if used in EIP712 meta tx mode)
	 *
	 * @param _implementationType TradeableShares implementation type
	 * @param _sharesSubject shares subject, owner of the curve
	 * @param _issuer an address to mint the NFT defined by the subject if it doesn't exist
	 * @param _amount how many shares to buy immediately after the deployment
	 * @param _authorizedBy must be either msg.sender or EIP712 signer if executed by the relayer
	 * @return deployed TradeableShares contract
	 */
	function __mintSubjectAndDeployShares(
		ImplementationType _implementationType,
		TradeableShares.SharesSubject calldata _sharesSubject,
		address _issuer,
		uint256 _amount,
		address _authorizedBy
	) private returns(TradeableShares) {
		// verify deployments are enabled
		require(isFeatureEnabled(FEATURE_SHARES_DEPLOYMENT_ENABLED), "shares deployments disabled");

		// verify paused deployments are enabled
		require(
			// zero amount means paused deployment
			_amount != 0 || isFeatureEnabled(FEATURE_ALLOW_PAUSED_DEPLOYMENTS)
				// we do not allow to bypass the feature with meta-tx
				|| isSenderInRole(ROLE_SHARES_REGISTRAR),
			"paused deployments disabled"
		);

		// verify exclusive buys are enabled (if exclusive buy is requested)
		require(
			_amount <= 1 || isFeatureEnabled(FEATURE_ALLOW_EXCLUSIVE_BUY)
				// we do not allow to bypass the feature with meta-tx
				|| isSenderInRole(ROLE_SHARES_REGISTRAR),
			"exclusive buys disabled"
		);

		// determine the issuer
		address issuer = _sharesSubject.getSharesIssuer();

		// verify the access permission:
		// contract can be deployed either by the shares subject owner, or by the shares registrar
		require(
			// contract can be deployed either by the shares subject owner
			msg.sender == issuer
			// or by the shares registrar (role)
			|| isOperatorInRole(_authorizedBy, ROLE_SHARES_REGISTRAR)
			// or by the ERC721 contract owner
			|| _authorizedBy == _sharesSubject.getCollectionOwner(),
			"access denied"
		);

		// if issuer couldn't determined, we might need to mint the corresponding NFT
		if(issuer == address(0)) {
			// ensure the address to mint to is defined
			// if not - we cannot mint, but the error is in the shares subject in the first place
			require(_issuer != address(0), "invalid subject");
			// try to mint, we expect this function to fail in case of an error
			MintableERC721(_sharesSubject.tokenAddress).mint(_issuer, _sharesSubject.tokenId);
			// set the issuer to the address NFT was minted to
			issuer = _issuer;
		}

		// at this point issuer cannot be zero, but it can be different from msg.sender
		assert(issuer != address(0));

		// get shares implementation address for the implementation type specified
		address sharesImplAddress = getSharesImplAddress(_implementationType);

		// verify the implementation address is registered for the implementation type specified
		require(sharesImplAddress != address(0), "implementation not registered");

		// "clone" the impl (deploy a minimalistic EIP-1167 proxy)
		TradeableShares sharesContract = TradeableShares(Clones.clone(sharesImplAddress));

		// get holders rewards distributor implementation address for the implementation type specified
		address distributorImplAddress = getDistributorImplAddress(_implementationType);

		// distributorImplAddress can be zero, in this case we will deploy the shares
		// without the HoldersRewardsDistributor attached to the contract
		HoldersRewardsDistributor distributorContract = HoldersRewardsDistributor(address(0));

		// if distributorImplAddress is defined, clone and initialize the HoldersRewardsDistributor
		if(distributorImplAddress != address(0)) {
			// "clone" the impl (deploy a minimalistic EIP-1167 proxy)
			distributorContract = HoldersRewardsDistributor(Clones.clone(distributorImplAddress));

			// proxy initialization logic is implementation dependent
			HoldersRewardsDistributorV1(payable(address(distributorContract))).postConstruct(
				sharesOwnerAddress,
				address(sharesContract),
				_implementationType == ImplementationType.ETH? address(0): address(paymentToken)
			);
		}

		// initialize TradeableShares EIP-1167 proxy
		__initSharesContract(sharesContract, distributorContract, _implementationType, _sharesSubject, _amount, issuer);

		// verify the shares subject is not yet mapped (not in use)
		bytes32 sharesKey = _sharesSubject.getSharesKey();
		require(address(shares[sharesKey]) == address(0), "subject in use");

		// register the deployed implementation into the mappings
		shares[sharesKey] = sharesContract;
		subjects[address(sharesContract)] = _sharesSubject;

		// emit an event
		emit SharesContractRegistered(issuer, sharesContract, distributorContract, _implementationType, _sharesSubject, true);

		// return the result - deployed address
		return sharesContract;
	}

	/**
	 * @dev Part of the `__mintSubjectAndDeployShares` routine moved into
	 *      a separate routine to fix the "Stack too deep" issue
	 */
	function __initSharesContract(
		TradeableShares _sharesContract,
		HoldersRewardsDistributor _distributorContract,
		ImplementationType _implementationType,
		TradeableShares.SharesSubject calldata _sharesSubject,
		uint256 _amount,
		address _beneficiary
	) private {
		// determine the effective shares holders fee percent
		// this also caches the fee on stack and saves a bit of gas
		uint64 _holdersFeePercent = address(_distributorContract) == address(0)? 0: holdersFeePercent;

		// proxy initialization logic is implementation dependent
		// switch(_implementationType)
		if(_implementationType == ImplementationType.ETH) {
			// initialize the Ethereum version by invoking the postConstruct on the proxy
			ETHShares(address(_sharesContract)).postConstruct{value: msg.value}(
				sharesOwnerAddress,
				_sharesSubject,
				protocolFeeDestination,
				protocolFeePercent,
				_distributorContract,
				_holdersFeePercent,
				subjectFeePercent,
				_amount,
				_beneficiary
			);
		}
		else if(_implementationType == ImplementationType.ERC20) {
			// factory doesn't support sending the change back
			require(msg.value == 0, "non-zero value");

			// if there is a request of the immediate shares buy
			if(_amount > 1) {
				// determine how much tokens we need
				uint256 toPay = _sharesContract.getBuyPriceAfterFee(0, _amount, protocolFeePercent, _holdersFeePercent, subjectFeePercent);
				// get the tokens required to buy
				require(paymentToken.transferFrom(msg.sender, address(this), toPay));
				// approve the tokens to be spent
				require(paymentToken.approve(address(_sharesContract), toPay));
			}

			// initialize the ERC20 version with the ERC20 as a payment token by invoking the postConstruct on the proxy
			ERC20Shares(address(_sharesContract)).postConstruct(
				sharesOwnerAddress,
				_sharesSubject,
				protocolFeeDestination,
				protocolFeePercent,
				_distributorContract,
				_holdersFeePercent,
				subjectFeePercent,
				_amount,
				_beneficiary,
				paymentToken
			);

			// if there was a request of the immediate shares buy
			if(_amount > 1) {
				// transfer the remaining tokens (if any) back to the sender
				require(paymentToken.transfer(msg.sender, paymentToken.balanceOf(address(this))));
			}
		}
		else {
			// throw if the implementation type is unknown
			// this must be an unreachable else block because the if-else blocks above
			// should have been taken care about all possible implementation types
			revert("unknown implementation type");
		}
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function executeDeploymentRequest(
		SharesDeploymentRequest calldata req,
		bytes calldata signature
	) public payable returns(TradeableShares) {
		// verify the request validity
		require(req.validFromTimestamp <= block.timestamp, "not yet valid");
		require(req.expiresAtTimestamp > block.timestamp, "expired");

		// verify and use nonce
		__useNonce(req.issuer, req.nonce);

		// derive the request signer
		// this also verifies that the signature is valid
		address signer = _hashTypedDataV4(req.hashStruct()).recover(signature);

		// delegate to unsafe `__mintSubjectAndDeployShares`
		return __mintSubjectAndDeployShares(req.implementationType, req.sharesSubject, req.issuer, req.amount, signer);
	}

	/**
	 * @dev Verifies the nonce is valid and marks it as used
	 *      Throws if nonce is already used or if it is invalid
	 *
	 * @param _issuer the owner of the nonce
	 * @param _nonce the nonce to be used
	 */
	function __useNonce(address _issuer, uint256 _nonce) private {
		// verify the nonce wasn't yet used and use it
		require(nonces[_issuer]++ == _nonce, "invalid nonce");

		// emit an event
		emit NonceUsed(_issuer, _nonce);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function getNonce(address _issuer) external view returns(uint256) {
		// read the nonce from the storage
		return nonces[_issuer];
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function rewindNonce(address _issuer, uint256 _nonce) external {
		// verify the access permission
		require(isSenderInRole(ROLE_SHARES_REGISTRAR), "access denied");

		// make sure nonce is not decreasing
		require(nonces[_issuer] < _nonce, "new nonce must be bigger than the current one");

		// rewind the nonce to the value requested
		nonces[_issuer] = _nonce;

		// emit an event
		emit NonceUsed(_issuer, _nonce - 1);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function lookupSharesContract(
		TradeableShares.SharesSubject calldata _sharesSubject
	) public view returns(TradeableShares) {
		return shares[_sharesSubject.getSharesKey()];
	}

	/**
	 * @inheritdoc SharesFactory
	 *
	 * @dev Note: this restricted function allows the authorized address to register
	 *      the shares contract with the invalid subject
	 */
	function registerSharesContract(TradeableShares _sharesContract) external {
		// verify the access permission: contract can be registered only by the shares registrar
		require(isSenderInRole(ROLE_SHARES_REGISTRAR), "access denied");

		// delegate to unsafe `__registerSharesContract`
		__registerSharesContract(_sharesContract);
	}

	/**
	 * @inheritdoc SharesFactory
	 */
	function notifySubjectUpdated() external {
		// read the registered subject (this can be zero if not registered)
		TradeableShares.SharesSubject memory registeredSubject = subjects[msg.sender];

		// ensure the subject is registered (we know the caller, we already registered it)
		require(!registeredSubject.isZero(), "not registered");
		// we do not allow binding to non-existent NFTs (consistency with `__mintSubjectAndDeployShares`)
		require(TradeableShares(msg.sender).getSharesSubject().getSharesIssuer() != address(0), "invalid subject");

		// delegate to unsafe `__registerSharesContract`
		__registerSharesContract(TradeableShares(msg.sender));
	}

	/**
	 * @dev Registers the TradeableShares contract;
	 *      unsafe, doesn't verify the access permissions, must be kept private at all times
	 *
	 * @param _sharesContract TradeableShares contract to register
	 */
	function __registerSharesContract(TradeableShares _sharesContract) private {
		// determine current shares subject
		TradeableShares.SharesSubject memory sharesSubject = _sharesContract.getSharesSubject();
		// this contract may had already been registered under the different subject
		TradeableShares.SharesSubject memory registeredSubject = subjects[address(_sharesContract)];

		// if it was already registered and subject didn't change there is nothing to do
		if(sharesSubject.equals(registeredSubject)) {
			// exit from the function silently
			return;
		}

		// verify the shares subject is not yet mapped (not in use)
		bytes32 sharesKey = sharesSubject.getSharesKey();
		require(address(shares[sharesKey]) == address(0), "subject in use");

		// cleanup previously registered subject mapping if any
		delete shares[registeredSubject.getSharesKey()];

		// register the deployed implementation into the mappings
		shares[sharesKey] = _sharesContract;
		subjects[address(_sharesContract)] = sharesSubject;

		// emit an event
		emit SharesContractRegistered(
			_sharesContract.getSharesIssuer(),
			_sharesContract,
			_sharesContract.getHoldersFeeDestination(),
			determineImplementationType(_sharesContract),
			_sharesContract.getSharesSubject(),
			false
		);
	}

	/**
	 * @notice Tries to determine the implementation type of the already deployed TradeableShares contract;
	 *      the result should not be considered reliable and can be used only as a hint
	 *
	 * @param _sharesContract deployed TradeableShares instance
	 * @return implementation type of the instance specified
	 */
	function determineImplementationType(TradeableShares _sharesContract) public view returns(ImplementationType) {
		// determine the implementation type
		ImplementationType implementationType;

		// try to treat the implementation as ERC20
		try ERC20Shares(address(_sharesContract)).getPaymentToken() returns (ERC1363 token) {
			// for the ERC20Shares impl we support only ERC20 token known to factory
			require(token == paymentToken, "unknown ERC20 implementation type");

			// implementation type is successfully determined as ERC20
			implementationType = ImplementationType.ERC20;
		}
		catch {
			// fallback to ETH
			implementationType = ImplementationType.ETH;
		}

		// return the result
		return implementationType;
	}
}
