// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.16 >=0.5.12 >=0.8.16 <0.9.0;

////// lib/dss-exec-lib/src/CollateralOpts.sol
//
// CollateralOpts.sol -- Data structure for onboarding collateral
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

struct CollateralOpts {
    bytes32 ilk;
    address gem;
    address join;
    address clip;
    address calc;
    address pip;
    bool    isLiquidatable;
    bool    isOSM;
    bool    whitelistOSM;
    uint256 ilkDebtCeiling;
    uint256 minVaultAmount;
    uint256 maxLiquidationAmount;
    uint256 liquidationPenalty;
    uint256 ilkStabilityFee;
    uint256 startingPriceFactor;
    uint256 breakerTolerance;
    uint256 auctionDuration;
    uint256 permittedDrop;
    uint256 liquidationRatio;
    uint256 kprFlatReward;
    uint256 kprPctReward;
}

////// lib/dss-exec-lib/src/DssExecLib.sol
//
// DssExecLib.sol -- MakerDAO Executive Spellcrafting Library
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

/* import "./CollateralOpts.sol"; */

interface Initializable {
    function init(bytes32) external;
}

interface Authorizable {
    function rely(address) external;
    function deny(address) external;
    function setAuthority(address) external;
}

interface Fileable {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
}

interface Drippable {
    function drip() external returns (uint256);
    function drip(bytes32) external returns (uint256);
}

interface Pricing {
    function poke(bytes32) external;
}

interface ERC20 {
    function decimals() external returns (uint8);
}

interface DssVat {
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
    function Line() external view returns (uint256);
    function suck(address, address, uint256) external;
}

interface ClipLike {
    function vat() external returns (address);
    function dog() external returns (address);
    function spotter() external view returns (address);
    function calc() external view returns (address);
    function ilk() external returns (bytes32);
}

interface DogLike {
    function ilks(bytes32) external returns (address clip, uint256 chop, uint256 hole, uint256 dirt);
}

interface JoinLike {
    function vat() external returns (address);
    function ilk() external returns (bytes32);
    function gem() external returns (address);
    function dec() external returns (uint256);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// Includes Median and OSM functions
interface OracleLike_2 {
    function src() external view returns (address);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface MomLike {
    function setOsm(bytes32, address) external;
    function setPriceTolerance(address, uint256) external;
}

interface RegistryLike {
    function add(address) external;
    function xlip(bytes32) external view returns (address);
}

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike {
    function setVersion(string calldata) external;
    function setIPFS(string calldata) external;
    function setSha256sum(string calldata) external;
    function getAddress(bytes32) external view returns (address);
    function setAddress(bytes32, address) external;
    function removeAddress(bytes32) external;
}

interface IAMLike {
    function ilks(bytes32) external view returns (uint256,uint256,uint48,uint48,uint48);
    function setIlk(bytes32,uint256,uint256,uint256) external;
    function remIlk(bytes32) external;
    function exec(bytes32) external returns (uint256);
}

interface LerpFactoryLike {
    function newLerp(bytes32 name_, address target_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
    function newIlkLerp(bytes32 name_, address target_, bytes32 ilk_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
}

interface LerpLike {
    function tick() external returns (uint256);
}

interface RwaOracleLike {
    function bump(bytes32 ilk, uint256 val) external;
}


library DssExecLib {

    /* WARNING

The following library code acts as an interface to the actual DssExecLib
library, which can be found in its own deployed contract. Only trust the actual
library's implementation.

    */

    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    uint256 constant internal WAD      = 10 ** 18;
    uint256 constant internal RAY      = 10 ** 27;
    uint256 constant internal RAD      = 10 ** 45;
    uint256 constant internal THOUSAND = 10 ** 3;
    uint256 constant internal MILLION  = 10 ** 6;
    uint256 constant internal BPS_ONE_PCT             = 100;
    uint256 constant internal BPS_ONE_HUNDRED_PCT     = 100 * BPS_ONE_PCT;
    uint256 constant internal RATES_ONE_HUNDRED_PCT   = 1000000021979553151239153027;
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function flap()       public view returns (address) { return getChangelogAddress("MCD_FLAP"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function updateCollateralPrice(bytes32 _ilk) public {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function increaseGlobalDebtCeiling(uint256 _amount) public {}
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {}
    function removeIlkFromAutoLine(bytes32 _ilk) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {}
    function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {}
}

////// lib/dss-exec-lib/src/DssAction.sol
//
// DssAction.sol -- DSS Executive Spell Actions
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

/* import "./DssExecLib.sol"; */
/* import "./CollateralOpts.sol"; */

interface OracleLike_1 {
    function src() external view returns (address);
}

abstract contract DssAction {

    using DssExecLib for *;

    // Modifier used to limit execution time when office hours is enabled
    modifier limited {
        require(DssExecLib.canCast(uint40(block.timestamp), officeHours()), "Outside office hours");
        _;
    }

    // Office Hours defaults to true by default.
    //   To disable office hours, override this function and
    //    return false in the inherited action.
    function officeHours() public view virtual returns (bool) {
        return true;
    }

    // DssExec calls execute. We limit this function subject to officeHours modifier.
    function execute() external limited {
        actions();
    }

    // DssAction developer must override `actions()` and place all actions to be called inside.
    //   The DssExec function will call this subject to the officeHours limiter
    //   By keeping this function public we allow simulations of `execute()` on the actions outside of the cast time.
    function actions() public virtual;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view virtual returns (string memory);

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external view returns (uint256 castTime) {
        require(eta <= type(uint40).max);
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
    }
}

////// lib/dss-exec-lib/src/DssExec.sol
//
// DssExec.sol -- MakerDAO Executive Spell Template
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

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
    function description() external view returns (string memory);
    function nextCastTime(uint256) external view returns (uint256);
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
    function description() external view returns (string memory) {
        return SpellAction(action).description();
    }

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellAction(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. block.timestamp + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) {
        pause       = PauseAbstract(log.getAddress("MCD_PAUSE"));
        expiration  = _expiration;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;                    // Required for assembly access
        address _action = _spellAction;  // Required for assembly access
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

////// lib/dss-test/lib/dss-interfaces/src/ERC/GemAbstract.sol
/* pragma solidity >=0.5.12; */

// A base ERC-20 abstract class
// https://eips.ethereum.org/EIPS/eip-20
interface GemAbstract {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/VatAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/VestAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-vest/blob/master/src/DssVest.sol
interface VestAbstract {
    function TWENTY_YEARS() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function awards(uint256) external view returns (address, uint48, uint48, uint48, address, uint8, uint128, uint128);
    function ids() external view returns (uint256);
    function cap() external view returns (uint256);
    function usr(uint256) external view returns (address);
    function bgn(uint256) external view returns (uint256);
    function clf(uint256) external view returns (uint256);
    function fin(uint256) external view returns (uint256);
    function mgr(uint256) external view returns (address);
    function res(uint256) external view returns (uint256);
    function tot(uint256) external view returns (uint256);
    function rxd(uint256) external view returns (uint256);
    function file(bytes32, uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function vest(uint256) external;
    function vest(uint256, uint256) external;
    function accrued(uint256) external view returns (uint256);
    function unpaid(uint256) external view returns (uint256);
    function restrict(uint256) external;
    function unrestrict(uint256) external;
    function yank(uint256) external;
    function yank(uint256, uint256) external;
    function move(uint256, address) external;
    function valid(uint256) external view returns (bool);
}

////// src/DssSpell.sol
// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
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

/* pragma solidity 0.8.16; */

/* import "./DssExec.sol"; */
/* import "./DssAction.sol"; */
/* import "./VatAbstract.sol"; */
/* import "./VestAbstract.sol"; */
/* import "./GemAbstract.sol"; */

interface RwaLiquidationOracleLike_1 {
    function bump(bytes32 ilk, uint256 val) external;
}

interface ProxyLike_1 {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/bf322ac65482bfc3f42bdb58dcc11a2f2ceeba5a/governance/votes/Executive%20vote%20-%20November%2029%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-11-29 MakerDAO Executive Spell | Hash: 0xbd47c214fb16080be97b08f3cf5b45ca9b3d5ff7bbc2057501534e05d84823ea";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- RWA Foundation Service Provider Changes ----------
    // Forum: https://forum.makerdao.com/t/dao-resolution-rwa-foundation-service-provider-changes/22866

    // Approve Dao resolution with IPFS hash QmPiEHtt8rkVtSibBXMrhEzHUmSriXWz4AL2bjscq8dUvU
    // Note: by the previous convention it is comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmPiEHtt8rkVtSibBXMrhEzHUmSriXWz4AL2bjscq8dUvU";

    // ---------- Rates ----------
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE = ;
    uint256 internal constant FIVE_PT_FIVE_FOUR_PCT_RATE  = 1000000001709786974743980088;
    uint256 internal constant FIVE_PT_SEVEN_NINE_PCT_RATE = 1000000001784811360376128985;
    uint256 internal constant SIX_PT_TWO_NINE_PCT_RATE    = 1000000001934329706253075715;

    // ---------- Math ----------
    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant BILLION  = 10 ** 9;
    uint256 internal constant WAD      = 10 ** 18;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- SBE parameter changes ----------
    address internal immutable MCD_VOW            = DssExecLib.vow();
    address internal immutable MCD_FLAP           = DssExecLib.flap();

    // ---------- Reduce PSM-GUSD-A Debt Ceiling ----------
    VatAbstract internal immutable vat            = VatAbstract(DssExecLib.vat());

    // ---------- Increase RWA014-A (Coinbase Custody) Debt Ceiling ----------
    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

    // ---------- Andromeda Legal Expenses ----------
    address internal constant BLOCKTOWER_WALLET_2 = 0xc4dB894A11B1eACE4CDb794d0753A3cB7A633767;

    // ---------- Trigger Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x68a075249fA77173b8d1B92750c9920423997e2B;

    // ---------- Payment Streams ----------
    address internal immutable MCD_VEST_DAI          = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address internal immutable MCD_VEST_MKR_TREASURY = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    GemAbstract internal immutable MKR               = GemAbstract(DssExecLib.mkr());
    address internal constant ECOSYSTEM_FACILITATOR  = 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75;

    // ---------- Timestamps ----------
    // 2023-12-01 00:00:00
    uint256 internal constant DEC_01_2023 = 1701385200;
    // 2024-11-30 23:59:59
    uint256 internal constant NOV_30_2024 = 1733007599;

    function actions() public override {
        // ---------- Stability Fee Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882#increase-rwa014-a-coinbase-custody-debt-ceiling-9

        // Decrease the WBTC-A Stability Fee (SF) by 0.07%, from 5.86% to 5.79%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_SEVEN_NINE_PCT_RATE, /* doDrip = */ true);

        // Decrease the WBTC-B Stability Fee (SF) by 0.07%, from 6.36% to 6.29%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_TWO_NINE_PCT_RATE, /* doDrip = */ true);

        // Decrease the WBTC-C Stability Fee (SF) by 0.07%, from 5.61% to 5.54%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_FIVE_FOUR_PCT_RATE, /* doDrip = */ true);

        // ---------- Reduce PSM-GUSD-A Debt Ceiling ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882/2

        // Note: record currently set debt ceiling for PSM-GUSD-A
        (,,,uint256 lineReduction,) = vat.ilks("PSM-GUSD-A");

        // Remove PSM-GUSD-A from `Autoline`
        DssExecLib.removeIlkFromAutoLine("PSM-GUSD-A");

        // Set PSM-GUSD-A debt ceiling to 0
        DssExecLib.setIlkDebtCeiling("PSM-GUSD-A", 0);

        // Reduce Global Debt Ceiling? Yes
        vat.file("Line", vat.Line() - lineReduction);

        // ---------- Increase RWA014-A (Coinbase Custody) Debt Ceiling ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882#increase-rwa014-a-coinbase-custody-debt-ceiling-9

        // Increase the RWA014-A (Coinbase Custody) debt ceiling by 1b DAI, from 500M to 1.5b
        DssExecLib.increaseIlkDebtCeiling("RWA014-A", 1 * BILLION, /* global = */ true);

        // Note: we have to bump the oracle price to account for the new DC
        // Note: the formula is `Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio`
        // Note: as stability fee is 0 for this deal, this should be equal to ilk DC
        RwaLiquidationOracleLike_1(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA014-A",
            1_500 * MILLION * WAD
        );

        // Note: we have to update collateral price to propagate the changes
        DssExecLib.updateCollateralPrice("RWA014-A");

        // ---------- SBE parameter changes ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-transaction-analysis-parameter-reconfiguration-update-3/22876

        // Increase bump by 10,000, from 20,000 to 30,000
        DssExecLib.setValue(MCD_VOW, "bump", 30 * THOUSAND * RAD);

        // Increase hop by 9,460, from 6,308 to 15,768
        DssExecLib.setValue(MCD_FLAP, "hop", 15_768);

        // ---------- Andromeda Legal Expenses ----------
        // Forum: https://forum.makerdao.com/t/project-andromeda-legal-expenses-ii/22577/4

        // Transfer 201,738 Dai to 0xc4dB894A11B1eACE4CDb794d0753A3cB7A633767
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKTOWER_WALLET_2, 201_738);

        // ---------- Trigger Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/accounting-discrepancy-in-the-dai-market/22845/2

        // Mainnet - 0x68a075249fA77173b8d1B92750c9920423997e2B
        ProxyLike_1(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // ---------- Yank Steakhouse and TechOps DSS-Vest Streams ----------
        // Forum: https://forum.makerdao.com/t/mip102c2-sp20-mip-amendment-subproposal/22334
        // MIP: https://mips.makerdao.com/mips/details/MIP113#7-1-1-1-1a

        // Yank Steakhouse DAI stream ID 19
        VestAbstract(MCD_VEST_DAI).yank(19);

        // Yank TechOps DAI stream ID 18
        VestAbstract(MCD_VEST_DAI).yank(18);

        // Yank Steakhouse MKR stream ID 32
        VestAbstract(MCD_VEST_MKR_TREASURY).yank(32);

        // Yank TechOps MKR stream ID 33
        VestAbstract(MCD_VEST_MKR_TREASURY).yank(33);

        // ---------- Set up Ecosystem Facilitator DSS-Vest Streams ----------
        // Forum: https://forum.makerdao.com/t/mip102c2-sp20-mip-amendment-subproposal/22334
        // MIP: https://mips.makerdao.com/mips/details/MIP113#7-1-1-1-1a

        // Ecosystem | 2023-12-01 00:00:00 to 2024-11-30 23:59:59 | 504,000.00 DAI | 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(
                ECOSYSTEM_FACILITATOR,     // usr
                504_000 * WAD,             // tot
                DEC_01_2023,               // bgn
                NOV_30_2024 - DEC_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Note: For the MKR stream we need to increase allowance by new vesting delta
        MKR.approve(address(MCD_VEST_MKR_TREASURY), MKR.allowance(address(this), address(MCD_VEST_MKR_TREASURY)) + 216 * WAD);

        // Ecosystem | 2023-12-01 00:00:00 to 2024-11-30 23:59:59 | 216.00 MKR | 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75
        VestAbstract(MCD_VEST_MKR_TREASURY).restrict(
            VestAbstract(MCD_VEST_MKR_TREASURY).create(
                ECOSYSTEM_FACILITATOR,     // usr
                216 * WAD,                 // tot
                DEC_01_2023,               // bgn
                NOV_30_2024 - DEC_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}

