//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./FactoryStorage.sol";
import "./IFactoryConsumer.sol";

contract BeyondFactories is OwnableUpgradeable, PausableUpgradeable, FactoryStorage {
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

	// emitted when a factory is created
	event FactoryCreated(uint256 indexed id, address indexed creator, string metadata);

	// emitted when factories are updated (active, paused, price, metadata...)
	event FactoriesUpdate(uint256[] factoryIds);

	// emitted when a factory has reached its max supply
	event FactoryOut(uint256 indexed id);

	// emitted when a donation recipient is created or modified
	event DonationRecipientsUpdate(uint256[] ids);

	// emitted when configuration changed
	event ConfigurationUpdate();

	// emitted when a tokenId is minted from a factory
	event MintFromFactory(
		uint256 indexed factoryId,
		address indexed minter,
		uint256 createdIndex, // index in factory
		address registry,
		uint256 tokenId,
		bytes32 data,
		string seed,
		uint256 price
	);

	/**
	 * @dev initialize function
	 */
	function initialize(
		address payable platformBeneficiary,
		uint16 platformFee,
		uint16 donationMinimum,
		bool restricted,
		bool defaultActive,
		bool canEditPlatformFees,
		address ownedBy
	) public initializer {
		__Ownable_init();
		__Pausable_init();

		contractConfiguration.platformBeneficiary = platformBeneficiary;
		contractConfiguration.platformFee = platformFee;
		contractConfiguration.donationMinimum = donationMinimum;
		contractConfiguration.canEditPlatformFees = canEditPlatformFees;

		// defines if factory are active by defualt or not
		contractConfiguration.defaultFactoryActivation = defaultActive;

		// if the factory is restricted
		contractConfiguration.restricted = restricted;

		if (address(0) != ownedBy) {
			transferOwnership(ownedBy);
		}
	}

	/**
	 * @dev called by creators or admin to register a new factory
	 *
	 * @param factoryType - if unique (erc721) or edition (erc1155)
	 * @param creator - the factory creator, is used when contract is restricted
	 * @param paused - if the factory starts paused
	 * @param price - factory price, in wei
	 * @param maxSupply - times this factory can be used; 0 = inifinity
	 * @param withSeed - if the factory needs a seed when creating
	 * @param metadata - factory metadata uri - ipfs uri most of the time
	 */
	function registerFactory(
		FactoryType factoryType, // if erc721 or erc1155
		address creator,
		bool paused, // if the factory start paused
		uint256 price, // factory price, in wei
		uint256 maxSupply, // max times this factory can be used; 0 = inifinity
		bool withSeed, // if the factory needs a seed when creating
		string memory metadata,
		uint256 royaltyValue,
		address consumer
	) external {
		require(bytes(metadata).length > 0, 'Need metadata URI');
		ContractConfiguration memory _configuration = contractConfiguration;
		require(!_configuration.restricted || owner() == _msgSender(), 'Restricted.');

		// Restricted contracts only allow OPERATORS to mint
		if (creator == address(0)) {
			creator = msg.sender;
		}

		// if no consumer given, take one of the default
		if (consumer == address(0)) {
			if (factoryType == FactoryType.Unique) {
				consumer = _configuration.uniqueConsumer;
			} else {
				consumer = _configuration.editionsConsumer;
			}
		}

		uint256 factoryId = factoriesCount + 1;
		factories[factoryId] = Factory({
			factoryType: factoryType,
			creator: creator,
			active: _configuration.defaultFactoryActivation,
			paused: paused,
			price: price,
			maxSupply: maxSupply,
			withSeed: withSeed,
			royaltyValue: royaltyValue,
			metadata: metadata,
			created: 0,
			consumer: consumer,
			donationId: 0,
			donationAmount: _configuration.donationMinimum
		});
		factoriesCount = factoryId;

		emit FactoryCreated(factoryId, creator, metadata);
	}

	/**
	 * @dev Function to mint a token without any seed
	 *
	 * @param factoryId id of the factory to mint from
	 * @param amount - amount to mint; only for Editions factories
	 * @param to - address to mint to, if address(0), msg.sender
	 * @param swapContract - address of the contract if this is a swap
	 * @param swapTokenId - id of the token if it's a swap
	 */
	function mintFrom(
		uint256 factoryId,
		uint256 amount,
		address to,
		address swapContract,
		uint256 swapTokenId
	) external payable {
		_mintFromFactory(factoryId, '', '', amount, to, swapContract, swapTokenId);
	}

	/**
	 * @dev Function to mint a token from a factory with a 32 bytes hex string as has
	 *
	 * @param factoryId id of the factory to mint from
	 * @param seed The hash used to create the seed
	 * @param amount - amount to mint; only for Editions factories
	 * @param to - address to mint to, if address(0), msg.sender
	 * @param swapContract - address of the contract if this is a swap
	 * @param swapTokenId - id of the token if it's a swap
	 *
	 * Seed will be used to create, off-chain, the token unique seed with the function:
	 * tokenSeed = sha3(blockHash, factoryId, createdIndex, minter, registry, tokenId, seed)
	 *
	 * There is as much chance of collision than there is on creating a duplicate
	 * of an ethereum private key, which is low enough to not go to crazy length in
	 * order to try to stop the "almost impossible"
	 *
	 * I thought about using a commit/reveal (revealed at the time of nft metadata creation)
	 * But this could break the token generation if, for example, the reveal was lost (db problem)
	 * between the function call and the reveal.
	 *
	 *
	 * All in all, using the blockhash in the seed makes this as secure as "on-chain pseudo rng".
	 *
	 * Also with this method, all informations to recreate the token can always be retrieved from the events.
	 */
	function mintWithHash(
		uint256 factoryId,
		bytes32 seed,
		uint256 amount,
		address to,
		address swapContract,
		uint256 swapTokenId
	) external payable {
		require(seed != 0x0, 'Invalid seed');
		_mintFromFactory(factoryId, seed, '', amount, to, swapContract, swapTokenId);
	}

	/**
	 * @dev Function to mint a token from a factory with a known seed
	 *
	 * This known seed can either be:
	 * - a user inputed seed
	 * - the JSON string of the factory properties. Allowing for future reconstruction of nft metadata if needed
	 *
	 * @param factoryId id of the factory to mint from
	 * @param seed The seed used to mint
	 * @param amount - amount to mint; only for Editions factories
	 * @param to - address to mint to, if address(0), msg.sender
	 * @param swapContract - address of the contract if this is a swap
	 * @param swapTokenId - id of the token if it's a swap
	 */
	function mintWithOpenSeed(
		uint256 factoryId,
		string memory seed,
		uint256 amount,
		address to,
		address swapContract,
		uint256 swapTokenId
	) external payable {
		require(bytes(seed).length > 0, 'Invalid seed');
		_mintFromFactory(
			factoryId,
			keccak256(abi.encodePacked(seed)),
			seed,
			amount,
			to,
			swapContract,
			swapTokenId
		);
	}

	/**
	 * @dev allows a creator to pause / unpause the use of their Factory
	 */
	function setFactoryPause(uint256 factoryId, bool isPaused) external {
		Factory storage factory = factories[factoryId];
		require(msg.sender == factory.creator, 'Not factory creator');
		factory.paused = isPaused;

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	/**
	 * @dev allows a creator to update the price of their factory
	 */
	function setFactoryPrice(uint256 factoryId, uint256 price) external {
		Factory storage factory = factories[factoryId];
		require(msg.sender == factory.creator, 'Not factory creator');
		factory.price = price;

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	/**
	 * @dev allows a creator to define a swappable factory
	 */
	function setFactorySwap(
		uint256 factoryId,
		address swapContract,
		uint256 swapTokenId,
		bool fixedId
	) external {
		Factory storage factory = factories[factoryId];
		require(msg.sender == factory.creator, 'Not factory creator');
		if (swapContract == address(0)) {
			delete factorySwap[factoryId];
		} else {
			factorySwap[factoryId] = TokenSwap({
				is1155: IERC1155Upgradeable(swapContract).supportsInterface(0xd9b67a26),
				fixedId: fixedId,
				swapContract: swapContract,
				swapTokenId: swapTokenId
			});
		}

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	/**
	 * @dev allows a creator to define to which orga they want to donate if not automatic
	 * and how much (minimum 2.50, taken from the BeyondNFT 10%)
	 *
	 * Be careful when using this:
	 * - if donationId is 0, then the donation will be automatic
	 * if you want to set a specific donation id, always use id + 1
	 */
	function setFactoryDonation(
		uint256 factoryId,
		uint256 donationId,
		uint16 donationAmount
	) external {
		Factory storage factory = factories[factoryId];
		require(msg.sender == factory.creator, 'Not factory creator');

		// if 0, set automatic;
		factory.donationId = donationId;

		// 2.50 is the minimum that can be set
		// those 2.50 are taken from BeyondNFT share of 10%
		if (donationAmount >= contractConfiguration.donationMinimum) {
			factory.donationAmount = donationAmount;
		}

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	/**
	 * @dev allows to activate and deactivate factories
	 *
	 * Because BeyondNFT is an open platform with no curation prior factory creation
	 * This can only be called by BeyondNFT administrators, if there is any abuse with a factory
	 */
	function setFactoryActiveBatch(uint256[] memory factoryIds, bool[] memory areActive)
		external
		onlyOwner
	{
		for (uint256 i; i < factoryIds.length; i++) {
			Factory storage factory = factories[factoryIds[i]];
			require(address(0) != factory.creator, 'Factory not found');

			factory.active = areActive[i];
		}
		emit FactoriesUpdate(factoryIds);
	}

	/**
	 * @dev allows to set a factory consumer
	 */
	function setFactoryConsumerBatch(uint256[] memory factoryIds, address[] memory consumers)
		external
		onlyOwner
	{
		for (uint256 i; i < factoryIds.length; i++) {
			Factory storage factory = factories[factoryIds[i]];
			require(address(0) != factory.creator, 'Factory not found');

			factory.consumer = consumers[i];
		}
		emit FactoriesUpdate(factoryIds);
	}

	/**
	 * @dev adds Donation recipients
	 */
	function addDonationRecipientsBatch(
		address[] memory recipients,
		string[] memory names,
		bool[] memory autos
	) external onlyOwner {
		DonationRecipient[] storage donationRecipients_ = donationRecipients;
		EnumerableSetUpgradeable.UintSet storage autoDonations_ = autoDonations;
		uint256[] memory ids = new uint256[](recipients.length);
		for (uint256 i; i < recipients.length; i++) {
			require(bytes(names[i]).length > 0, 'Invalid name');
			donationRecipients_.push(
				DonationRecipient({
					autoDonation: autos[i],
					recipient: recipients[i],
					name: names[i]
				})
			);
			ids[i] = donationRecipients_.length - 1;
			if (autos[i]) {
				autoDonations_.add(ids[i]);
			}
		}
		emit DonationRecipientsUpdate(ids);
	}

	/**
	 * @dev modify Donation recipients
	 */
	function setDonationRecipientBatch(
		uint256[] memory ids,
		address[] memory recipients,
		string[] memory names,
		bool[] memory autos
	) external onlyOwner {
		DonationRecipient[] storage donationRecipients_ = donationRecipients;
		EnumerableSetUpgradeable.UintSet storage autoDonations_ = autoDonations;
		for (uint256 i; i < recipients.length; i++) {
			if (address(0) != recipients[i]) {
				donationRecipients_[ids[i]].recipient = recipients[i];
			}

			if (bytes(names[i]).length > 0) {
				donationRecipients_[ids[i]].name = names[i];
			}

			donationRecipients_[ids[i]].autoDonation = autos[i];
			if (autos[i]) {
				autoDonations_.add(ids[i]);
			} else {
				autoDonations_.remove(ids[i]);
			}
		}

		emit DonationRecipientsUpdate(ids);
	}

	/**
	 * @dev allows to update a factory metadata
	 *
	 * This can only be used by admins in very specific cases when a critical bug is found
	 */
	function setFactoryMetadata(uint256 factoryId, string memory metadata) external onlyOwner {
		Factory storage factory = factories[factoryId];
		require(address(0) != factory.creator, 'Factory not found');
		factory.metadata = metadata;

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	function setPlatformFee(uint16 fee) external onlyOwner {
		require(contractConfiguration.canEditPlatformFees == true, "Can't edit platform fees");
		require(fee <= 10000, 'Fees too high');
		contractConfiguration.platformFee = fee;
		emit ConfigurationUpdate();
	}

	function setPlatformBeneficiary(address payable beneficiary) external onlyOwner {
		require(contractConfiguration.canEditPlatformFees == true, "Can't edit platform fees");
		require(address(beneficiary) != address(0), 'Invalid beneficiary');
		contractConfiguration.platformBeneficiary = beneficiary;
		emit ConfigurationUpdate();
	}

	function setDefaultFactoryActivation(bool isDefaultActive) external onlyOwner {
		contractConfiguration.defaultFactoryActivation = isDefaultActive;
		emit ConfigurationUpdate();
	}

	function setRestricted(bool restricted) external onlyOwner {
		contractConfiguration.restricted = restricted;
		emit ConfigurationUpdate();
	}

	function setFactoriesConsumers(address unique, address editions) external onlyOwner {
		if (address(0) != unique) {
			contractConfiguration.uniqueConsumer = unique;
		}

		if (address(0) != editions) {
			contractConfiguration.editionsConsumer = editions;
		}

		emit ConfigurationUpdate();
	}

	/**
	 * @dev Pauses all token creation.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `DEFAULT_ADMIN_ROLE`.
	 */
	function pause() public virtual onlyOwner {
		_pause();
	}

	/**
	 * @dev Unpauses all token creation.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `DEFAULT_ADMIN_ROLE`.
	 */
	function unpause() public virtual onlyOwner {
		_unpause();
	}

	/**
	 * @dev This function does the minting process.
	 * It checkes that the factory exists, and if there is a seed, that it wasn't already
	 * used for it.
	 *
	 * Depending on the factory type, it will call the right contract to mint the token
	 * to msg.sender
	 *
	 * Requirements:
	 * - contract musn't be paused
	 * - If there is a seed, it must not have been used for this Factory
	 */
	function _mintFromFactory(
		uint256 factoryId,
		bytes32 seed,
		string memory openSeed,
		uint256 amount,
		address to,
		address swapContract,
		uint256 swapTokenId
	) internal whenNotPaused {
		require(amount >= 1, 'Amount is zero');

		Factory storage factory = factories[factoryId];

		require(factory.active && !factory.paused, 'Factory inactive or not found');
		require(
			factory.maxSupply == 0 || factory.created < factory.maxSupply,
			'Factory max supply reached'
		);

		// if the factory requires a seed (user seed, random seed)
		if (factory.withSeed) {
			// verify that the seed is not empty and that it was never used before
			// for this factory
			require(
				seed != 0x0 && factoriesSeed[factoryId][seed] == false,
				'Invalid seed or already taken'
			);
			factoriesSeed[factoryId][seed] = true;
		}

		factory.created++;

		address consumer = _doPayment(factoryId, factory, swapContract, swapTokenId);

		// if people mint to another address
		if (to == address(0)) {
			to = msg.sender;
		}

		uint256 tokenId =
			IFactoryConsumer(consumer).mint(
				to,
				factoryId,
				amount,
				factory.creator,
				factory.royaltyValue
			);

		// emit minting from factory event with data and seed
		emit MintFromFactory(
			factoryId,
			to,
			factory.created,
			consumer,
			tokenId,
			seed,
			openSeed,
			msg.value
		);

		if (factory.created == factory.maxSupply) {
			emit FactoryOut(factoryId);
		}
	}

	function _doPayment(
		uint256 factoryId,
		Factory storage factory,
		address swapContract,
		uint256 swapTokenId
	) internal returns (address) {
		ContractConfiguration memory contractConfiguration_ = contractConfiguration;
		// try swap
		if (swapContract != address(0)) {
			TokenSwap memory swap = factorySwap[factoryId];

			// verify that the swap asked is the right one
			require(
				// contract match
				swap.swapContract == swapContract &&
					// and either ANY idea id works, either the given ID is the right one
					(!swap.fixedId || swap.swapTokenId == swapTokenId),
				'Invalid swap'
			);
			require(msg.value == 0, 'No value allowed when swapping');

			// checking if ERC1155 or ERC721
			// and burn the tokenId
			// using 0xdead address to be sure it works with contracts
			// that have no burn function
			//
			// those functions calls should revert if there is a problem when transfering
			if (swap.is1155) {
				IERC1155Upgradeable(swapContract).safeTransferFrom(
					msg.sender,
					address(0xdEaD),
					swapTokenId,
					1,
					''
				);
			} else {
				IERC721Upgradeable(swapContract).transferFrom(
					msg.sender,
					address(0xdEaD),
					swapTokenId
				);
			}
		} else if (factory.price > 0) {
			require(msg.value == factory.price, 'Wrong value sent');

			uint256 platformFee = (msg.value * uint256(contractConfiguration_.platformFee)) / 10000;

			DonationRecipient[] memory donationRecipients_ = donationRecipients;
			uint256 donation;
			if (donationRecipients_.length > 0) {
				donation = (msg.value * uint256(factory.donationAmount)) / 10000;

				// send fees to platform
				contractConfiguration_.platformBeneficiary.transfer(platformFee);

				if (factory.donationId > 0) {
					payable(donationRecipients_[factory.donationId - 1].recipient).transfer(
						donation
					);
				} else {
					// send to current cursor
					EnumerableSetUpgradeable.UintSet storage autoDonations_ = autoDonations;

					payable(donationRecipients_[autoDonations_.at(donationCursor)].recipient)
						.transfer(donation);
					donationCursor = (donationCursor + 1) % autoDonations_.length();
				}
			}

			// send rest to creator
			payable(factory.creator).transfer(msg.value - platformFee - donation);
		}

		if (factory.consumer != address(0)) {
			return factory.consumer;
		}

		return
			factory.factoryType == FactoryType.Multiple
				? contractConfiguration_.editionsConsumer
				: contractConfiguration_.uniqueConsumer;
	}

	function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;

		return array;
	}

	/**
	 * @dev do not accept value sent directly to contract
	 */
	receive() external payable {
		revert('No value accepted');
	}
}
