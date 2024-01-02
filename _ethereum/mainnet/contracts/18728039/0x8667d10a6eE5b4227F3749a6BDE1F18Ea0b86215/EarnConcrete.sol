//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Constants.sol";
import "./ERC20TransferHelper.sol";
import "./SFTIssuableConcrete.sol";
import "./MultiRechargeableConcrete.sol";
import "./MultiRepayableConcrete.sol";
import "./IERC20Metadata.sol";
import "./IEarnConcrete.sol";

contract EarnConcrete is IEarnConcrete, SFTIssuableConcrete, MultiRepayableConcrete {

    mapping(address => bool) internal _allowCurrencies;
    mapping(uint256 => SlotBaseInfo) internal _slotBaseInfos;
    mapping(uint256 => SlotExtInfo) internal _slotExtInfos;

    function initialize() external initializer {
        __SFTIssuableConcrete_init();
	}

    function setCurrencyOnlyDelegate(address currency_, bool isAllowed_) external override onlyDelegate {
        _setCurrency(currency_, isAllowed_);
    }

	function setInterestRateOnlyDelegate(address txSender_, uint256 slot_, int32 interestRate_) external override onlyDelegate {
        SlotExtInfo storage extInfo = _slotExtInfos[slot_];
        require(extInfo.interestType == InterestType.FLOATING, "EarnConcrete: not floating interest");
        require(txSender_ == extInfo.supervisor, "EarnConcrete: only supervisor");
        require(slotTotalValue(slot_) == slotInitialValue(slot_), "EarnConcrete: already claimed");

        extInfo.interestRate = interestRate_;
        extInfo.isInterestRateSet = true;
    }

    function claimableValue(uint256 tokenId_) public view virtual override returns (uint256) {
        uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
        if (_slotExtInfos[slot].interestType == InterestType.FLOATING && !_slotExtInfos[slot].isInterestRateSet) {
            return 0;
        }
        return super.claimableValue(tokenId_);
    }

    function getSlot(address issuer_, address currency_, uint64 valueDate_, uint64 maturity_, uint64 createTime_, bool transferable_) public view returns (uint256) {
		uint256 chainId;
        assembly { chainId := chainid() }
		return uint256(keccak256(abi.encodePacked(chainId, delegate(), issuer_, currency_, valueDate_, maturity_, createTime_, transferable_)));
	}

    function slotBaseInfo(uint256 slot_) external view override returns (SlotBaseInfo memory) {
        return _slotBaseInfos[slot_];
    }

    function slotExtInfo(uint256 slot_) external view override returns (SlotExtInfo memory) {
        return _slotExtInfos[slot_];
    }

    function _isSlotValid(uint256 slot_) internal view virtual override returns (bool) {
        return _slotBaseInfos[slot_].isValid;
    }

    function _createSlot(address txSender_, bytes memory inputSlotInfo_) internal virtual override returns (uint256 slot_) {
        InputSlotInfo memory input = abi.decode(inputSlotInfo_, (InputSlotInfo));
        _validateSlotInfo(input);

        require(_allowCurrencies[input.currency], "EarnConcrete: currency not allowed");

        SlotBaseInfo memory baseInfo = SlotBaseInfo({
            issuer: txSender_,
            currency: input.currency,
            valueDate: input.valueDate,
            maturity: input.maturity,
            createTime: input.createTime,
            transferable: input.transferable,
            isValid: true
        });

        slot_ = getSlot(txSender_, input.currency, input.valueDate, input.maturity, input.createTime, input.transferable);

        _slotBaseInfos[slot_] = baseInfo;
        _slotExtInfos[slot_] = SlotExtInfo({
            supervisor: input.supervisor,
            issueQuota: input.issueQuota,
            interestType: input.interestType,
            interestRate: input.interestRate,
            isInterestRateSet: input.interestType == InterestType.FIXED,
            externalURI: input.externalURI
        });
    }

    function _mint(address /** txSender_ */, address currency_, address /** mintTo_ */, uint256 slot_, uint256 /** tokenId_ */, uint256 /** amount_ */) internal virtual override {
        SlotBaseInfo storage base = _slotBaseInfos[slot_];
        require(base.isValid, "EarnConcrete: invalid slot");
        require(base.currency == currency_, "EarnConcrete: currency not match");

        uint256 issueQuota = _slotExtInfos[slot_].issueQuota;
        uint256 issuedAmount = MultiRepayableConcrete.slotInitialValue(slot_);
        require(issuedAmount <= issueQuota, "EarnConcrete: issueQuota exceeded");
    }

    function _validateSlotInfo(InputSlotInfo memory input_) internal view virtual {
        require(input_.valueDate > block.timestamp, "EarnConcrete: invalid valueDate");
        require(input_.maturity > input_.valueDate, "EarnConcrete: invalid maturity");
    }

    function isSlotTransferable(uint256 slot_) external view override returns (bool) {
        return _slotBaseInfos[slot_].transferable;
    }

    function isCurrencyAllowed(address currency_) external view returns (bool) {
        return _allowCurrencies[currency_];
    }

    function _setCurrency(address currency_, bool isAllowed_) internal virtual {
        _allowCurrencies[currency_] = isAllowed_;
    }

	function _currency(uint256 slot_) internal view virtual override returns (address) {
        return _slotBaseInfos[slot_].currency;
    }

    function _repayRate(uint256 slot_) internal view virtual override returns (uint256) {
        SlotBaseInfo storage baseInfo = _slotBaseInfos[slot_];
        SlotExtInfo storage extInfo = _slotExtInfos[slot_];

        uint256 scaledFullPercentage = uint256(Constants.FULL_PERCENTAGE) * MultiRepayableConcrete.REPAY_RATE_SCALAR;
        uint256 scaledPositiveInterestRate = 
            (extInfo.interestRate < 0 ? uint256(int256(0 - extInfo.interestRate)) : uint256(int256(extInfo.interestRate))) * 
            MultiRepayableConcrete.REPAY_RATE_SCALAR * (baseInfo.maturity - baseInfo.valueDate) / Constants.SECONDS_PER_YEAR;

        return extInfo.interestRate < 0 ? scaledFullPercentage - scaledPositiveInterestRate : scaledFullPercentage + scaledPositiveInterestRate;
    }

    function _beforeRepayWithBalance(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) internal virtual override {
        super._beforeRepayWithBalance(txSender_, slot_, currency_, repayCurrencyAmount_);
        require(txSender_ == _slotBaseInfos[slot_].issuer, "EarnConcrete: only issuer");
    }
}
