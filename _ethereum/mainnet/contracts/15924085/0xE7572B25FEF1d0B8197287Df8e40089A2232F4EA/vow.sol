// SPDX-License-Identifier: AGPL-3.0-or-later

/// vow.sol -- Dai settlement module

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
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

pragma solidity 0.5.15;

import "./lib.sol";

interface FlopLike {
    function kick(address gal, uint256 lot, uint256 bid) external returns (uint256);
    function cage() external;
    function live() external returns (uint256);
}

interface FlapLike {
    function kick(uint256 lot, uint256 bid) external returns (uint256);
    function cage(uint256) external;
    function live() external returns (uint256);
}

interface VatLike {
    function dai (address) external view returns (uint256);
    function sin (address) external view returns (uint256);
    function heal(uint256) external;
    function hope(address) external;
    function nope(address) external;
}

contract Vow is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { require(live == 1, "Vow/not-live"); wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Vow/not-authorized");
        _;
    }

    // --- Data ---
    VatLike public vat;        // CDP Engine
    FlapLike public flapper;   // Surplus Auction House
    FlopLike public flopper;   // Debt Auction House

    mapping (uint256 => uint256) public sin;  // debt queue
    uint256 public Sin;   // Queued debt            [rad]
    uint256 public Ash;   // On-auction debt        [rad]

    uint256 public wait;  // Flop delay             [seconds]
    uint256 public dump;  // Flop initial lot size  [wad]
    uint256 public sump;  // Flop fixed bid size    [rad]

    uint256 public bump;  // Flap fixed lot size    [rad]
    uint256 public hump;  // Surplus buffer         [rad]

    uint256 public live;  // Active Flag

    // --- Init ---
    constructor(address vat_, address flapper_, address flopper_) public {
        wards[msg.sender] = 1;
        vat     = VatLike(vat_);
        flapper = FlapLike(flapper_);
        flopper = FlopLike(flopper_);
        vat.hope(flapper_);
        live = 1;
    }

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Vow/add-overflow");
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Vow/sub-underflow");
    }
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external note auth {
        if (what == "wait") wait = data;
        else if (what == "bump") bump = data;
        else if (what == "sump") sump = data;
        else if (what == "dump") dump = data;
        else if (what == "hump") hump = data;
        else revert("Vow/file-unrecognized-param");
    }

    function file(bytes32 what, address data) external note auth {
        if (what == "flapper") {
            vat.nope(address(flapper));
            flapper = FlapLike(data);
            vat.hope(data);
        }
        else if (what == "flopper") flopper = FlopLike(data);
        else revert("Vow/file-unrecognized-param");
    }

    // Push to debt-queue
    function fess(uint256 tab) external note auth {
        sin[now] = add(sin[now], tab);
        Sin = add(Sin, tab);
    }
    // Pop from debt-queue
    function flog(uint256 era) external note {
        require(add(era, wait) <= now, "Vow/wait-not-finished");
        Sin = sub(Sin, sin[era]);
        sin[era] = 0;
    }

    // Debt settlement
    function heal(uint256 rad) external note {
        require(rad <= vat.dai(address(this)), "Vow/insufficient-surplus");
        require(rad <= sub(sub(vat.sin(address(this)), Sin), Ash), "Vow/insufficient-debt");
        vat.heal(rad);
    }
    function kiss(uint256 rad) external note {
        require(rad <= Ash, "Vow/not-enough-ash");
        require(rad <= vat.dai(address(this)), "Vow/insufficient-surplus");
        Ash = sub(Ash, rad);
        vat.heal(rad);
    }

    // Debt auction
    function flop() external note returns (uint256 id) {
        require(sump <= sub(sub(vat.sin(address(this)), Sin), Ash), "Vow/insufficient-debt");
        require(vat.dai(address(this)) == 0, "Vow/surplus-not-zero");
        Ash = add(Ash, sump);
        id = flopper.kick(address(this), dump, sump);
    }
    // Surplus auction
    function flap() external note returns (uint256 id) {
        require(vat.dai(address(this)) >= add(add(vat.sin(address(this)), bump), hump), "Vow/insufficient-surplus");
        require(sub(sub(vat.sin(address(this)), Sin), Ash) == 0, "Vow/debt-not-zero");
        id = flapper.kick(bump, 0);
    }

    function cage() external note auth {
        require(live == 1, "Vow/not-live");
        live = 0;
        Sin = 0;
        Ash = 0;
        flapper.cage(vat.dai(address(flapper)));
        flopper.cage();
        vat.heal(min(vat.dai(address(this)), vat.sin(address(this))));
    }
}
