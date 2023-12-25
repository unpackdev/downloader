// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

library PricingLibrary {
    // 1 Slot
    struct Data {
        uint48 lastTune;
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint48 length; // time from creation to conclusion. used as speed to decay debt.
        uint48 depositInterval; // target frequency of deposits
        uint48 tuneInterval; // frequency of tuning
    }

    // 2 Storage slots
    struct Market {
        uint96 capacity; // capacity remaining
        uint96 totalDebt; // total debt from market
        uint96 maxPayout; // max tokens in/out
        uint96 sold; // Koto out
        uint96 purchased; // Eth in
    }

    // 1 Storage Slot
    struct Adjustment {
        uint128 change;
        uint48 lastAdjustment;
        uint48 timeToAdjusted;
        bool active;
    }

    // 2 Storage slots
    struct Term {
        uint48 conclusion; // timestamp when the current market will end
        uint256 controlVariable; // scaling variable for price
    }

    function decay(Data memory data, Market memory market, Term memory terms, Adjustment memory adjustments)
        internal
        view
        returns (Market memory, Data memory, Term memory, Adjustment memory)
    {
        uint48 time = uint48(block.timestamp);
        market.totalDebt -= debtDecay(data, market);
        data.lastDecay = time;

        if (adjustments.active) {
            (uint128 adjustby, uint48 dt, bool stillActive) = controlDecay(adjustments);
            terms.controlVariable -= adjustby;
            if (stillActive) {
                adjustments.change -= adjustby;
                adjustments.timeToAdjusted -= dt;
                adjustments.lastAdjustment = time;
            } else {
                adjustments.active = false;
            }
        }
        return (market, data, terms, adjustments);
    }

    function controlDecay(Adjustment memory info) internal view returns (uint128, uint48, bool) {
        if (!info.active) return (0, 0, false);

        uint48 secondsSince = uint48(block.timestamp) - info.lastAdjustment;
        bool active = secondsSince < info.timeToAdjusted;
        uint128 _decay = active ? (info.change * secondsSince) / info.timeToAdjusted : info.change;
        return (_decay, secondsSince, active);
    }

    function marketPrice(uint256 _controlVariable, uint256 _totalDebt, uint256 _totalSupply)
        internal
        pure
        returns (uint256)
    {
        return ((_controlVariable * debtRatio(_totalDebt, _totalSupply)) / 1e18);
    }

    function debtRatio(uint256 _totalDebt, uint256 _totalSupply) internal pure returns (uint256) {
        return ((_totalDebt * 1e18) / _totalSupply);
    }

    function debtDecay(Data memory data, Market memory market) internal view returns (uint64) {
        uint256 secondsSince = block.timestamp - data.lastDecay;
        return uint64((market.totalDebt * secondsSince) / data.length);
    }

    struct TuneCache {
        uint256 remaining;
        uint256 price;
        uint256 capacity;
        uint256 targetDebt;
        uint256 ncv;
    }

    function tune(
        uint48 time,
        Market memory market,
        Term memory term,
        Data memory data,
        Adjustment memory adjustment,
        uint256 _totalSupply
    ) internal pure returns (Market memory, Term memory, Data memory, Adjustment memory) {
        TuneCache memory cache;
        if (time >= data.lastTune + data.tuneInterval) {
            cache.remaining = term.conclusion - time;
            cache.price = marketPrice(term.controlVariable, market.totalDebt, _totalSupply);
            cache.capacity = market.capacity;
            market.maxPayout = uint96((cache.capacity * data.depositInterval / cache.remaining));
            cache.targetDebt = cache.capacity * data.length / cache.remaining;
            cache.ncv = (cache.price * _totalSupply) / cache.targetDebt;

            if (cache.ncv < term.controlVariable) {
                uint128 change = uint128(term.controlVariable - cache.ncv);
                adjustment = Adjustment(change, time, data.tuneInterval, true);
            } else {
                term.controlVariable = cache.ncv;
            }
            data.lastTune = time;
        }
        return (market, term, data, adjustment);
    }
}
