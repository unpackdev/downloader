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
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        public view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function pauseProxy() public view returns (address) { return getChangelogAddress("MCD_PAUSE_PROXY"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogVersion(string memory _version) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function decreaseGlobalDebtCeiling(uint256 _amount) public {}
    function decreaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
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

interface DenyLike {
    function deny(address usr) external;
}

interface ChainlogLike_2 {
    function removeAddress(bytes32) external;
}

interface ProxyLike_1 {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/ef206389a490089bd06e64c574038f07bfbb7569/governance/votes/Executive%20vote%20-%20September%2013%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-09-13 MakerDAO Executive Spell | Hash: 0x214ab69eb9c381276e409b9c58c74a6e090f1105992fabc8986d88091121765f";

    GemAbstract internal immutable MKR         = GemAbstract(DssExecLib.mkr());

    address internal immutable MCD_VAT         = DssExecLib.vat();
    address internal immutable MCD_CAT         = DssExecLib.cat();
    address internal immutable MCD_PAUSE_PROXY = DssExecLib.pauseProxy();

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }
    // ----- Approve HV Bank (RWA009-A) DAO Resolution -----
    // Forum: http://forum.makerdao.com/t/request-to-poll-offboarding-legacy-legal-recourse-assets/21582
    // Poll: https://vote.makerdao.com/polling/QmNgKzcG
    // Approve DAO resolution hash QmXU2TwsRpVevGY74NVFbD9bKwtsw1mSuSce7My1zinD9m

    // Comma-separated list of DAO resolutions IPFS hashes.
    string public constant dao_resolutions = "QmXU2TwsRpVevGY74NVFbD9bKwtsw1mSuSce7My1zinD9m";

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

    uint256 internal constant THREE_PT_FOUR_FIVE_PCT_RATE  = 1000000001075539644270067964;
    uint256 internal constant THREE_PT_SEVEN_ZERO_PCT_RATE = 1000000001152077919467240095;
    uint256 internal constant FOUR_PT_TWO_ZERO_PCT_RATE    = 1000000001304602465690389263;

    // ----------- MKR transfer Addresses -----------
    address internal constant DECO_WALLET = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address internal constant SES_WALLET  = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    address internal constant DEFENSOR    = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant TRUENAME    = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant BONAPUBLICA = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant VIGILANT    = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant NAVIGATOR   = 0x11406a9CC2e37425F15f920F494A51133ac93072;
    address internal constant QGOV        = 0xB0524D8707F76c681901b782372EbeD2d4bA28a6;
    address internal constant UPMAKER     = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant PALC        = 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A;
    address internal constant PBG         = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant CLOAKY      = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant WBC         = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant BLUE        = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;

    //  ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;

    // ---------- Spark Proxy ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL = 0x95bcf659653d2E0b44851232d61F6F9d2e933fB1;

    function actions() public override {
        // ---------- Stability Scope Parameter Changes ----------
        // MIP: https://mips.makerdao.com/mips/details/MIP104#0-the-stability-scope
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-5/21969
        // Increase the ETH-A Stability Fee (SF) by 0.12% from 3.58% to 3.70%.
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_PT_SEVEN_ZERO_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-B Stability Fee (SF) by 0.12% from 4.08% to 4.20%.
        DssExecLib.setIlkStabilityFee("ETH-B", FOUR_PT_TWO_ZERO_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-C Stability Fee (SF) by 0.12% from 3.33% to 3.45%.
        DssExecLib.setIlkStabilityFee("ETH-C", THREE_PT_FOUR_FIVE_PCT_RATE, /* doDrip = */ true);

        // Activate DC-IAM for PSM-PAX-A
        // Maximum Debt Ceiling (line): 120M
        // Target Available Debt (gap): 50 million DAI
        // Ceiling Increase Cooldown (ttl): 24 hours
        DssExecLib.setIlkAutoLineParameters("PSM-PAX-A", /* line */ 120 * MILLION, /* gap */ 50 * MILLION, /* ttl */ 24 hours);

        // ---------- Spark Protocol DC-IAM changes ----------
        // Forum: http://forum.makerdao.com/t/upcoming-spell-proposed-changes/21801
        // Poll: https://vote.makerdao.com/polling/QmQnUhZt#vote-breakdown
        // Increase the Maximum Debt Ceiling from 200 million DAI to 400 million DAI.
        // and
        // Increase the Ceiling Increase Cooldown from 8 hours to 12 hours.
        DssExecLib.setIlkAutoLineParameters("DIRECT-SPARK-DAI", /* line */ 400 * MILLION, /* gap */ 20 * MILLION, /* ttl */ 12 hours);

        // ---------- Aligned Delegate Compensation for August ----------
        // Forum: https://forum.makerdao.com/t/august-2023-aligned-delegate-compensation/21983

        // 0xDefensor - 41.67 - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // TRUE NAME - 41.67 - 0x612f7924c367575a0edf21333d96b15f1b345a5d
        MKR.transfer(TRUENAME, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // BONAPUBLICA - 41.67 - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // vigilant - 41.67 - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // Navigator - 28.23 - 0x11406a9CC2e37425F15f920F494A51133ac93072
        MKR.transfer(NAVIGATOR, 28.23 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // QGov - 20.16 - 0xB0524D8707F76c681901b782372EbeD2d4bA28a6
        MKR.transfer(QGOV, 20.16 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // UPMaker - 13.89 - 0xbb819df169670dc71a16f58f55956fe642cc6bcd
        MKR.transfer(UPMAKER, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // PALC - 13.89 - 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A
        MKR.transfer(PALC, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // PBG - 13.89 - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // Cloaky - 7.17 - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 7.17 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // WBC - 6.72 - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC, 6.72 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // BLUE - 1.25 - 0xb6c09680d822f162449cdfb8248a7d3fc26ec9bf
        MKR.transfer(BLUE, 1.25 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- Decrease Debt Ceiling for Fortunafi (RWA005-A) to 0 ----------
        // Decrease Debt Ceiling from 15 million DAI to 0 (zero)
        // Forum: http://forum.makerdao.com/t/request-to-poll-offboarding-legacy-legal-recourse-assets/21582
        // Poll: https://vote.makerdao.com/polling/Qmcb1c9x

        DssExecLib.decreaseIlkDebtCeiling("RWA005-A", 15 * MILLION, /* global = */ true);

        // ---------- Trigger Spark Proxy Spell ----------
        // Poll: https://vote.makerdao.com/polling/QmQrkxud
        // Poll 2: https://vote.makerdao.com/polling/QmbCDKof
        ProxyLike_1(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));


        // ---------- Core Unit MKR Vesting Transfers ----------
        // DECO-001 - 125 MKR - 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP36#sentence-summary
        MKR.transfer(DECO_WALLET, 125 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // SES-001 - 34.94 MKR - 0x87acdd9208f73bfc9207e1f6f0fde906bca95cc6
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP17#sentence-summary
        MKR.transfer(SES_WALLET, 34.94 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- Scuttle MCD_CAT ----------
        // Forum: http://forum.makerdao.com/t/proposal-to-scuttle-mcd-cat-upcoming-executive-spell-2023-09-13/21958

        // Remove MCD_CAT from the Chainlog
        ChainlogLike_2(DssExecLib.LOG).removeAddress("MCD_CAT");

        // Revoke MCD_CAT access to MCD_VAT: vat.deny(cat)
        DenyLike(MCD_VAT).deny(MCD_CAT);

        // Yield ownership of MCD_CAT: cat.deny(pauseProxy)
        DenyLike(MCD_CAT).deny(MCD_PAUSE_PROXY);

        // Bump chainlog version
        // Justification: The MINOR version is updated as core MCD_CAT contract is being removed in this spell
        DssExecLib.setChangelogVersion("1.17.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}

