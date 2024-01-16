// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./AdminControl.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC20TransferHelper.sol";
import "./ERC20Upgradeable.sol";
import "./IBondPool.sol";

contract BondPool is IBondPool, AdminControl, ReentrancyGuardUpgradeable {
    
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(uint256 => SlotDetail) internal _slotDetails;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal _issuerSlots;

    mapping(uint256 => uint256) public slotBalances;

    uint8 public valueDecimals;

    address public fundCurrency;

    address public voucher;

    string public issuerName;

    modifier onlyVoucher() {
        require(_msgSender() == voucher, "only voucher");
        _;
    }

    function initialize(uint8 valueDecimals_, address fundCurrency_, string calldata issuerName_) external initializer {
        AdminControl.__AdminControl_init(_msgSender());
        valueDecimals = valueDecimals_;
        fundCurrency = fundCurrency_;
        issuerName = issuerName_;
    }

    function createSlot(
        address issuer_,
        uint64 effectiveTime_,
        uint64 maturity_
    ) external onlyVoucher returns (uint256 slot) {
        validateSlotParams(issuer_, effectiveTime_, maturity_);

        slot = getSlot(issuer_, effectiveTime_, maturity_);
        require(!_slotDetails[slot].isValid, "slot already existed");

        SlotDetail storage slotDetail = _slotDetails[slot];
        slotDetail.issuer = issuer_;
        slotDetail.effectiveTime = effectiveTime_;
        slotDetail.maturity = maturity_;
        slotDetail.isValid = true;

        _issuerSlots[issuer_].add(slot);

        emit CreateSlot(slot, issuer_, effectiveTime_, maturity_);
    }

    function validateSlotParams(
        address issuer_,
        uint64 effectiveTime_,
        uint64 maturity_
    ) public pure {
        require(issuer_ != address(0), "issuer cannot be 0 address");
        require(effectiveTime_ > 0 && effectiveTime_ < maturity_, "invalid time");
    }

    function mint(
        address minter_,
        uint256 slot_,
        uint256 mintValue_
    ) external override nonReentrant onlyVoucher {
        require(minter_ != address(0), "minter cannot be 0 address");
        require(mintValue_ != 0, "mint value cannot be 0");
        SlotDetail storage slotDetail = _slotDetails[slot_];
        require(slotDetail.isValid, "invalid slot");
        require(
            !slotDetail.isIssuerRefunded && block.timestamp < slotDetail.maturity, 
            "non-mintable slot"
        );

        slotDetail.totalValue = slotDetail.totalValue.add(mintValue_);
        emit Mint(minter_, slot_, mintValue_);
    }

    function refund(uint256 slot_) external override nonReentrant {
        SlotDetail storage slotDetail = _slotDetails[slot_];
        require(slotDetail.isValid, "invalid slot");
        require(!slotDetail.isIssuerRefunded, "already refunded");

        slotDetail.isIssuerRefunded = true;

        uint8 currencyDecimals = ERC20Upgradeable(fundCurrency).decimals();
        uint256 currencyAmount = slotDetail.totalValue.mul(10**currencyDecimals).div(10**valueDecimals);

        slotBalances[slot_] = slotBalances[slot_].add(currencyAmount);
        ERC20TransferHelper.doTransferIn(fundCurrency,_msgSender(),currencyAmount);

        emit Refund(slot_, _msgSender(), currencyAmount);
    }

    function claim(uint256 slot_, address to_, uint256 claimValue_)
        external
        override
        onlyVoucher
        nonReentrant
        returns (uint256 claimCurrencyAmount)
    {
        SlotDetail storage slotDetail = _slotDetails[slot_];
        require(slotDetail.isValid, "invalid slot");
        require(slotDetail.isIssuerRefunded, "not refunded");

        claimCurrencyAmount = claimValue_
            .mul(10 ** ERC20Upgradeable(fundCurrency).decimals())
            .div(10 ** valueDecimals);

        if (claimCurrencyAmount > 0) {
            uint256 reservedCurrencyAmount = slotBalances[slot_];
            if (claimCurrencyAmount > reservedCurrencyAmount) {
                claimCurrencyAmount = reservedCurrencyAmount;
            }
            slotBalances[slot_] = reservedCurrencyAmount.sub(claimCurrencyAmount);
            ERC20TransferHelper.doTransferOut(fundCurrency, payable(to_), claimCurrencyAmount);
        }
    }

    function getSlot(
        address issuer_,
        uint64 effectiveTime_,
        uint64 maturity_
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        voucher,
                        issuer_,
                        effectiveTime_,
                        maturity_
                    )
                )
            );
    }

    function getSlotDetail(uint256 slot_) external view returns (SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function getIssuerSlots(address issuer_) external view returns (uint256[] memory slots) {
        slots = new uint256[](_issuerSlots[issuer_].length());
        for (uint256 i = 0; i < slots.length; i++) {
            slots[i] = _issuerSlots[issuer_].at(i);
        }
    }

    function getIssuerSlotDetails(address issuer_) external view returns (SlotDetail[] memory slotDetails) {
        slotDetails = new SlotDetail[](_issuerSlots[issuer_].length());
        for (uint256 i = 0; i < slotDetails.length; i++) {
            slotDetails[i] = _slotDetails[_issuerSlots[issuer_].at(i)];
        }
    }

    function setVoucher(address newVoucher_) external onlyAdmin {
        require(newVoucher_ != address(0), "new voucher cannot be 0 address");
        emit NewVoucher(voucher, newVoucher_);
        voucher = newVoucher_;
    }
    
}
