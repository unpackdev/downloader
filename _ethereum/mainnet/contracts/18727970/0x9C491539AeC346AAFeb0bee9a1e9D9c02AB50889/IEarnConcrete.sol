// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEarnConcrete {
	enum InterestType {
		FIXED,
		FLOATING
	}

	struct InputSlotInfo {
		address currency;
		address supervisor;
		uint256 issueQuota;
		InterestType interestType;
		int32 interestRate;
		uint64 valueDate;
		uint64 maturity;
		uint64 createTime;
		bool transferable;
		string externalURI;
	}

	struct SlotBaseInfo {
		address issuer;
		address currency;
		uint64 valueDate;
		uint64 maturity;
		uint64 createTime;
		bool transferable;
		bool isValid;
	}

	struct SlotExtInfo {
		address supervisor;
		uint256 issueQuota;
		InterestType interestType;
		int32 interestRate;
		bool isInterestRateSet;
		string externalURI;
	}

	function slotBaseInfo(uint256 slot_) external returns (SlotBaseInfo memory);
	function slotExtInfo(uint256 slot_) external returns (SlotExtInfo memory);
	function isSlotTransferable(uint256 slot_) external returns (bool);
	function isCurrencyAllowed(address currency_) external returns (bool);

	function setCurrencyOnlyDelegate(address currency_, bool isAllowed_) external;
	function setInterestRateOnlyDelegate(address txSender_, uint256 slot_, int32 interestRate_) external;
}