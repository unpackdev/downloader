//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSetUpgradeable.sol";

contract FactoryStorage {
	enum FactoryType {Unique, Multiple}

	struct DonationRecipient {
		bool autoDonation;
		address recipient;
		string name;
	}

	struct TokenSwap {
		bool is1155;
		bool fixedId;
		address swapContract;
		uint256 swapTokenId;
	}

	struct Factory {
		// factory type
		FactoryType factoryType;
		// factory creator
		address creator;
		// if factory is active or not
		// this is changed by beyondNFT admins if abuse with factories
		bool active;
		// if factory is paused or not <- this is changed by creator
		bool paused;
		// if the factory requires a seed
		bool withSeed;
		// the contract this factory mint with
		address consumer;
		// donation amount, 2.5% (250) is the minimum amount
		uint16 donationAmount;
		// id of the donation recipient for this factory
		// this id must be id + 1, so 0 can be considered as automatic
		uint256 donationId;
		// price to mint
		uint256 price;
		// how many were minted already
		uint256 created;
		// 0 if infinite
		uint256 maxSupply;
		// royalties
		uint256 royaltyValue;
		// The factory metadata uri, contains all informations about where to find code, properties etc...
		// this is the base that will be used to create NFTs
		string metadata;
	}

	struct ContractConfiguration {
		bool restricted;
		bool defaultFactoryActivation;
		address uniqueConsumer;
		address editionsConsumer;
		bool canEditPlatformFees;
		uint16 platformFee;
		uint16 donationMinimum;
		address payable platformBeneficiary;
	}

	ContractConfiguration public contractConfiguration;

	uint256 public factoriesCount;

	// the factories
	mapping(uint256 => Factory) public factories;

	// some factories allow to swap other contracts token again one from the factory
	mapping(uint256 => TokenSwap) public factorySwap;

	// the seeds already used by each factories
	// not in the struct as it complicated things
	mapping(uint256 => mapping(bytes32 => bool)) public factoriesSeed;

	DonationRecipient[] public donationRecipients;

	uint256 donationCursor;
	EnumerableSetUpgradeable.UintSet internal autoDonations;
}
