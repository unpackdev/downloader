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
interface ChainlogLike_1 {
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
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function esm()        public view returns (address) { return getChangelogAddress("MCD_ESM"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function flipperMom() public view returns (address) { return getChangelogAddress("FLIPPER_MOM"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogAddress(bytes32 _key, address _val) public {}
    function setChangelogVersion(string memory _version) public {}
    function authorize(address _base, address _ward) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
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

/* import "./GemAbstract.sol"; */

interface RwaLiquidationOracleLike_1 {
    function tell(bytes32 ilk) external;
}

interface ChainlogLike_2 {
    function removeAddress(bytes32) external;
}

interface RwaInputConduitLike_1 {
    function mate(address usr) external;
    function file(bytes32 what, address data) external;
}

interface DssVestLike {
    function yank(uint256) external;
}

interface ProxyLike_1 {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface FlliperMomLike {
    function setOwner(address owner_) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/64b0d8425a316c40d1fc464c084d800e3b17c1f3/governance/votes/Executive%20vote%20-%20August%2030%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-08-30 MakerDAO Executive Spell | Hash: 0xd4f061429b564e422f18f0289a0f956f0229edbeead40b51ad69d52b27f7e591";

    GemAbstract internal immutable MKR                         = GemAbstract(DssExecLib.mkr());
    address internal immutable MCD_ESM                         = DssExecLib.esm();
    address internal immutable MCD_VOW                         = DssExecLib.vow();
    address internal immutable MCD_FLIPPER_MOM                 = DssExecLib.flipperMom();
    address internal immutable MIP21_LIQUIDATION_ORACLE        = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable MCD_VEST_DAI                    = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address internal immutable MCD_VEST_MKR_TREASURY           = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address internal immutable RWA015_A_INPUT_CONDUIT_URN_USDC = DssExecLib.getChangelogAddress("RWA015_A_INPUT_CONDUIT_URN");
    address internal immutable RWA015_A_INPUT_CONDUIT_JAR_USDC = DssExecLib.getChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR");

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    address internal constant RWA015_A_OPERATOR               = 0x23a10f09Fac6CCDbfb6d9f0215C795F9591D7476;
    address internal constant RWA015_A_CUSTODY                = 0x65729807485F6f7695AF863d97D62140B7d69d83;
    // BlockTower Input Conduits
    address internal constant RWA015_A_INPUT_CONDUIT_URN_GUSD = 0xAB80C37cB5b21238D975c2Cea46e0F12b3d84B06;
    address internal constant RWA015_A_INPUT_CONDUIT_JAR_GUSD = 0x13C31b41E671401c7BC2bbd44eF33B6E9eaa1E7F;
    address internal constant RWA015_A_INPUT_CONDUIT_URN_PAX  = 0x4f7f76f31CE6Bb20809aaCE30EfD75217Fbfc217;
    address internal constant RWA015_A_INPUT_CONDUIT_JAR_PAX  = 0x79Fc3810735959db3C6D4fc64F7F7b5Ce48d1CEc;

    // ---------- Launch Project Transfers ----------
    address internal constant LAUNCH_PROJECT_FUNDING          = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // Contracts pulled from Spark official deployment repository
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/5/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY                     = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL                     = 0xFBdB6C5596Fc958B432Bf1c99268C72B1515DFf0;

    function actions() public override {
        // ---------- Management of ConsolFreight (RWA003-A) Default ----------
        // Forum: https://forum.makerdao.com/t/consolfreight-rwa-003-cf4-drop-default/21745

        // Set DC to 0
        // Note: it was agreed with GovAlpha that there will be no global DC reduction this time.
        DssExecLib.setIlkDebtCeiling("RWA003-A", 0);
        // Call tell() on RWALiquidationOracle
        RwaLiquidationOracleLike_1(MIP21_LIQUIDATION_ORACLE).tell("RWA003-A");

        // ---------- Auth ESM on the Vow ----------
        // Forum: http://forum.makerdao.com/t/overlooked-vectors-for-post-shutdown-governance-attacks-postmortem/20696/5

        DssExecLib.authorize(MCD_VOW, MCD_ESM);

        // ---------- BlockTower Andromeda Input Conduit Chainlog Additions ----------
        // Forum: http://forum.makerdao.com/t/overlooked-vectors-for-post-shutdown-governance-attacks-postmortem/20696/5

        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_URN_GUSD
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_URN_GUSD).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_URN_GUSD
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_URN_GUSD).file("quitTo", RWA015_A_CUSTODY);
        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_JAR_GUSD
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_JAR_GUSD).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_JAR_GUSD
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_JAR_GUSD).file("quitTo", RWA015_A_CUSTODY);

        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_URN_PAX
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_URN_PAX).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_URN_PAX
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_URN_PAX).file("quitTo", RWA015_A_CUSTODY);
        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_JAR_PAX
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_JAR_PAX).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_JAR_PAX
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_JAR_PAX).file("quitTo", RWA015_A_CUSTODY);

        // Authorize ESM
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_URN_GUSD, MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_JAR_GUSD, MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_URN_PAX,  MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_JAR_PAX,  MCD_ESM);

        // Add RWA015 Conduits to the changelog
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_URN_GUSD", RWA015_A_INPUT_CONDUIT_URN_GUSD);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR_GUSD", RWA015_A_INPUT_CONDUIT_JAR_GUSD);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_URN_PAX",  RWA015_A_INPUT_CONDUIT_URN_PAX);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR_PAX",  RWA015_A_INPUT_CONDUIT_JAR_PAX);

        // Replace name for USDC Input Conduits in changelog
        ChainlogLike_2(DssExecLib.LOG).removeAddress("RWA015_A_INPUT_CONDUIT_URN");
        ChainlogLike_2(DssExecLib.LOG).removeAddress("RWA015_A_INPUT_CONDUIT_JAR");
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_URN_USDC",  RWA015_A_INPUT_CONDUIT_URN_USDC);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR_USDC",  RWA015_A_INPUT_CONDUIT_JAR_USDC);

        // ---------- Chainlog Cleanup ----------
        // Discussion: https://github.com/makerdao/spells-mainnet/issues/354

        // Deauth FlliperMom
        DssExecLib.setAuthority(MCD_FLIPPER_MOM, address(0));
        FlliperMomLike(MCD_FLIPPER_MOM).setOwner(address(0));

        ChainlogLike_2(DssExecLib.LOG).removeAddress("FLIPPER_MOM");
        ChainlogLike_2(DssExecLib.LOG).removeAddress("FLIP_FAB");

        // ---------- Yank GovAlpha Budget Streams ----------
        // Forum: https://forum.makerdao.com/t/spell-contents-2023-08-30/21730

        DssVestLike(MCD_VEST_DAI).yank(17);
        DssVestLike(MCD_VEST_MKR_TREASURY).yank(34);

        // ---------- Launch Project Dai Transfer ----------
        // Discussion: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/4

        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 941_993);

        // ---------- Launch Project MKR Transfer ----------
        // Discussion: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/4

        MKR.transfer(LAUNCH_PROJECT_FUNDING, 210.83 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Trigger Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/phoenix-labs-proposed-changes-for-spark-for-august-18th-spell/21612
        // Vote: https://vote.makerdao.com/polling/QmbMR8PU

        ProxyLike_1(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // Bump Changelog
        DssExecLib.setChangelogVersion("1.16.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}

