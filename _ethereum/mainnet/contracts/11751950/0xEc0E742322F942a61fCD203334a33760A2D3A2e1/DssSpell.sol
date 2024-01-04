// SPDX-License-Identifier: GPL-3.0-or-later
// hevm: flattened sources of src/DssSpell.sol
pragma solidity =0.6.11 >=0.6.11 <0.7.0;

////// lib/dss-exec-lib/src/CollateralOpts.sol
/* pragma solidity ^0.6.11; */

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

/* pragma solidity ^0.6.11; */

/* import "./CollateralOpts.sol"; */

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike {
    function getAddress(bytes32) external view returns (address);
}

interface RegistryLike {
    function ilkData(bytes32) external view returns (
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
    function vat()        internal view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        internal view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function jug()        internal view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        internal view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        internal view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        internal view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        internal view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spot()       internal view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function flap()       internal view returns (address) { return getChangelogAddress("MCD_FLAP"); }
    function flop()       internal view returns (address) { return getChangelogAddress("MCD_FLOP"); }
    function osmMom()     internal view returns (address) { return getChangelogAddress("OSM_MOM"); }
    function govGuard()   internal view returns (address) { return getChangelogAddress("GOV_GUARD"); }
    function flipperMom() internal view returns (address) { return getChangelogAddress("FLIPPER_MOM"); }
    function autoLine()   internal view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }

    function flip(bytes32 ilk) internal view returns (address) {
        (,,,, address _flip,,,) = RegistryLike(reg()).ilkData(ilk);
        return _flip;
    }

    function getChangelogAddress(bytes32 key) internal view returns (address) {
        return ChainlogLike(LOG).getAddress(key);
    }

    function libcall(bytes memory data) internal {
        (bool ok,) = lib.delegatecall(data);
        require(ok, "DssAction/failed-lib-call");
    }


    /****************************/
    /*** Changelog Management ***/
    /****************************/
    function setChangelogAddress(bytes32 key, address value) internal {
        libcall(abi.encodeWithSignature("setChangelogAddress(address,bytes32,address)", LOG, key, value));
    }

    function setChangelogVersion(string memory version) internal {
        libcall(abi.encodeWithSignature("setChangelogVersion(address,string)", LOG, version));
    }

    function setChangelogIPFS(string memory ipfs) internal {
        libcall(abi.encodeWithSignature("setChangelogIPFS(address,string)", LOG, ipfs));
    }

    function setChangelogSHA256(string memory SHA256) internal {
        libcall(abi.encodeWithSignature("setChangelogSHA256(address,string)", LOG, SHA256));
    }

    /**********************/
    /*** Authorizations ***/
    /**********************/
    function authorize(address base, address ward) internal virtual {
        libcall(abi.encodeWithSignature("authorize(address,address)", base, ward));
    }

    function deauthorize(address base, address ward) internal {
        libcall(abi.encodeWithSignature("deauthorize(address,address)", base, ward));
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    function accumulateDSR() internal {
        libcall(abi.encodeWithSignature("accumulateDSR(address)", pot()));
    }

    function accumulateCollateralStabilityFees(bytes32 ilk) internal {
        libcall(abi.encodeWithSignature("accumulateCollateralStabilityFees(address,bytes32)", jug(), ilk));
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    function updateCollateralPrice(bytes32 ilk) internal {
        libcall(abi.encodeWithSignature("updateCollateralPrice(address,bytes32)", spot(), ilk));
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    function setContract(address base, bytes32 what, address addr) internal {
        libcall(abi.encodeWithSignature("setContract(address,bytes32,address)", base, what, addr));
    }

    function setContract(address base, bytes32 ilk, bytes32 what, address addr) internal {
        libcall(abi.encodeWithSignature("setContract(address,bytes32,bytes32,address)", base, ilk, what, addr));
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    function setGlobalDebtCeiling(uint256 amount) internal {
        libcall(abi.encodeWithSignature("setGlobalDebtCeiling(address,uint256)", vat(), amount));
    }

    function increaseGlobalDebtCeiling(uint256 amount) internal {
        libcall(abi.encodeWithSignature("increaseGlobalDebtCeiling(address,uint256)", vat(), amount));
    }

    function decreaseGlobalDebtCeiling(uint256 amount) internal {
        libcall(abi.encodeWithSignature("decreaseGlobalDebtCeiling(address,uint256)", vat(), amount));
    }

    function setDSR(uint256 rate) internal {
        libcall(abi.encodeWithSignature("setDSR(address,uint256)", pot(), rate));
    }

    function setSurplusAuctionAmount(uint256 amount) internal {
        libcall(abi.encodeWithSignature("setSurplusAuctionAmount(address,uint256)", vow(), amount));
    }

    function setSurplusBuffer(uint256 amount) internal {
        libcall(abi.encodeWithSignature("setSurplusBuffer(address,uint256)", vow(), amount));
    }

    function setMinSurplusAuctionBidIncrease(uint256 pct_bps) internal {
        libcall(abi.encodeWithSignature("setMinSurplusAuctionBidIncrease(address,uint256)", flap(), pct_bps));
    }

    function setSurplusAuctionBidDuration(uint256 duration) internal {
        libcall(abi.encodeWithSignature("setSurplusAuctionBidDuration(address,uint256)", flap(), duration));
    }

    function setSurplusAuctionDuration(uint256 duration) internal {
        libcall(abi.encodeWithSignature("setSurplusAuctionDuration(address,uint256)", flap(), duration));
    }

    function setDebtAuctionDelay(uint256 duration) internal {
        libcall(abi.encodeWithSignature("setDebtAuctionDelay(address,uint256)", vow(), duration));
    }

    function setDebtAuctionDAIAmount(uint256 amount) internal {
        libcall(abi.encodeWithSignature("setDebtAuctionDAIAmount(address,uint256)", vow(), amount));
    }

    function setDebtAuctionMKRAmount(uint256 amount) internal {
        libcall(abi.encodeWithSignature("setDebtAuctionMKRAmount(address,uint256)", vow(), amount));
    }

    function setMinDebtAuctionBidIncrease(uint256 pct_bps) internal {
        libcall(abi.encodeWithSignature("setMinDebtAuctionBidIncrease(address,uint256)", flop(), pct_bps));
    }

    function setDebtAuctionBidDuration(uint256 duration) internal {
        libcall(abi.encodeWithSignature("setDebtAuctionBidDuration(address,uint256)", flop(), duration));
    }

    function setDebtAuctionDuration(uint256 duration) internal {
        libcall(abi.encodeWithSignature("setDebtAuctionDuration(address,uint256)", flop(), duration));
    }

    function setDebtAuctionMKRIncreaseRate(uint256 pct_bps) internal {
        libcall(abi.encodeWithSignature("setDebtAuctionMKRIncreaseRate(address,uint256)", flop(), pct_bps));
    }

    function setMaxTotalDAILiquidationAmount(uint256 amount) internal {
        libcall(abi.encodeWithSignature("setMaxTotalDAILiquidationAmount(address,uint256)", cat(), amount));
    }

    function setEmergencyShutdownProcessingTime(uint256 duration) internal {
        libcall(abi.encodeWithSignature("setEmergencyShutdownProcessingTime(address,uint256)", end(), duration));
    }

    function setGlobalStabilityFee(uint256 rate) internal {
        libcall(abi.encodeWithSignature("setGlobalStabilityFee(address,uint256)", jug(), rate));
    }

    function setDAIReferenceValue(uint256 value) internal {
        libcall(abi.encodeWithSignature("setDAIReferenceValue(address,uint256)", spot(),value));
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    function setIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libcall(abi.encodeWithSignature("setIlkDebtCeiling(address,bytes32,uint256)", vat(), ilk, amount));
    }

    function increaseIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libcall(abi.encodeWithSignature("increaseIlkDebtCeiling(address,bytes32,uint256,bool)", vat(), ilk, amount, true));
    }

    function decreaseIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libcall(abi.encodeWithSignature("decreaseIlkDebtCeiling(address,bytes32,uint256,bool)", vat(), ilk, amount, true));
    }

    function setIlkAutoLineParameters(bytes32 ilk, uint256 amount, uint256 gap, uint256 ttl) internal {
        libcall(abi.encodeWithSignature("setIlkAutoLineParameters(address,bytes32,uint256,uint256,uint256)", autoLine(), ilk, amount, gap, ttl));
    }

    function setIlkAutoLineDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libcall(abi.encodeWithSignature("setIlkAutoLineDebtCeiling(address,bytes32,uint256)", autoLine(), ilk, amount));
    }

    function removeIlkFromAutoLine(bytes32 ilk) internal {
        libcall(abi.encodeWithSignature("removeIlkFromAutoLine(address,bytes32)", autoLine(), ilk));
    }

    function setIlkMinVaultAmount(bytes32 ilk, uint256 amount) internal {
        libcall(abi.encodeWithSignature("setIlkMinVaultAmount(address,bytes32,uint256)", vat(), ilk, amount));
    }

    function setIlkLiquidationPenalty(bytes32 ilk, uint256 pct_bps) internal {
        libcall(abi.encodeWithSignature("setIlkLiquidationPenalty(address,bytes32,uint256)", cat(), ilk, pct_bps));
    }

    function setIlkMaxLiquidationAmount(bytes32 ilk, uint256 amount) internal {
        libcall(abi.encodeWithSignature("setIlkMaxLiquidationAmount(address,bytes32,uint256)", cat(), ilk, amount));
    }

    function setIlkLiquidationRatio(bytes32 ilk, uint256 pct_bps) internal {
        libcall(abi.encodeWithSignature("setIlkLiquidationRatio(address,bytes32,uint256)", spot(), ilk, pct_bps));
    }

    function setIlkMinAuctionBidIncrease(bytes32 ilk, uint256 pct_bps) internal {
        libcall(abi.encodeWithSignature("setIlkMinAuctionBidIncrease(address,uint256)", flip(ilk), pct_bps));
    }

    function setIlkBidDuration(bytes32 ilk, uint256 duration) internal {
        libcall(abi.encodeWithSignature("setIlkBidDuration(address,uint256)", flip(ilk), duration));
    }

    function setIlkAuctionDuration(bytes32 ilk, uint256 duration) internal {
        libcall(abi.encodeWithSignature("setIlkAuctionDuration(address,uint256)", flip(ilk), duration));
    }

    function setIlkStabilityFee(bytes32 ilk, uint256 rate) internal {
        libcall(abi.encodeWithSignature("setIlkStabilityFee(address,bytes32,uint256,bool)", jug(), ilk, rate, true));
    }

    /***********************/
    /*** Core Management ***/
    /***********************/
    function updateCollateralAuctionContract(bytes32 ilk, address newFlip, address oldFlip) internal {
        libcall(abi.encodeWithSignature("updateCollateralAuctionContract(address,address,address,address,bytes32,address,address)", vat(), cat(), end(), flipperMom(), ilk, newFlip, oldFlip));
    }

    function updateSurplusAuctionContract(address newFlap, address oldFlap) internal {
        libcall(abi.encodeWithSignature("updateSurplusAuctionContract(address,address,address,address)", vat(), vow(), newFlap, oldFlap));
    }

    function updateDebtAuctionContract(address newFlop, address oldFlop) internal {
        libcall(abi.encodeWithSignature("updateDebtAuctionContract(address,address,address,address,address)", vat(), vow(), govGuard(), newFlop, oldFlop));
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/
    function addWritersToMedianWhitelist(address medianizer, address[] memory feeds) internal {
        libcall(abi.encodeWithSignature("addWritersToMedianWhitelist(address,address[])", medianizer, feeds));
    }

    function removeWritersFromMedianWhitelist(address medianizer, address[] memory feeds) internal {
        libcall(abi.encodeWithSignature("removeWritersFromMedianWhitelist(address,address[])", medianizer, feeds));
    }

    function addReadersToMedianWhitelist(address medianizer, address[] memory readers) internal {
        libcall(abi.encodeWithSignature("addReadersToMedianWhitelist(address,address[])", medianizer, readers));
    }

    function addReaderToMedianWhitelist(address medianizer, address reader) internal {
        libcall(abi.encodeWithSignature("addReaderToMedianWhitelist(address,address)", medianizer, reader));
    }

    function removeReadersFromMedianWhitelist(address medianizer, address[] memory readers) internal {
        libcall(abi.encodeWithSignature("removeReadersFromMedianWhitelist(address,address[])", medianizer, readers));
    }

    function removeReaderFromMedianWhitelist(address medianizer, address reader) internal {
        libcall(abi.encodeWithSignature("removeReaderFromMedianWhitelist(address,address)", medianizer, reader));
    }

    function setMedianWritersQuorum(address medianizer, uint256 minQuorum) internal {
        libcall(abi.encodeWithSignature("setMedianWritersQuorum(address,uint256)", medianizer, minQuorum));
    }

    function addReaderToOSMWhitelist(address osm, address reader) internal {
        libcall(abi.encodeWithSignature("addReaderToOSMWhitelist(address,address)", osm, reader));
    }

    function removeReaderFromOSMWhitelist(address osm, address reader) internal {
        libcall(abi.encodeWithSignature("removeReaderFromOSMWhitelist(address,address)", osm, reader));
    }

    function allowOSMFreeze(address osm, bytes32 ilk) internal {
        libcall(abi.encodeWithSignature("allowOSMFreeze(address,address,bytes32)", osmMom(), osm, ilk));
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    // Minimum actions to onboard a collateral to the system with 0 line.
    function addCollateralBase(bytes32 ilk, address gem, address join, address flipper, address pip) internal {
        libcall(abi.encodeWithSignature(
            "addCollateralBase(address,address,address,address,address,address,bytes32,address,address,address,address)",
            vat(), cat(), jug(), end(), spot(), reg(), ilk, gem, join, flipper, pip
        ));
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

////// lib/dss-exec-lib/src/DssExec.sol
//
// DssExec.sol -- MakerDAO Executive Spell Template
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

/* pragma solidity ^0.6.11; */

interface PauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface Changelog {
    function getAddress(bytes32) external view returns (address);
}

interface SpellAction {
    function officeHours() external view returns (bool);
}

contract DssExec {

    Changelog      constant public log   = Changelog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                 public eta;
    bytes                   public sig;
    bool                    public done;
    bytes32       immutable public tag;
    address       immutable public action;
    uint256       immutable public expiration;
    PauseAbstract immutable public pause;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    string                  public description;

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        require(eta != 0, "DssExec/spell-not-scheduled");
        castTime = block.timestamp > eta ? block.timestamp : eta; // Any day at XX:YY

        if (SpellAction(action).officeHours()) {
            uint256 day    = (castTime / 1 days + 3) % 7;
            uint256 hour   = castTime / 1 hours % 24;
            uint256 minute = castTime / 1 minutes % 60;
            uint256 second = castTime % 60;

            if (day >= 5) {
                castTime += (6 - day) * 1 days;                 // Go to Sunday XX:YY
                castTime += (24 - hour + 14) * 1 hours;         // Go to 14:YY UTC Monday
                castTime -= minute * 1 minutes + second;        // Go to 14:00 UTC
            } else {
                if (hour >= 21) {
                    if (day == 4) castTime += 2 days;           // If Friday, fast forward to Sunday XX:YY
                    castTime += (24 - hour + 14) * 1 hours;     // Go to 14:YY UTC next day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                } else if (hour < 14) {
                    castTime += (14 - hour) * 1 hours;          // Go to 14:YY UTC same day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                }
            }
        }
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. now + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(string memory _description, uint256 _expiration, address _spellAction) public {
        pause       = PauseAbstract(log.getAddress("MCD_PAUSE"));
        description = _description;
        expiration  = _expiration;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;                    // Required for assembly access
        address _action = _spellAction;  // Required for assembly access
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
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

/* import "./DssExec.sol"; */
/* import "./DssAction.sol"; */

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/e2929f286f2c486c0485637967284630643ddc8d/governance/votes/Executive%20vote%20-%20January%2029%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-01-29 MakerDAO Executive Spell | Hash: 0xbb7974fc8e89c016a6c42f5ced4b1f42e45671e5f4f4009535658affb6a98343";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    /**
        @dev constructor (required)
        @param lib         address of the DssExecLib contract
        @param officeHours true if officehours enabled
    */
    constructor(address lib, bool officeHours) public DssAction(lib, officeHours) {}

    uint256 constant MILLION = 10**6;

    function actions() public override {
        //                           ilk            line           gap       ttl
        setIlkAutoLineParameters("ETH-A", 1500 * MILLION, 30 * MILLION, 12 hours);
    }
}

contract DssSpell is DssExec {
    address public constant LIB = 0xFC32E74e6e33D924bd2fBFC7A27b6F2177032760;
    DssSpellAction public spell = new DssSpellAction(LIB, false);
    constructor() DssExec(spell.description(), now + 30 days, address(spell)) public {}
}