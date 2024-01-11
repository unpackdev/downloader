// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";

contract HYFI_Referrals is Initializable, AccessControlUpgradeable {
    mapping(uint256 => uint256) internal _referralDiscountAmount; //referral -> discountAmount
    uint256 internal _rangeSize;
    uint256 constant range = 100_000;
    mapping(uint256 => uint256) amountBoughtWithReferralCode;
    uint256[] internal _usedReferralCodeList;
    uint256 internal totalAmountBoughtWithReferrals;

    bytes32 public constant REFERRAL_SETTER = keccak256("REFERRAL_SETTER");

    function initialize() public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REFERRAL_SETTER, msg.sender);
    }

    function addToReferralRange(uint256 referralRange, uint256 referralDiscount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_referralDiscountAmount[referralRange] == 0) {
            _rangeSize++;
        }
        _referralDiscountAmount[referralRange] = referralDiscount;
    }

    function removeReferralRange(uint256 range)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delete _referralDiscountAmount[range];
        _rangeSize--;
    }

    function updateAmountBoughtWithReferral(
        uint256 referralCode,
        uint256 amount
    ) external virtual onlyRole(REFERRAL_SETTER) {
        /* If the referral code (contract wise) was not used to buy items to this point,
           then add the referral code to the list of referrals in use*/
        if (getAmountBoughtWithReferral(referralCode) == 0) {
            _usedReferralCodeList.push(referralCode);
        }
        amountBoughtWithReferralCode[referralCode] += amount;
        totalAmountBoughtWithReferrals += amount;
    }

    function getAmountBoughtWithReferral(uint256 referralCode)
        public
        view
        returns (uint256)
    {
        return (amountBoughtWithReferralCode[referralCode]);
    }

    function getTotalAmountBoughtWithReferrals()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        return (totalAmountBoughtWithReferrals);
    }

    function getAllUsedReferralCodeList()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256[] memory)
    {
        return (_usedReferralCodeList);
    }

    function getReferralDiscountAmount(uint256 referral)
        external
        view
        virtual
        onlyRole(REFERRAL_SETTER)
        returns (uint256 discountAmount)
    {
        for (uint256 i = _rangeSize * range; i > 0; i -= range) {
            if (i <= referral) {
                discountAmount = _referralDiscountAmount[i];
                return discountAmount;
            }
        }
    }

    function getReferralRangeSize()
        external
        view
        onlyRole(REFERRAL_SETTER)
        returns (uint256)
    {
        return (_rangeSize);
    }

    function getReferralDiscountAmountByRange(uint256 referralCode)
        external
        view
        onlyRole(REFERRAL_SETTER)
        returns (uint256)
    {
        return (_referralDiscountAmount[referralCode]);
    }
}