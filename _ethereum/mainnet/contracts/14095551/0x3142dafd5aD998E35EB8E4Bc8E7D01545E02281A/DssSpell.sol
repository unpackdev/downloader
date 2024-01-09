// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.6.12 <0.7.0;
// pragma experimental ABIEncoderV2;

////// lib/dss-exec-lib/src/CollateralOpts.sol
/* pragma solidity ^0.6.12; */

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
/* pragma solidity ^0.6.12; */
/* // pragma experimental ABIEncoderV2; */

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
    function suck(address, address, uint) external;
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
    function join(address, uint) external;
    function exit(address, uint) external;
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
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogAddress(bytes32 _key, address _val) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {}
    function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {}
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

/* pragma solidity ^0.6.12; */

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
    function officeHours() public virtual returns (bool) {
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
    function description() external virtual view returns (string memory);

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external returns (uint256 castTime) {
        require(eta <= uint40(-1));
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
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

/* pragma solidity ^0.6.12; */

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
    // @param _expiration   The timestamp this spell will expire. (Ex. now + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) public {
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

////// src/DssSpellCollateralOnboarding.sol
//
// Copyright (C) 2021-2022 Dai Foundation
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

/* pragma solidity 0.6.12; */

/* import "./DssExecLib.sol"; */

contract DssSpellCollateralOnboardingAction {

    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmTRiQ3GqjCiRhh1ojzKzgScmSsiwQPLyjhgYSxZASQekj
    //

    // --- Math ---

    // --- DEPLOYED COLLATERAL ADDRESSES ---

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add ______________ as a new Vault Type
        //  Poll Link:

        // DssExecLib.addNewCollateral(
        //     CollateralOpts({
        //         ilk:                   ,
        //         gem:                   ,
        //         join:                  ,
        //         clip:                  ,
        //         calc:                  ,
        //         pip:                   ,
        //         isLiquidatable:        ,
        //         isOSM:                 ,
        //         whitelistOSM:          ,
        //         ilkDebtCeiling:        ,
        //         minVaultAmount:        ,
        //         maxLiquidationAmount:  ,
        //         liquidationPenalty:    ,
        //         ilkStabilityFee:       ,
        //         startingPriceFactor:   ,
        //         breakerTolerance:      ,
        //         auctionDuration:       ,
        //         permittedDrop:         ,
        //         liquidationRatio:      ,
        //         kprFlatReward:         ,
        //         kprPctReward:
        //     })
        // );

        // DssExecLib.setStairstepExponentialDecrease(
        //     CALC_ADDR,
        //     DURATION,
        //     PCT_BPS
        // );

        // DssExecLib.setIlkAutoLineParameters(
        //     ILK,
        //     AMOUNT,
        //     GAP,
        //     TTL
        // );

        // ChainLog Updates
        // Add the new flip and join to the Chainlog
        // address constant CHAINLOG        = DssExecLib.LOG();
        // ChainlogAbstract(CHAINLOG).setAddress("<join-name>", <join-address>);
        // ChainlogAbstract(CHAINLOG).setAddress("<clip-name>", <clip-address>);
        // ChainlogAbstract(CHAINLOG).setVersion("<new-version>");
    }
}

////// src/DssSpell.sol
//
// Copyright (C) 2021-2022 Dai Foundation
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

/* pragma solidity 0.6.12; */

/* import "./DssExec.sol"; */
/* import "./DssAction.sol"; */

/* import "./DssSpellCollateralOnboarding.sol"; */

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
    function yank(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/8d4ada25d79f0d7cee894fc9f80d579ae5545a48/governance/votes/Executive%20vote%20-%20January%2028%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-01-28 MakerDAO Executive Spell | Hash: 0x1284f085ea8cd00b52464a5191e1975b5e1b53fcfe3daa1434bd37348fbeaf9f";

    address public immutable MCD_VEST_DAI = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address public immutable MCD_VEST_MKR_TREASURY = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");


    address constant SNE_001_WALLET        = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;
    address constant TECH_001_WALLET       = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;
    address constant ORA_001_GAS           = 0x2B6180b413511ce6e3DA967Ec503b2Cc19B78Db6;
    address constant ORA_001_GAS_EMERGENCY = 0x1A5B692029b157df517b7d21a32c8490b8692b0f;
    address constant DUX_001_WALLET        = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
    address constant SES_001_WALLET        = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    address constant SF_001_WALLET         = 0xf737C76D2B358619f7ef696cf3F94548fEcec379;
    address constant RWF_001_WALLET        = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    address constant SF_001_VEST_01        = 0xBC7fd5AA2016C3e2C8F0dBf4e919485C6BBb59e2;
    address constant SF_001_VEST_02        = 0xCC81578d163A04ea8d2EaE6904d0C8E61A84E1Bb;


    uint256 constant APR_01_2021 = 1617235200;
    uint256 constant SEP_01_2021 = 1630454400;
    uint256 constant FEB_01_2022 = 1643673600;
    uint256 constant DEC_31_2022 = 1672444800;
    uint256 constant JAN_31_2023 = 1675123200;
    uint256 constant JUL_31_2023 = 1690761600;


    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // Revoking Content Production Budget (MKT-001)
        // https://mips.makerdao.com/mips/details/MIP40c3SP49
        DssVestLike(MCD_VEST_DAI).yank(20);


        //Core Unit DAI Budget Transfers
        // https://mips.makerdao.com/mips/details/MIP40c3SP47
        DssExecLib.sendPaymentFromSurplusBuffer(SNE_001_WALLET, 229_792);
        // https://mips.makerdao.com/mips/details/MIP40c3SP53
        DssExecLib.sendPaymentFromSurplusBuffer(TECH_001_WALLET, 1_069_250);
        // https://mips.makerdao.com/mips/details/MIP40c3SP45
        DssExecLib.sendPaymentFromSurplusBuffer(ORA_001_GAS, 6_966_070);
        // https://mips.makerdao.com/mips/details/MIP40c3SP45
        DssExecLib.sendPaymentFromSurplusBuffer(ORA_001_GAS_EMERGENCY, 1_805_407);


        // Core Unit DAI Budget Streams
        // https://mips.makerdao.com/mips/details/MIP40c3SP52
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(DUX_001_WALLET,   1_934_300 * WAD, FEB_01_2022, JAN_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP55
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(SES_001_WALLET,   5_844_444 * WAD, FEB_01_2022, JAN_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP47
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(SNE_001_WALLET,     257_500 * WAD, FEB_01_2022, JUL_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP53
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(TECH_001_WALLET,  2_486_400 * WAD, FEB_01_2022, JAN_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP46
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(SF_001_WALLET,      494_502 * WAD, FEB_01_2022, JUL_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://forum.makerdao.com/t/rwf-001-auditor-flow/12900
        DssVestLike(MCD_VEST_DAI).yank(15);
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(RWF_001_WALLET,   1_705_000 * WAD, FEB_01_2022, DEC_31_2022 - FEB_01_2022,            0, address(0))
        );


        // Core Unit MKR Vesting Streams (sourced from treasury)
        // https://mips.makerdao.com/mips/details/MIP40c3SP48
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create(
                SF_001_VEST_01,  // Participant
                240 * WAD,       // Amount
                SEP_01_2021,     // Begin date
                3 * 365 days,    // Vest duration
                365 days,        // Cliff time
                SF_001_WALLET    // Manager
            )
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP48
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create(
                SF_001_VEST_02,
                240 * WAD,
                APR_01_2021,
                3 * 365 days,
                365 days,
                SF_001_WALLET
            )
        );


        // Housekeeping
        // Add CLIP_FAB to the Chainlog
        DssExecLib.setChangelogAddress("CLIP_FAB", 0x0716F25fBaAae9b63803917b6125c10c313dF663);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}

