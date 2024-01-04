// hevm: flattened sources of src/SpellFab.sol
pragma solidity =0.6.11;

////// lib/dss-exec-lib/src/CollateralOpts.sol
/* pragma solidity ^0.6.7; */

struct CollateralOpts {
    bytes32 ilk;
    address gem;
    address join;
    address flip;
    address pip;
    bool    isLiquidatable;
    bool    isOSM;
    bool    whitelistOSM;
    uint256 ilkDebtCeiling;
    uint256 minVaultAmount;
    uint256 maxLiquidationAmount;
    uint256 liquidationPenalty;
    uint256 ilkStabilityFee;
    uint256 bidIncrease;
    uint256 bidDuration;
    uint256 auctionDuration;
    uint256 liquidationRatio;
}

////// lib/dss-exec-lib/src/DssAction.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssAction.sol -- DSS Executive Spell Actions
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity ^0.6.7; */
/* pragma experimental ABIEncoderV2; */

/* import "./CollateralOpts.sol"; */

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike {
    function getAddress(bytes32) external view returns (address);
}

interface RegistryLike {
    function ilkData(bytes32) external returns (
        uint256       pos,
        address       gem,
        address       pip,
        address       join,
        address       flip,
        uint256       dec,
        string memory name,
        string memory symbol
    );
}

// Includes Median and OSM functions
interface OracleLike {
    function src() external view returns (address);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
}

abstract contract DssAction {

    address public immutable lib;
    bool    public immutable officeHours;

    // Changelog address applies to MCD deployments on
    //        mainnet, kovan, rinkeby, ropsten, and goerli
    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    constructor(address lib_, bool officeHours_) public {
        lib = lib_;
        officeHours = officeHours_;
    }

    // DssExec calls execute. We limit this function subject to officeHours modifier.
    function execute() external limited {
        actions();
    }

    // DssAction developer must override `actions()` and place all actions to be called inside.
    //   The DssExec function will call this subject to the officeHours limiter
    //   By keeping this function public we allow simulations of `execute()` on the actions outside of the cast time.
    function actions() public virtual;

    // Modifier required to
    modifier limited {
        if (officeHours) {
            uint day = (block.timestamp / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = block.timestamp / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    /****************************/
    /*** Core Address Helpers ***/
    /****************************/
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        public view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spot()       public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function flap()       public view returns (address) { return getChangelogAddress("MCD_FLAP"); }
    function flop()       public view returns (address) { return getChangelogAddress("MCD_FLOP"); }
    function osmMom()     public view returns (address) { return getChangelogAddress("OSM_MOM"); }
    function govGuard()   public view returns (address) { return getChangelogAddress("GOV_GUARD"); }
    function flipperMom() public view returns (address) { return getChangelogAddress("FLIPPER_MOM"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }

    function getChangelogAddress(bytes32 _key) public view returns (address) {
        return ChainlogLike(LOG).getAddress(_key);
    }

    function flip(bytes32 _ilk) public returns (address) {
        (,,,, address _flip,,,) = RegistryLike(reg()).ilkData(_ilk);
        return _flip;
    }

    function _dcall(bytes memory data) internal {
        (bool ok,) = lib.delegatecall(data);
        require(ok, "fail");
    }

    function libCall(string memory sig, address addr, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, addr, addr2));
    }

    function libCall(string memory sig, address addr, bytes32 what, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, addr, what, addr2));
    }

    function libCall(string memory sig, address addr, bytes32 what, bytes32 what2, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, addr, what, what2, addr2));
    }

    function libCall(string memory sig, address addr, address[] memory arr) internal {
        _dcall(abi.encodeWithSignature(sig, addr, arr));
    }

    function libCall(string memory sig, string memory what) internal {
        _dcall(abi.encodeWithSignature(sig, what));
    }

    function libCall(string memory sig, bytes32 what, uint256 num) internal {
        _dcall(abi.encodeWithSignature(sig, what, num));
    }

    function libCall(string memory sig, address mcd_addr, bytes32 what, uint256 num1, uint256 num2, uint256 num3) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, what, num1, num2, num3));
    }

    function libCall(string memory sig, bytes32 what, address addr) internal {
        _dcall(abi.encodeWithSignature(sig, what, addr));
    }

    function libCall(string memory sig, address mcd_addr) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr));
    }

    function libCall(string memory sig, address mcd_addr, uint256 num) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, num));
    }

    function libCall(string memory sig, address mcd_addr, bytes32 what) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, what));
    }

    function libCall(string memory sig, address mcd_addr, string memory what) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, what));
    }

    function libCall(string memory sig, address mcd_addr, address addr, bytes32 what) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, addr, what));
    }

    function libCall(string memory sig, address mcd_addr, bytes32 what, uint256 num) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, what, num));
    }

    function libCall(string memory sig, address mcd_addr, bytes32 what, uint256 num, bool bool1) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, what, num, bool1));
    }

    function libCall(string memory sig, address mcd_addr, address mcd_addr2, address addr, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, mcd_addr2, addr, addr2));
    }

    function libCall(string memory sig, address mcd_addr, address mcd_addr2, address mcd_addr3, address addr, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, mcd_addr2, mcd_addr3, addr, addr2));
    }

    function libCall(string memory sig, address mcd_addr, address mcd_addr2, address mcd_addr3, address mcd_addr4, bytes32 what, address addr, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, mcd_addr, mcd_addr2, mcd_addr3, mcd_addr4, what, addr, addr2));
    }

    function libCall(
        string memory sig, address _vat, address _cat, address _jug, address _end, address _spot, address _reg, bytes32 _ilk, address _gem, address _join, address _flip, address _pip
    ) internal {
        _dcall(abi.encodeWithSignature(sig, _vat, _cat, _jug, _end, _spot, _reg, _ilk, _gem, _join, _flip, _pip));
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/
    function setChangelogAddress(bytes32 key, address value) internal {
        libCall("setChangelogAddress(address,bytes32,address)", LOG, key, value);
    }

    function setChangelogVersion(string memory version) internal {
        libCall("setChangelogVersion(address,string)", LOG, version);
    }

    function setChangelogIPFS(string memory ipfs) internal {
        libCall("setChangelogIPFS(address,string)", LOG, ipfs);
    }

    function setChangelogSHA256(string memory SHA256) internal {
        libCall("setChangelogSHA256(address,string)", LOG, SHA256);
    }

    /**********************/
    /*** Authorizations ***/
    /**********************/
    function authorize(address base, address ward) internal virtual {
        libCall("authorize(address,address)", base, ward);
    }

    function deauthorize(address base, address ward) internal {
        libCall("deauthorize(address,address)", base, ward);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    function accumulateDSR() internal {
        libCall("accumulateDSR(address)", pot());
    }

    function accumulateCollateralStabilityFees(bytes32 ilk) internal {
        libCall("accumulateCollateralStabilityFees(address,bytes32)", jug(), ilk);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    function updateCollateralPrice(bytes32 ilk) internal {
        libCall("updateCollateralPrice(address,bytes32)", spot(), ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    function setContract(address base, bytes32 what, address addr) internal {
        libCall("setContract(address,bytes32,address)", base, what, addr);
    }

    function setContract(address base, bytes32 ilk, bytes32 what, address addr) internal {
        libCall("setContract(address,bytes32,bytes32,address)", base, ilk, what, addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    function setGlobalDebtCeiling(uint256 amount) internal {
        libCall("setGlobalDebtCeiling(address,uint256)", vat(), amount);
    }

    function increaseGlobalDebtCeiling(uint256 amount) internal {
        libCall("increaseGlobalDebtCeiling(address,uint256)", vat(), amount);
    }

    function decreaseGlobalDebtCeiling(uint256 amount) internal {
        libCall("decreaseGlobalDebtCeiling(address,uint256)", vat(), amount);
    }

    function setDSR(uint256 rate) internal {
        libCall("setDSR(address,uint256)", pot(), rate);
    }

    function setSurplusAuctionAmount(uint256 amount) internal {
        libCall("setSurplusAuctionAmount(address,uint256)", vow(), amount);
    }

    function setSurplusBuffer(uint256 amount) internal {
        libCall("setSurplusBuffer(address,uint256)", vow(), amount);
    }

    function setMinSurplusAuctionBidIncrease(uint256 pct_bps) internal {
        libCall("setMinSurplusAuctionBidIncrease(address,uint256)", flap(), pct_bps);
    }

    function setSurplusAuctionBidDuration(uint256 duration) internal {
        libCall("setSurplusAuctionBidDuration(address,uint256)", flap(), duration);
    }

    function setSurplusAuctionDuration(uint256 duration) internal {
        libCall("setSurplusAuctionDuration(address,uint256)", flap(), duration);
    }

    function setDebtAuctionDelay(uint256 duration) internal {
        libCall("setDebtAuctionDelay(address,uint256)", vow(), duration);
    }

    function setDebtAuctionDAIAmount(uint256 amount) internal {
        libCall("setDebtAuctionDAIAmount(address,uint256)", vow(), amount);
    }

    function setDebtAuctionMKRAmount(uint256 amount) internal {
        libCall("setDebtAuctionMKRAmount(address,uint256)", vow(), amount);
    }

    function setMinDebtAuctionBidIncrease(uint256 pct_bps) internal {
        libCall("setMinDebtAuctionBidIncrease(address,uint256)", flop(), pct_bps);
    }

    function setDebtAuctionBidDuration(uint256 duration) internal {
        libCall("setDebtAuctionBidDuration(address,uint256)", flop(), duration);
    }

    function setDebtAuctionDuration(uint256 duration) internal {
        libCall("setDebtAuctionDuration(address,uint256)", flop(), duration);
    }

    function setDebtAuctionMKRIncreaseRate(uint256 pct_bps) internal {
        libCall("setDebtAuctionMKRIncreaseRate(address,uint256)", flop(), pct_bps);
    }

    function setMaxTotalDAILiquidationAmount(uint256 amount) internal {
        libCall("setMaxTotalDAILiquidationAmount(address,uint256)", cat(), amount);
    }

    function setEmergencyShutdownProcessingTime(uint256 duration) internal {
        libCall("setEmergencyShutdownProcessingTime(address,uint256)", end(), duration);
    }

    function setGlobalStabilityFee(uint256 rate) internal {
        libCall("setGlobalStabilityFee(address,uint256)", jug(), rate);
    }

    function setDAIReferenceValue(uint256 value) internal {
        libCall("setDAIReferenceValue(address,uint256)", spot(),value);
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    function setIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkDebtCeiling(address,bytes32,uint256)", vat(), ilk, amount);
    }

    function increaseIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libCall("increaseIlkDebtCeiling(address,bytes32,uint256,bool)", vat(), ilk, amount, true);
    }

    function decreaseIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libCall("decreaseIlkDebtCeiling(address,bytes32,uint256,bool)", vat(), ilk, amount, true);
    }

    function setIlkAutoLineParameters(bytes32 ilk, uint256 amount, uint256 gap, uint256 ttl) internal {
        libCall("setIlkAutoLineParameters(address,bytes32,uint256,uint256,uint256)", autoLine(), ilk, amount, gap, ttl);
    }

    function setIlkAutoLineDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkAutoLineDebtCeiling(address,bytes32,uint256)", autoLine(), ilk, amount);
    }

    function removeIlkFromAutoLine(bytes32 ilk) internal {
        libCall("removeIlkFromAutoLine(address,bytes32)", autoLine(), ilk);
    }

    function setIlkMinVaultAmount(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkMinVaultAmount(address,bytes32,uint256)", vat(), ilk, amount);
    }

    function setIlkLiquidationPenalty(bytes32 ilk, uint256 pct_bps) internal {
        libCall("setIlkLiquidationPenalty(address,bytes32,uint256)", cat(), ilk, pct_bps);
    }

    function setIlkMaxLiquidationAmount(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkMaxLiquidationAmount(address,bytes32,uint256)", cat(), ilk, amount);
    }

    function setIlkLiquidationRatio(bytes32 ilk, uint256 pct_bps) internal {
        libCall("setIlkLiquidationRatio(address,bytes32,uint256)", spot(), ilk, pct_bps);
    }

    function setIlkMinAuctionBidIncrease(bytes32 ilk, uint256 pct_bps) internal {
        libCall("setIlkMinAuctionBidIncrease(address,uint256)", flip(ilk), pct_bps);
    }

    function setIlkBidDuration(bytes32 ilk, uint256 duration) internal {
        libCall("setIlkBidDuration(address,uint256)", flip(ilk), duration);
    }

    function setIlkAuctionDuration(bytes32 ilk, uint256 duration) internal {
        libCall("setIlkAuctionDuration(address,uint256)", flip(ilk), duration);
    }

    function setIlkStabilityFee(bytes32 ilk, uint256 rate) internal {
        libCall("setIlkStabilityFee(address,bytes32,uint256,bool)", jug(), ilk, rate, true);
    }

    /***********************/
    /*** Core Management ***/
    /***********************/
    function updateCollateralAuctionContract(bytes32 ilk, address newFlip, address oldFlip) internal {
        libCall("updateCollateralAuctionContract(address,address,address,address,bytes32,address,address)", vat(), cat(), end(), flipperMom(), ilk, newFlip, oldFlip);
    }

    function updateSurplusAuctionContract(address newFlap, address oldFlap) internal {
        libCall("updateSurplusAuctionContract(address,address,address,address)", vat(), vow(), newFlap, oldFlap);
    }

    function updateDebtAuctionContract(address newFlop, address oldFlop) internal {
        libCall("updateDebtAuctionContract(address,address,address,address,address)", vat(), vow(), govGuard(), newFlop, oldFlop);
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/
    function addWritersToMedianWhitelist(address medianizer, address[] memory feeds) internal {
        libCall("addWritersToMedianWhitelist(address,address[])", medianizer, feeds);
    }

    function removeWritersFromMedianWhitelist(address medianizer, address[] memory feeds) internal {
        libCall("removeWritersFromMedianWhitelist(address,address[])", medianizer, feeds);
    }

    function addReadersToMedianWhitelist(address medianizer, address[] memory readers) internal {
        libCall("addReadersToMedianWhitelist(address,address[])", medianizer, readers);
    }

    function addReaderToMedianWhitelist(address medianizer, address reader) internal {
        libCall("addReaderToMedianWhitelist(address,address)", medianizer, reader);
    }

    function removeReadersFromMedianWhitelist(address medianizer, address[] memory readers) internal {
        libCall("removeReadersFromMedianWhitelist(address,address[])", medianizer, readers);
    }

    function removeReaderFromMedianWhitelist(address medianizer, address reader) internal {
        libCall("removeReaderFromMedianWhitelist(address,address)", medianizer, reader);
    }

    function setMedianWritersQuorum(address medianizer, uint256 minQuorum) internal {
        libCall("setMedianWritersQuorum(address,uint256)", medianizer, minQuorum);
    }

    function addReaderToOSMWhitelist(address osm, address reader) internal {
        libCall("addReaderToOSMWhitelist(address,address)", osm, reader);
    }

    function removeReaderFromOSMWhitelist(address osm, address reader) internal {
        libCall("removeReaderFromOSMWhitelist(address,address)", osm, reader);
    }

    function allowOSMFreeze(address osm, bytes32 ilk) internal {
        libCall("allowOSMFreeze(address,address,bytes32)", osmMom(), osm, ilk);
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    // Minimum actions to onboard a collateral to the system with 0 line.
    function addCollateralBase(bytes32 ilk, address gem, address join, address flipper, address pip) internal {
        libCall(
            "addCollateralBase(address,address,address,address,address,address,bytes32,address,address,address,address)",
            vat(), cat(), jug(), end(), spot(), reg(), ilk, gem, join, flipper, pip
        );
    }

    // Complete collateral onboarding logic.
    function addNewCollateral(CollateralOpts memory co) internal {
        // Add the collateral to the system.
        addCollateralBase(co.ilk, co.gem, co.join, co.flip, co.pip);

        // Allow FlipperMom to access to the ilk Flipper
        authorize(co.flip, flipperMom());
        // Disallow Cat to kick auctions in ilk Flipper
        if(!co.isLiquidatable) deauthorize(flipperMom(), co.flip);

        if(co.isOSM) { // If pip == OSM
            // Allow OsmMom to access to the TOKEN OSM
            authorize(co.pip, osmMom());
            if (co.whitelistOSM) { // If median is src in OSM
                // Whitelist OSM to read the Median data (only necessary if it is the first time the token is being added to an ilk)
                addReaderToMedianWhitelist(address(OracleLike(co.pip).src()), co.pip);
            }
            // Whitelist Spotter to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToOSMWhitelist(co.pip, spot());
            // Whitelist End to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToOSMWhitelist(co.pip, end());
            // Set TOKEN OSM in the OsmMom for new ilk
            allowOSMFreeze(co.pip, co.ilk);
        }
        // Increase the global debt ceiling by the ilk ceiling
        increaseGlobalDebtCeiling(co.ilkDebtCeiling);
        // Set the ilk debt ceiling
        setIlkDebtCeiling(co.ilk, co.ilkDebtCeiling);
        // Set the ilk dust
        setIlkMinVaultAmount(co.ilk, co.minVaultAmount);
        // Set the dunk size
        setIlkMaxLiquidationAmount(co.ilk, co.maxLiquidationAmount);
        // Set the ilk liquidation penalty
        setIlkLiquidationPenalty(co.ilk, co.liquidationPenalty);

        // Set the ilk stability fee
        setIlkStabilityFee(co.ilk, co.ilkStabilityFee);

        // Set the ilk percentage between bids
        setIlkMinAuctionBidIncrease(co.ilk, co.bidIncrease);
        // Set the ilk time max time between bids
        setIlkBidDuration(co.ilk, co.bidDuration);
        // Set the ilk max auction duration
        setIlkAuctionDuration(co.ilk, co.auctionDuration);
        // Set the ilk min collateralization ratio
        setIlkLiquidationRatio(co.ilk, co.liquidationRatio);

        // Update ilk spot value in Vat
        updateCollateralPrice(co.ilk);
    }
}

////// lib/dss-interfaces/src/dss/FlapAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/flap.sol
interface FlapAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48);
    function vat() external view returns (address);
    function gem() external view returns (address);
    function beg() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, uint256) external;
    function kick(uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function tend(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function cage(uint256) external;
    function yank(uint256) external;
}

////// lib/dss-interfaces/src/dss/OsmAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/osm
interface OsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function stopped() external view returns (uint256);
    function src() external view returns (address);
    function hop() external view returns (uint16);
    function zzz() external view returns (uint64);
    function cur() external view returns (uint128, uint128);
    function nxt() external view returns (uint128, uint128);
    function bud(address) external view returns (uint256);
    function stop() external;
    function start() external;
    function change(address) external;
    function step(uint16) external;
    function void() external;
    function pass() external view returns (bool);
    function poke() external;
    function peek() external view returns (bytes32, bool);
    function peep() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
}

////// src/DssSpell.sol
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.11; */

/* import "./DssAction.sol"; */
/* import "./OsmAbstract.sol"; */
/* import "./FlapAbstract.sol"; */

contract SpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/b902aac62c589dcc77c74eea6e6de8131c39547a/governance/votes/Executive%20vote%20-%20January%2015%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-01-15 MakerDAO Executive Spell | Hash: 0x2417a1d5c313f1acf1198d99d4356522cbe71e3253af1b7138b3448649c85129";

    // New flap.beg() value
    uint256 constant NEW_BEG     = 1.04E18; // 4%

    // Gnosis
    address constant GNOSIS      = 0xD5885fbCb9a8a8244746010a3BC6F1C6e0269777;

    // SET
    address constant SET_AAVE    = 0x8b1C079f8192706532cC0Bf0C02dcC4fF40d045D;
    address constant SET_LRC     = 0x1D5d9a2DDa0843eD9D8a9Bddc33F1fca9f9C64a0;
    address constant SET_YFI     = 0x1686d01Bd776a1C2A3cCF1579647cA6D39dd2465;
    address constant SET_ZRX     = 0xFF60D1650696238F81BE53D23b3F91bfAAad938f;
    address constant SET_UNI     = 0x3c3Afa479d8C95CF0E1dF70449Bb5A14A3b7Af67;


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant THREE_PT_FIVE_PERCENT_RATE = 1000000001090862085746321732;
    uint256 constant FOUR_PERCENT_RATE          = 1000000001243680656318820312;
    uint256 constant FIVE_PERCENT_RATE          = 1000000001547125957863212448;
    uint256 constant SIX_PERCENT_RATE           = 1000000001847694957439350562;
    uint256 constant SIX_PT_FIVE_PERCENT_RATE   = 1000000001996917783620820123;


    /**
        @dev constructor (required)
        @param lib         address of the DssExecLib contract
        @param officeHours true if officehours enabled
    */
    constructor(address lib, bool officeHours) public DssAction(lib, officeHours) {}

    function actions() public override {

        // Adjust FLAP Auction Parameters - January 11, 2021
        // https://vote.makerdao.com/polling/QmT79sT6#poll-detail
        FlapAbstract(flap()).file("beg", NEW_BEG);
        setSurplusAuctionBidDuration(1 hours);


        // Increase the System Surplus Buffer - January 11, 2021
        // https://vote.makerdao.com/polling/QmcXtm1d#poll-detail
        setSurplusBuffer(10_000_000);


        // Rates Proposal - January 11, 2021
        // https://vote.makerdao.com/polling/QmfBQ4Bh#poll-detail
        // Increase the ETH-A Stability Fee from 2.5% to 3.5%.
        /// @dev setIlkStabilityFee will drip() the collateral
        setIlkStabilityFee("ETH-A",  THREE_PT_FIVE_PERCENT_RATE);
        // Increase the ETH-B Stability Fee from 5% to 6.5%.
        setIlkStabilityFee("ETH-B",  SIX_PT_FIVE_PERCENT_RATE);
        // Decrease the WBTC-A Stability Fee from 4.5% to 4%.
        setIlkStabilityFee("WBTC-A", FOUR_PERCENT_RATE);
        // Decrease the YFI-A Stability Fee from 9% to 6%.
        setIlkStabilityFee("YFI-A",  SIX_PERCENT_RATE);
        // Decrease the MANA-A Stability Fee from 10% to 5%.
        setIlkStabilityFee("MANA-A", FIVE_PERCENT_RATE);
        // Decrease the AAVE-A Stability Fee from 6% to 4%.
        setIlkStabilityFee("AAVE-A", FOUR_PERCENT_RATE);


        address PIP_YFI = getChangelogAddress("PIP_YFI");
        address PIP_ZRX = getChangelogAddress("PIP_ZRX");

        // Whitelist Gnosis on Multiple Oracles - January 11, 2021
        // https://vote.makerdao.com/polling/QmNwTMcB#poll-detail
        addReaderToOSMWhitelist(getChangelogAddress("PIP_WBTC"), GNOSIS);
        addReaderToOSMWhitelist(getChangelogAddress("PIP_LINK"), GNOSIS);
        addReaderToOSMWhitelist(getChangelogAddress("PIP_COMP"), GNOSIS);
        addReaderToOSMWhitelist(PIP_YFI,                         GNOSIS);
        addReaderToOSMWhitelist(PIP_ZRX,                         GNOSIS);


        // Whitelist Set Protocol on Multiple Oracles - January 11, 2021
        // https://vote.makerdao.com/polling/QmTctW6i#poll-detail
        addReaderToMedianWhitelist(OsmAbstract(getChangelogAddress("PIP_AAVE")).src(), SET_AAVE);
        addReaderToMedianWhitelist(OsmAbstract(getChangelogAddress("PIP_LRC")).src(),  SET_LRC);
        addReaderToMedianWhitelist(OsmAbstract(PIP_YFI).src(),                         SET_YFI);
        addReaderToMedianWhitelist(OsmAbstract(PIP_ZRX).src(),                         SET_ZRX);
        addReaderToMedianWhitelist(OsmAbstract(getChangelogAddress("PIP_UNI")).src(),  SET_UNI);


        // Limiting Governance Attack Surface for Stablecoins
        // https://forum.makerdao.com/t/limiting-governance-attack-surface-for-stablecoins/6057
        deauthorize(getChangelogAddress("MCD_FLIP_USDC_A"),   flipperMom());
        deauthorize(getChangelogAddress("MCD_FLIP_USDC_B"),   flipperMom());
        deauthorize(getChangelogAddress("MCD_FLIP_TUSD_A"),   flipperMom());
        deauthorize(getChangelogAddress("MCD_FLIP_PAXUSD_A"), flipperMom());
        deauthorize(getChangelogAddress("MCD_FLIP_GUSD_A"),   flipperMom());
    }
}

////// src/SpellFab.sol
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.11; */

interface DssExecFactory {
    function newExec(string memory,uint256,address) external returns (address);
    function newWeeklyExec(string memory,address) external returns (address);
    function newMonthlyExec(string memory,address) external returns (address);
}

/* import "./DssSpell.sol"; */

contract SpellFab {

    // Mainnet
    address public constant  EXEC_FACTORY = 0xf610426dFAb48f7AE5678e97Be0286C1aDCedb11;
    // Mainnet
    address public constant  EXEC_LIB     = 0xFC32E74e6e33D924bd2fBFC7A27b6F2177032760;
    address public immutable action;
    address public immutable spell;

    constructor() public {
        address _action = action = address(new SpellAction(EXEC_LIB, false)); // office hours disabled
        spell  = DssExecFactory(EXEC_FACTORY).newWeeklyExec(
            SpellAction(_action).description(),    // action description
            address(_action)                       // action address
        );
    }

}