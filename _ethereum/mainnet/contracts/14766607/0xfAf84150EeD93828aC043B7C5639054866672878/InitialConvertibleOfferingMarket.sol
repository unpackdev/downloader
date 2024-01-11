// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./OfferingMarketCore.sol";

interface IConvertibleVoucher {
    function mint(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint256 tokenInAmount_ // 最大偿付token数量 (at lowestPrice)
    ) external returns (uint256 slot, uint256 tokenId);
}

interface IConvertiblePool {
    function validateSlotParams(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint8 collateralType_
    ) external view;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract InitialConvertibleOfferingMarket is OfferingMarketCore {
    using SafeMathUpgradeable128 for uint128;

    struct MintParameter {
        uint128 lowestPrice;
        uint128 highestPrice;
        uint128 tokenInAmount;
        uint64 effectiveTime;
        uint64 maturity;
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

        IConvertiblePool(market.voucherPool).validateSlotParams(
            msg.sender,
            currency_,
            mintParameter_.lowestPrice,
            mintParameter_.highestPrice,
            mintParameter_.effectiveTime,
            mintParameter_.maturity,
            0 //ERC20
        );

        uint128 units = mintParameter_.tokenInAmount.mul(
            mintParameter_.lowestPrice
        );

        ERC20TransferHelper.doTransferIn(
            market.asset,
            msg.sender,
            mintParameter_.tokenInAmount
        );

        offeringId = OfferingMarketCore._offer(
            voucher_,
            currency_,
            units,
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
        uint128 tokenInAmount = units_.div(parameter.lowestPrice);
        IERC20(markets[offering.voucher].asset).approve(
            markets[offering.voucher].voucherPool,
            tokenInAmount
        );
        (, voucherId) = IConvertibleVoucher(offering.voucher).mint(
            offering.issuer,
            offering.currency,
            parameter.lowestPrice,
            parameter.highestPrice,
            parameter.effectiveTime,
            parameter.maturity,
            tokenInAmount
        );
    }

    function _refund(uint24 offeringId_, uint128 units_)
        internal
        virtual
        override
    {
        Offering memory offering = offerings[offeringId_];
        address asset = markets[offering.voucher].asset;
        uint256 balance = IERC20(asset).balanceOf(address(this));
        uint256 refundAmount = units_.div(
            _mintParameters[offeringId_].lowestPrice
        );
        if (refundAmount > balance) {
            refundAmount = balance;
        }

        ERC20TransferHelper.doTransferOut(
            markets[offering.voucher].asset,
            payable(offering.issuer),
            refundAmount
        );
    }

    function isSupportVoucherType(Constants.VoucherType voucherType_)
        public
        pure
        override
        returns (bool)
    {
        return (voucherType_ == Constants.VoucherType.BOUNDING);
    }
}
