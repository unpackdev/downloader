// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Release {
    struct Basic {
        uint256 _total;
        uint256 _locked;
        uint256 _available;
        uint256 _extracted;
        bool isInit;
    }

    struct Record {
        uint256 _timemap;
        uint256 _amount;
        uint256 _extracted;
        uint16 _lockMon;
        address _operator;
    }

    struct Withdraw {
        uint256 _timemap;
        uint256 _amount;
        address _operator;
    }

    struct Data {
        Basic _basic;
        Withdraw[] _withdraws;
        Record[] _deposits;
        uint256 _recent_timemap;
    }

    modifier isInit(Data storage h) {
        require(h._basic.isInit == true, "Release: account does not exist");
        _;
    }

    modifier insufficient(Data storage h, uint256 amount) {
        require(h._basic._available >= amount, "Release: insufficient available assets");
        _;
    }

    function _record(
        Data storage h,
        uint256 amount,
        uint256 timemap,
        uint16 lockMon,
        address operator
    ) internal {
        if (h._basic.isInit == false) h._basic.isInit = true;
        if (h._recent_timemap == 0) h._recent_timemap = timemap;

        h._deposits.push(
            Record({_amount: amount, _timemap: timemap, _lockMon: lockMon, _operator: operator, _extracted: 0})
        );
        h._basic._total += amount;
        h._basic._available += amount;
    }

    function _withdraw(
        Data storage h,
        uint256 amount,
        uint256 timemap,
        address operator
    ) internal isInit(h) insufficient(h, amount) {
        h._withdraws.push(Withdraw({_amount: amount, _timemap: timemap, _operator: operator}));

        h._basic._available -= amount;
        h._basic._extracted += amount;

        h._recent_timemap = timemap;
    }

    function _lock(Data storage h, uint256 amount) internal isInit(h) insufficient(h, amount) {
        h._basic._available -= amount;
        h._basic._locked += amount;
    }

    function _ulock(Data storage h, uint256 amount) internal isInit(h) {
        require(h._basic._locked >= amount, "Release: insufficient lock-in assets");
        h._basic._locked -= amount;
        h._basic._available += amount;
    }

    function _extract(
        Data storage h,
        uint256 n,
        uint256 amount
    ) internal isInit(h) {
        require(
            h._deposits[n]._extracted + amount <= h._deposits[n]._amount,
            "Release: insufficient assets to be extracted"
        );
        h._deposits[n]._extracted += amount;
    }

    function _finish(Data storage h, uint256 n) internal isInit(h) {
        require(h._deposits[n]._amount == h._deposits[n]._extracted, "Release: there are also remaining assets");
        delete (h._deposits[n]);
    }

    function _calculateRelease(
        Data storage h,
        uint256 diff_month,
        uint256 total_month,
        uint256 n
    ) internal isInit(h) returns (uint256 release, bool finish) {
        if (diff_month <= h._deposits[n]._lockMon) {
            release = 0;
        } else {
            h._deposits[n]._lockMon = 0;
            release = (h._deposits[n]._amount / total_month) * diff_month;
            if (release + h._deposits[n]._extracted >= h._deposits[n]._amount) {
                release = h._deposits[n]._amount - h._deposits[n]._extracted;
                finish = true;
            }
        }
    }
}
