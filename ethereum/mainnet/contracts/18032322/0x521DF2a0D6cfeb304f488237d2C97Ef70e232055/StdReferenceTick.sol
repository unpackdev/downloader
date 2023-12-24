// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import {StdReferenceBase} from "StdReferenceBase.sol";
import {AccessControl} from "AccessControl.sol";

contract StdReferenceTick is AccessControl, StdReferenceBase {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant LISTER_ROLE = keccak256("LISTER_ROLE");
    bytes32 public constant DELISTER_ROLE = keccak256("DELISTER_ROLE");
    bytes32 private constant USD = keccak256(bytes("USD"));
    uint256 public constant MID_TICK = 262144;

    struct Price {
        uint256 tick;
        string symbol;
    }

    uint256 public totalSymbolsCount = 0;

    // storage
    // 31|3|(timeOffset(18)+tick(19))*6|
    mapping(uint256 => uint256) public refs;
    mapping(string => uint256) public symbolsToIDs;
    mapping(uint256 => string) public idsToSymbols;

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RELAYER_ROLE, admin);
        _grantRole(LISTER_ROLE, admin);
        _grantRole(DELISTER_ROLE, admin);
    }

    function _extractSlotTime(uint256 val) private pure returns (uint256 t) {
        unchecked {
            t = (val >> 225) & ((1 << 31) - 1);
        }
    }

    function _extractSize(uint256 val) private pure returns (uint256 s) {
        unchecked {
            s = (val >> 222) & ((1 << 3) - 1);
        }
    }

    function _extractTick(uint256 val, uint256 shiftLen) private pure returns (uint256 tick) {
        unchecked {
            tick = (val >> shiftLen) & ((1 << 19) - 1);
        }
    }

    function _extractTimeOffset(uint256 val, uint256 shiftLen) private pure returns (uint256 offset) {
        unchecked {
            offset = (val >> shiftLen) & ((1 << 18) - 1);
        }
    }

    function _setTime(uint256 val, uint256 time) private pure returns (uint256 newVal) {
        unchecked {
            newVal = (val & (type(uint256).max >> 31)) | (time << 225);
        }
    }

    function _setSize(uint256 val, uint256 size) private pure returns (uint256 newVal) {
        unchecked {
            newVal = (val & ((type(uint256).max << (37 * (6 - size))) - ((((1 << 3) - 1)) << 222))) | (size << 222);
        }
    }

    function _setTimeOffset(uint256 val, uint256 timeOffset, uint256 shiftLen) private pure returns (uint256 newVal) {
        unchecked {
            newVal = ((val & ~(uint256((1 << 18) - 1) << (shiftLen + 19))) | (timeOffset << (shiftLen + 19)));
        }
    }

    function _setTicksAndTimeOffset(uint256 val, uint256 timeOffset, uint256 tick, uint256 shiftLen) private pure returns (uint256 newVal) {
        unchecked {
            newVal = (val & (~(uint256((1 << 37) - 1) << shiftLen))) | (((timeOffset << 19) | (tick & ((1 << 19) - 1))) << shiftLen);
        }
    }

    function _getTickAndTime(uint256 slot, uint8 idx) private view returns (uint256 tick, uint256 lastUpdated) {
        unchecked {
            uint256 sVal = refs[slot];
            uint256 idx_x_37 = idx * 37;
            return (_extractTick(sVal, 185 - idx_x_37), _extractTimeOffset(sVal, 204 - idx_x_37) + _extractSlotTime(sVal));
        }
    }

    function getSlotAndIndex(string memory symbol) public view returns (uint256 slot, uint8 idx) {
        unchecked {
            uint256 id = symbolsToIDs[symbol];
            require(id != 0, "getSlotAndIndex: FAIL_SYMBOL_NOT_AVAILABLE");
            return ((id - 1) / 6, uint8((id - 1) % 6));
        }
    }

    function getTickAndTime(string memory symbol) public view returns (uint256 tick, uint256 lastUpdated) {
        unchecked {
            if (keccak256(bytes(symbol)) == USD) {
                (tick, lastUpdated) = (MID_TICK, block.timestamp);
            } else {
                (uint256 slot, uint8 idx) = getSlotAndIndex(symbol);
                (tick, lastUpdated) = _getTickAndTime(slot, idx);
                require(tick != 0, "getTickAndTime: FAIL_TICK_0_IS_AN_EMPTY_PRICE");
            }
        }
    }

    function getReferenceData(string memory _base, string memory _quote) public view override returns (ReferenceData memory r) {
        uint256 baseTick;
        uint256 quoteTick;
        (baseTick, r.lastUpdatedBase) = getTickAndTime(_base);
        (quoteTick, r.lastUpdatedQuote) = getTickAndTime(_quote);
        require(baseTick + MID_TICK > quoteTick, "getReferenceData: FAIL_PRICE_RATIO_TOO_LOW");
        require(baseTick < MID_TICK + quoteTick, "getReferenceData: FAIL_PRICE_RATIO_TOO_HIGH");
        r.rate = _getPriceFromTick((baseTick + MID_TICK) - quoteTick);
    }

    function _getPriceFromTick(uint256 x) private pure returns (uint256 y) {
        unchecked {
            require(x != 0, "_getPriceFromTick: FAIL_TICK_0_IS_AN_EMPTY_PRICE");
            require(x < (1 << 19), "_getPriceFromTick: FAIL_TICK_OUT_OF_RANGE");
            y = 649037107316853453566312041152512;
            if (x < MID_TICK) {
                x = MID_TICK - x;
                if (x & 0x01 != 0) y = (y * 649102011027585138911668672356627) >> 109;
                if (x & 0x02 != 0) y = (y * 649166921228687897425559839223862) >> 109;
                if (x & 0x04 != 0) y = (y * 649296761104602847291923925447306) >> 109;
                if (x & 0x08 != 0) y = (y * 649556518769447606681106054382372) >> 109;
                if (x & 0x10 != 0) y = (y * 650076345896668132522271100656030) >> 109;
                if (x & 0x20 != 0) y = (y * 651117248505878973533694452870408) >> 109;
                if (x & 0x40 != 0) y = (y * 653204056474534657407624669811404) >> 109;
                if (x & 0x80 != 0) y = (y * 657397758286396885483233885325217) >> 109;
                if (x & 0x0100 != 0) y = (y * 665866108005128170549362417755489) >> 109;
                if (x & 0x0200 != 0) y = (y * 683131470899774684431604377857106) >> 109;
                if (x & 0x0400 != 0) y = (y * 719016834742958293196733842540130) >> 109;
                if (x & 0x0800 != 0) y = (y * 796541835305874991615834691778664) >> 109;
                if (x & 0x1000 != 0) y = (y * 977569522974447437629335387266319) >> 109;
                if (x & 0x2000 != 0) y = (y * 1472399900522103311842374358851872) >> 109;
                if (x & 0x4000 != 0) y = (y * 3340273526146976564083509455290620) >> 109;
                if (x & 0x8000 != 0) y = (y * 17190738562859105750521122099339319) >> 109;
                if (x & 0x010000 != 0) y = (y * 455322953040804340936374685561109626) >> 109;
                if (x & 0x020000 != 0) y = (y * 319425483117388922324853186559947171877) >> 109;
                y = 649037107316853453566312041152512000000000000000000 / y;
            } else {
                x = x - MID_TICK;
                if (x & 0x01 != 0) y = (y * 649102011027585138911668672356627) >> 109;
                if (x & 0x02 != 0) y = (y * 649166921228687897425559839223862) >> 109;
                if (x & 0x04 != 0) y = (y * 649296761104602847291923925447306) >> 109;
                if (x & 0x08 != 0) y = (y * 649556518769447606681106054382372) >> 109;
                if (x & 0x10 != 0) y = (y * 650076345896668132522271100656030) >> 109;
                if (x & 0x20 != 0) y = (y * 651117248505878973533694452870408) >> 109;
                if (x & 0x40 != 0) y = (y * 653204056474534657407624669811404) >> 109;
                if (x & 0x80 != 0) y = (y * 657397758286396885483233885325217) >> 109;
                if (x & 0x0100 != 0) y = (y * 665866108005128170549362417755489) >> 109;
                if (x & 0x0200 != 0) y = (y * 683131470899774684431604377857106) >> 109;
                if (x & 0x0400 != 0) y = (y * 719016834742958293196733842540130) >> 109;
                if (x & 0x0800 != 0) y = (y * 796541835305874991615834691778664) >> 109;
                if (x & 0x1000 != 0) y = (y * 977569522974447437629335387266319) >> 109;
                if (x & 0x2000 != 0) y = (y * 1472399900522103311842374358851872) >> 109;
                if (x & 0x4000 != 0) y = (y * 3340273526146976564083509455290620) >> 109;
                if (x & 0x8000 != 0) y = (y * 17190738562859105750521122099339319) >> 109;
                if (x & 0x010000 != 0) y = (y * 455322953040804340936374685561109626) >> 109;
                if (x & 0x020000 != 0) y = (y * 319425483117388922324853186559947171877) >> 109;
                y = (y * 1e18) / 649037107316853453566312041152512;
            }
        }
    }

    function getPriceFromTick(uint256 x) public pure returns (uint256 y) {
        y = _getPriceFromTick(x);
    }

    /**
     * @dev Grants `RELAYER_ROLE` to `accounts`.
     *
     * If each `account` had not been already granted `RELAYER_ROLE`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``RELAYER_ROLE``'s admin role.
     */
    function grantRelayers(address[] calldata accounts) external onlyRole(getRoleAdmin(RELAYER_ROLE)) {
        for (uint256 idx = 0; idx < accounts.length; idx++) {
            _grantRole(RELAYER_ROLE, accounts[idx]);
        }
    }

    /**
     * @dev Revokes `RELAYER_ROLE` from `accounts`.
     *
     * If each `account` had already granted `RELAYER_ROLE`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``RELAYER_ROLE``'s admin role.
     */
    function revokeRelayers(address[] calldata accounts) external onlyRole(getRoleAdmin(RELAYER_ROLE)) {
        for (uint256 idx = 0; idx < accounts.length; idx++) {
            _revokeRole(RELAYER_ROLE, accounts[idx]);
        }
    }

    function listing(string[] calldata symbols) public onlyRole(LISTER_ROLE) {
        require(symbols.length != 0, "listing: FAIL_SYMBOLS_IS_EMPTY");

        uint256 _totalSymbolsCount = totalSymbolsCount;
        uint256 sid = _totalSymbolsCount / 6;
        uint256 sVal = refs[sid];
        uint256 sSize = _extractSize(sVal);

        for (uint256 i = 0; i < symbols.length; i++) {
            require(keccak256(bytes(symbols[i])) != USD, "listing: FAIL_USD_CANT_BE_SET");
            require(symbolsToIDs[symbols[i]] == 0, "listing: FAIL_SYMBOL_IS_ALREADY_SET");

            uint256 slotID = _totalSymbolsCount / 6;

            _totalSymbolsCount++;
            symbolsToIDs[symbols[i]] = _totalSymbolsCount;
            idsToSymbols[_totalSymbolsCount] = symbols[i];

            if (sid != slotID) {
                refs[sid] = sVal;

                sid = slotID;
                sVal = refs[sid];
                sSize = _extractSize(sVal);
            }

            sSize++;
            sVal = _setSize(sVal, sSize);
        }

        refs[sid] = sVal;
        totalSymbolsCount = _totalSymbolsCount;
    }

    function delisting(string[] calldata symbols) public onlyRole(DELISTER_ROLE) {
        uint256 _totalSymbolsCount = totalSymbolsCount;
        uint256 slotID1;
        uint256 slotID2;
        uint256 sVal1;
        uint256 sVal2;
        uint256 sSize;
        uint256 shiftLen;
        uint256 lastSegment;
        uint256 time;
        string memory lastSymbol;
        for (uint256 i = 0; i < symbols.length; i++) {
            uint256 id = symbolsToIDs[symbols[i]];
            require(id != 0, "delisting: FAIL_SYMBOL_NOT_AVAILABLE");

            lastSymbol = idsToSymbols[_totalSymbolsCount];

            symbolsToIDs[lastSymbol] = id;
            idsToSymbols[id] = lastSymbol;

            slotID1 = (_totalSymbolsCount - 1) / 6;
            slotID2 = (id - 1) / 6;
            sVal1 = refs[slotID1];
            sSize = _extractSize(sVal1);
            lastSegment = (sVal1 >> (37 * (6 - sSize))) & ((1 << 37) - 1);
            shiftLen = 37 * (5 - ((id - 1) % 6));

            if (slotID1 == slotID2) {
                sVal1 = (sVal1 & (type(uint256).max - (((1 << 37) - 1) << shiftLen))) | (lastSegment << shiftLen);
            } else {
                sVal2 = refs[slotID2];

                time = _extractSlotTime(sVal1) + (lastSegment >> 19);
                require(time >= _extractSlotTime(sVal2), "delisting: FAIL_LAST_TIMESTAMP_IS_LESS_THAN_TARGET_TIMESTAMP");
                time -= _extractSlotTime(sVal2);
                require(time < 1 << 18, "delisting: FAIL_DELTA_TIME_EXCEED_3_DAYS");
                lastSegment = (time << 19) | (lastSegment & ((1 << 19) - 1));

                refs[slotID2] = (sVal2 & (type(uint256).max - (((1 << 37) - 1) << shiftLen))) | (lastSegment << shiftLen);
            }

            refs[slotID1] = _setSize(sVal1, sSize - 1);

            delete symbolsToIDs[symbols[i]];
            delete idsToSymbols[_totalSymbolsCount];

            _totalSymbolsCount--;
        }

        totalSymbolsCount = _totalSymbolsCount;
    }

    function relay(uint256 time, uint256 requestID, Price[] calldata ps) external onlyRole(RELAYER_ROLE) {
        unchecked {
            uint256 id;
            uint256 sid = type(uint256).max;
            uint256 nextSID;
            uint256 sTime;
            uint256 sVal;
            uint256 shiftLen;
            for (uint256 i = 0; i < ps.length; i++) {
                id = symbolsToIDs[ps[i].symbol];
                require(id != 0, "relay: FAIL_SYMBOL_NOT_AVAILABLE");

                nextSID = (id - 1) / 6;
                if (sid != nextSID) {
                    if (sVal != 0) refs[sid] = sVal;

                    sVal = refs[nextSID];
                    sid = nextSID;
                    sTime = _extractSlotTime(sVal);
                }

                shiftLen = 204 - (37 * ((id - 1) % 6));
                if (sTime + _extractTimeOffset(sVal, shiftLen) < time) {
                    require(time < sTime + (1 << 18), "relay: FAIL_DELTA_TIME_EXCEED_3_DAYS");
                    sVal = _setTicksAndTimeOffset(sVal, time - sTime, ps[i].tick, shiftLen - 19);
                }
            }

            if (sVal != 0) refs[sid] = sVal;
        }
    }

    function relayRebase(uint256 time, uint256 requestID, Price[] calldata ps) external onlyRole(RELAYER_ROLE) {
        unchecked {
            uint256 id;
            uint256 nextID;
            uint256 sVal;
            uint256 sTime;
            uint256 sSize;
            uint256 shiftLen;
            uint256 timeOffset;
            uint256 i;
            while (i < ps.length) {
                id = symbolsToIDs[ps[i].symbol];
                require(id != 0, "relayRebase: FAIL_SYMBOL_NOT_AVAILABLE");
                require((id - 1) % 6 == 0, "relayRebase: FAIL_INVALID_FIRST_IDX");
                sVal = refs[(id - 1) / 6];
                (sTime, sSize) = (_extractSlotTime(sVal), _extractSize(sVal));
                require(sTime < time, "relayRebase: FAIL_NEW_TIME_<=_CURRENT");
                shiftLen = 204;
                timeOffset = _extractTimeOffset(sVal, shiftLen);
                shiftLen = shiftLen - 19;
                sVal = sTime + timeOffset <= time
                    ? _setTicksAndTimeOffset(sVal, 0, ps[i].tick, shiftLen)
                    : _setTimeOffset(sVal, (sTime + timeOffset) - time, shiftLen);
                require(i + sSize <= ps.length, "relayRebase: FAIL_INCONSISTENT_SIZES");
                for (uint256 j = i + 1; j < i + sSize; j++) {
                    nextID = symbolsToIDs[ps[j].symbol];
                    require(nextID != 0, "relayRebase: FAIL_SYMBOL_NOT_AVAILABLE");
                    require(nextID + i == id + j, "relayRebase: FAIL_INVALID_IDX_ORDER");
                    shiftLen = shiftLen - 18;
                    timeOffset = _extractTimeOffset(sVal, shiftLen);
                    shiftLen = shiftLen - 19;
                    sVal = sTime + timeOffset <= time
                        ? _setTicksAndTimeOffset(sVal, 0, ps[j].tick, shiftLen)
                        : _setTimeOffset(sVal, (sTime + timeOffset) - time, shiftLen);
                }
                refs[(id - 1) / 6] = _setTime(sVal, time);
                i += sSize;
            }
        }
    }
}
