// SPDX-License-Identifier: GPL-3.0-or-later
// hevm: flattened sources of src/DssSpell.sol
pragma solidity =0.6.11 >=0.5.12;

////// lib/dss-interfaces/src/dapp/DSPauseAbstract.sol

/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
    function setDelay(uint256) external;
    function plans(bytes32) external view returns (bool);
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function drop(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

////// lib/dss-interfaces/src/dss/ChainlogAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-chain-log
interface ChainlogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function keys() external view returns (bytes32[] memory);
    function version() external view returns (string memory);
    function ipfs() external view returns (string memory);
    function setVersion(string calldata) external;
    function setSha256sum(string calldata) external;
    function setIPFS(string calldata) external;
    function setAddress(bytes32,address) external;
    function removeAddress(bytes32) external;
    function count() external view returns (uint256);
    function get(uint256) external view returns (bytes32,address);
    function list() external view returns (bytes32[] memory);
    function getAddress(bytes32) external view returns (address);
}

// Helper function for returning address or abstract of Chainlog
//  Valid on Mainnet, Kovan, Rinkeby, Ropsten, and Goerli
contract ChainlogHelper {
    address          public constant ADDRESS  = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    ChainlogAbstract public constant ABSTRACT = ChainlogAbstract(ADDRESS);
}

////// lib/dss-interfaces/src/dss/VatAbstract.sol
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

/* import "./DSPauseAbstract.sol"; */
/* import "./ChainlogAbstract.sol"; */
/* import "./VatAbstract.sol"; */

contract SpellAction {
    // Office hours enabled if true
    bool constant public officeHours = false;

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    modifier limited {
        if (officeHours) {
            uint day = (block.timestamp / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = block.timestamp / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    function execute() external limited {
        // Proving the Pause Proxy has access to the MCD core system at the execution time
        address MCD_VAT = CHANGELOG.getAddress("MCD_VAT");
        require(VatAbstract(MCD_VAT).wards(address(this)) == 1, "no-access");
    }
}

contract DssSpell {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    DSPauseAbstract immutable public pause;
    address         immutable public action;
    bytes32         immutable public tag;
    uint256         immutable public expiration;
    uint256         public eta;
    bytes           public sig;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/3e18ba4514db068a96ea277e006028831dbd5ed7/governance/votes/Executive%20vote%20-%20January%2025%2C%202021.md -q -O - 2>/dev/null)"
    string constant public description =
        "2021-01-25 MakerDAO Executive Spell | Hash: 0x6d023ee5874db51d0cdb0491d5ae3095c89a578133c44769c836efcb06f02eb0";

    // MIP29: Peg Stability Module
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/4fc8d21ce2122c637f3302c63d2892b572cb5c94/MIP29/mip29.md -q -O - 2>/dev/null)"
    string constant public MIP29 = "0xfcca2f3e493a998bf7e5532cda126d106173d2ab41d6965baa08e66a2c6cd96a";

    // MIP30: Farmable cUSDC Adaptor (CropJoin)
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/4fc8d21ce2122c637f3302c63d2892b572cb5c94/MIP30/mip30.md -q -O - 2>/dev/null)"
    string constant public MIP30 = "0xbdd7787c5d43e146c9ffa021ed59f9dbc01867c16216ff4a3c4341a530c18172";

    // MIP13c3-SP7: Declaration of Intent - Governance Communications Domain
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/4942ee3a65f4205303146388d5af48f69f5e6898/MIP13/MIP13c3-Subproposals/MIP13c3-SP7.md -q -O - 2>/dev/null)"
    string constant public MIP13c3SP7 = "0x821e0bb3299445e27a12fa29ce5820e5cc0b633650f7d7064aeb0de6307a807e";

    // MIP7c3-SP5: Onboarding Sébastien Derivaux to the Risk Domain
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/4942ee3a65f4205303146388d5af48f69f5e6898/MIP7/MIP7c3-Subproposals/MIP7c3-SP5.md -q -O - 2>/dev/null)"
    string constant public MIP7c3SP5 = "0x8dd22faf4a65225699ab45df003a363e39636954ca5f07b7300a03e68ae96d07";

    // MIP7c3-SP5: Onboarding Sam MacPherson to the Smart Contracts Domain
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/4fc8d21ce2122c637f3302c63d2892b572cb5c94/MIP7/MIP7c3-Subproposals/MIP7c3-SP6.md -q -O - 2>/dev/null)"
    string constant public MIP7c3SP6 = "0x20f8c70ec4f91fa36acb3708aaf018f9bcd42529802fefbe3633d5f80a3085d8";

    // MIP28c7-SP2: Onboarding @JuanJuan to the Operational Support Domain
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c0f090df4d1ca28daefbb030725e7f8c115ea516/MIP28/MIP28c7-Subproposals/MIP28c7-SP2.md -q -O - 2>/dev/null)"
    string constant public MIP28c7SP2 = "0x37d7005b0bf865b171bec39a7e1648f7cea3171124d615fb59e77ac455586850";

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    constructor() public {
        pause = DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;
        address _action = action = address(new SpellAction());
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = block.timestamp + 4 days + 2 hours;
    }

    function nextCastTime() external view returns (uint256 castTime) {
        require(eta != 0, "DSSSpell/spell-not-scheduled");
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

    function schedule() external {
        require(block.timestamp <= expiration, "DSSSpell/spell-has-expired");
        require(eta == 0, "DSSSpell/spell-already-scheduled");
        eta = block.timestamp + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() external {
        require(!done, "DSSSpell/spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}