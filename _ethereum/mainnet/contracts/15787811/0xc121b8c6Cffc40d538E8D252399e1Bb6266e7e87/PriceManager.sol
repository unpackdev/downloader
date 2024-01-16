// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

contract PriceManager {
    enum PriceType {
        FIXED,
        DECLIINING_BY_TIME
    }

    struct DecliningPrice {
        uint128 highest; //起始价格
        uint128 lowest; //最终价格
        uint32 startTime;
        uint32 duration; //持续时间
        uint32 interval; //降价周期
    }

    //saleId => DecliningPrice
    mapping(uint24 => DecliningPrice) internal decliningPrices;
    mapping(uint24 => uint128) internal fixedPrices;

    function price(PriceType priceType_, uint24 offeringId_)
        internal
        view
        returns (uint128)
    {
        if (priceType_ == PriceType.FIXED) {
            return fixedPrices[offeringId_];
        }

        if (priceType_ == PriceType.DECLIINING_BY_TIME) {
            DecliningPrice storage price_ = decliningPrices[offeringId_];
            if (block.timestamp >= price_.startTime + price_.duration) {
                return price_.lowest;
            }
            if (block.timestamp <= price_.startTime) {
                return price_.highest;
            }

            uint256 lastPrice = price_.highest -
                ((block.timestamp - price_.startTime) / price_.interval) *
                ((price_.interval * (price_.highest - price_.lowest)) /
                    price_.duration);
            uint256 price256 = lastPrice < price_.lowest
                ? price_.lowest
                : lastPrice;
            require(price256 <= uint128(-1), "price: exceeds uint128 max");

            return uint128(price256);
        }

        revert("unsupported priceType");
    }

    function setFixedPrice(uint24 offeringId_, uint128 price_) internal {
        fixedPrices[offeringId_] = price_;
    }

    function setDecliningPrice(
        uint24 offeringId_,
        uint32 startTime_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) internal {
        require(highest_ > lowest_, "highest must greater than lowest");
        require(duration_ >= interval_, "duration must greater than interval");
        decliningPrices[offeringId_].startTime = startTime_;
        decliningPrices[offeringId_].highest = highest_;
        decliningPrices[offeringId_].lowest = lowest_;
        decliningPrices[offeringId_].duration = duration_;
        decliningPrices[offeringId_].interval = interval_;
    }

    function getDecliningPrice(uint24 offeringId_)
        external
        view
        returns (
            uint128 highest,
            uint128 lowest,
            uint32 startTime,
            uint32 duration,
            uint32 interval
        )
    {
        DecliningPrice storage decliningPrice = decliningPrices[offeringId_];
        return (
            decliningPrice.highest,
            decliningPrice.lowest,
            decliningPrice.startTime,
            decliningPrice.duration,
            decliningPrice.interval
        );
    }

    function getFixedPrice(uint24 offeringId_) external view returns (uint128) {
        return fixedPrices[offeringId_];
    }
}
