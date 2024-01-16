// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./OfferingMarketCore.sol";

interface IBondVoucher {
    function mint(
        address issuer_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint256 mintValue_
    ) external returns (uint256 slot, uint256 tokenId);
}

interface IBondPool {
    function validateSlotParams(
        address issuer_,
        uint64 effectiveTime_,
        uint64 maturity_
    ) external view;

    function fundCurrency() external returns (address);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CreditBondOfferingMarket is OfferingMarketCore {
    using SafeMathUpgradeable128 for uint128;

    struct MintParameter {
        uint64 effectiveTime;
        uint64 maturity;
    }

    //key: offeringId
    mapping(uint24 => MintParameter) internal _mintParameters;

    function mintParameters(uint24 offeringId_) external view returns (MintParameter memory) {
        return _mintParameters[offeringId_];
    }

    function offer(
        address voucher_,
        address currency_,
        uint128 totalValue_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        uint32 endTime_,
        bool useAllowList_,
        PriceManager.PriceType priceType_,
        bytes calldata priceData_,
        MintParameter calldata mintParameter_
    ) 
        external returns (uint24 offeringId) 
    {
        Market memory market = markets[voucher_];
        IBondPool voucherPool = IBondPool(market.voucherPool);

        require(currency_ == voucherPool.fundCurrency(), "unsupported fund currency");

        IBondPool(market.voucherPool).validateSlotParams(
            msg.sender,
            mintParameter_.effectiveTime,
            mintParameter_.maturity
        );

        offeringId = OfferingMarketCore._offer(
            voucher_,
            currency_,
            totalValue_,
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
        (, voucherId) = IBondVoucher(offering.voucher).mint(
            offering.issuer,
            parameter.effectiveTime,
            parameter.maturity,
            units_
        );
    }

    function _refund(uint24 offeringId, uint128 units) internal virtual override {
        offeringId; units;
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
