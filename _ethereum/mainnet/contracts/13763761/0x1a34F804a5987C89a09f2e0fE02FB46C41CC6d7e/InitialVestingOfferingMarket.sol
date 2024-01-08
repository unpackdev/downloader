// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./OfferingMarketCore.sol";

interface IStandardVestingVoucher {
    function mint(
        uint64 term_,
        uint256 amount_,
        uint64[] calldata maturities_,
        uint32[] calldata percentages_,
        string memory originalInvestor_
    ) external returns (uint256 slot, uint256 voucherId);
}

interface IFlexibleDateVestingVoucher {
    function mint(
        address issuer_,
        uint8 claimType_,
        uint64 latestClaimVestingTime_,
        uint64[] calldata terms_,
        uint32[] calldata percentages_,
        uint256 vestingAmount_
    ) external returns (uint256 slot, uint256 tokenId);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract InitialVestingOfferingMarket is OfferingMarketCore {
    enum TimeType {
        LATEST_START_TIME,
        ON_BUY,
        UNDECIDED
    }

    struct MintParameter {
        Constants.ClaimType claimType;
        uint64 latestStartTime;
        TimeType timeType;
        uint64[] terms;
        uint32[] percentages;
    }

    //key: offeringId
    mapping(uint24 => MintParameter) internal _mintParameters;

    function mintParameters(uint24 offeringId_)
        external
        view
        returns (MintParameter memory)
    {
        return _mintParameters[offeringId_];
    }

    function offer(
        address voucher_,
        address currency_,
        uint128 units_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        uint32 endTime_,
        bool useAllowList_,
        PriceManager.PriceType priceType_,
        bytes calldata priceData_,
        MintParameter calldata mintParameter_
    ) external returns (uint24 offeringId) {
        Market memory market = markets[voucher_];

        if (mintParameter_.timeType == TimeType.UNDECIDED) {
            require(
                market.voucherType ==
                    Constants.VoucherType.FLEXIBLE_DATE_VESTING,
                "invalid time type"
            );
        }

        require(
            mintParameter_.terms.length == mintParameter_.percentages.length,
            "invalid terms and percentages"
        );
        // latestStartTime should not be later than 2100/01/01 00:00:00
        require(mintParameter_.latestStartTime < 4102416000, "latest start time too late");
        // number of stages should not be more than 50
        require(mintParameter_.percentages.length <= 50, "too many stages");

        uint256 sumOfPercentages = 0;
        for (uint256 i = 0; i < mintParameter_.percentages.length; i++) {
            // value of each term should not be larger than 10 years
            require(mintParameter_.terms[i] <= 315360000, "term value too large");
            // value of each percentage should not be larger than 10000
            require(mintParameter_.percentages[i] <= Constants.FULL_PERCENTAGE, "percentage value too large");
            sumOfPercentages += mintParameter_.percentages[i];
        }
        require(
            sumOfPercentages == Constants.FULL_PERCENTAGE,
            "not full percentage"
        );

        require(
            (mintParameter_.claimType == Constants.ClaimType.LINEAR &&
                mintParameter_.percentages.length == 1) ||
                (mintParameter_.claimType == Constants.ClaimType.ONE_TIME &&
                    mintParameter_.percentages.length == 1) ||
                (mintParameter_.claimType == Constants.ClaimType.STAGED &&
                    mintParameter_.percentages.length > 1),
            "invalid params"
        );

        ERC20TransferHelper.doTransferIn(market.asset, msg.sender, units_);

        offeringId = OfferingMarketCore._offer(
            voucher_,
            currency_,
            units_,
            min_,
            max_,
            startTime_,
            endTime_,
            useAllowList_,
            priceType_,
            priceData_
        );
        _mintParameters[offeringId] = mintParameter_;
    }

    function _mintVoucher(uint24 offeringId_, uint128 units_)
        internal
        virtual
        override
        returns (uint256 voucherId)
    {
        Offering memory offering = offerings[offeringId_];
        MintParameter memory parameter = _mintParameters[offeringId_];
        IERC20(markets[offering.voucher].asset).approve(
            markets[offering.voucher].voucherPool,
            units_
        );
        if (parameter.timeType != TimeType.UNDECIDED) {
            uint64 term;
            uint64[] memory maturities = new uint64[](parameter.terms.length);
            IStandardVestingVoucher vestingVoucher = IStandardVestingVoucher(
                offering.voucher
            );
            uint64 startTime = parameter.timeType == TimeType.LATEST_START_TIME
                ? parameter.latestStartTime
                : uint64(block.timestamp);

            // The values of `startTime` and `terms` are read from storage, and their values have been
            // checked before stored when offering a new IVO, so there is no need here to check the 
            // overflow of the value of `term` and `maturities`.
            for (uint256 i = 0; i < parameter.terms.length; i++) {
                term += parameter.terms[i];
                maturities[i] = startTime + term;
            }

            if (parameter.claimType == Constants.ClaimType.STAGED) {
                //standard vesting voucher: staged term should be not included terms[0]
                term -= parameter.terms[0];
            } else if (parameter.claimType == Constants.ClaimType.ONE_TIME) {
                //standard vesting voucher: one-time term should be 0
                term = 0;
            }

            (, voucherId) = vestingVoucher.mint(
                term,
                units_,
                maturities,
                parameter.percentages,
                "IVO"
            );
        } else {
            IFlexibleDateVestingVoucher offeringVoucher = IFlexibleDateVestingVoucher(
                    offering.voucher
                );
            (, voucherId) = offeringVoucher.mint(
                offering.issuer,
                uint8(parameter.claimType),
                parameter.latestStartTime,
                parameter.terms,
                parameter.percentages,
                units_
            );
        }
    }

    function _refund(uint24 offeringId_, uint128 units_)
        internal
        virtual
        override
    {
        ERC20TransferHelper.doTransferOut(
            markets[offerings[offeringId_].voucher].asset,
            payable(offerings[offeringId_].issuer),
            units_
        );
    }

    function isSupportVoucherType(Constants.VoucherType voucherType_)
        public
        pure
        override
        returns (bool)
    {
        return (voucherType_ == Constants.VoucherType.FLEXIBLE_DATE_VESTING ||
            voucherType_ == Constants.VoucherType.STANDARD_VESTING);
    }
}
