// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.6.7;



interface PauseLike {
    function delay() external returns (uint);
    function exec(address, bytes32, bytes calldata, uint256) external;
    function plot(address, bytes32, bytes calldata, uint256) external;
}


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

interface FlipLike {
    function rely(address usr) external;
}


interface CatLike {
    function ilks(bytes32) external view returns (
        address flip, // Liquidator
        uint256 chop,  // Liquidation Penalty  [wad]
        uint256 dunk  // Liquidation Quantity [rad]
    );

    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
}



contract SpellActionCommon {

    uint256 constant ZERO_PERCENT_RATE            = 1000000000000000000000000000;
    uint256 constant ONE_PERCENT_RATE             = 1000000000315522921573372069;
    uint256 constant TWO_PERCENT_RATE             = 1000000000627937192491029810;
    uint256 constant TWO_POINT_FIVE_PERCENT_RATE  = 1000000000782997609082909351;
    uint256 constant THREE_PERCENT_RATE           = 1000000000937303470807876289;
    uint256 constant FOUR_POINT_FIVE_PERCENT_RATE = 1000000001395766281313196627;
    uint256 constant FIVE_PERCENT_RATE            = 1000000001547125957863212448;
    uint256 constant SIX_PERCENT_RATE             = 1000000001847694957439350562;
    uint256 constant EIGHT_PERCENT_RATE           = 1000000002440418608258400030;
    uint256 constant NINE_PERCENT_RATE            = 1000000002732676825177582095;
    uint256 constant TEN_PERCENT_RATE             = 1000000003022265980097387650;

    uint256 constant TWO_THOUSAND_RAD          = 2000000000000000000000000000000000000000000000000;
    uint256 constant ONE_MIL_RAD               = 1000000000000000000000000000000000000000000000000000;

    uint256 constant THREE_HUNDRED             = 300000000000000000000000000000000000000000000000;
                                                    

    function setupFlip(bytes32 ilk, address cat) internal {
        (address flip,,) = CatLike(cat).ilks(ilk);
        FlipLike(flip).rely(cat);
        CatLike(cat).file(ilk, "dunk", ONE_MIL_RAD);
    }

    function executeCommon(address changeLogAddr) internal {

        address MCD_CAT = ChainlogAbstract(changeLogAddr).getAddress("MCD_CAT");

        setupFlip("USDTUSDC-A", MCD_CAT);
        setupFlip("USDTDAI-A", MCD_CAT);
        setupFlip("USDTUSDN-A", MCD_CAT);

        setupFlip("USDCDAI-A", MCD_CAT);
        setupFlip("CRV_3POOL-A", MCD_CAT);
        setupFlip("CRV_3POOL-B", MCD_CAT);

        CatLike(MCD_CAT).file("box", ONE_MIL_RAD);


        ChainlogAbstract(changeLogAddr).setVersion("1.6.0");
    }
}

contract SpellActionMainnet is SpellActionCommon {
    function execute() external {
        executeCommon(0xE0fb0a1B0F1db37D803bad3F6d55158291Bb7bAc);
    }
}



contract SpellActionKovan is SpellActionCommon {
    function execute() external {
        executeCommon(0x873396d69b017e3Ed499406892E1cd2f3EE1CFA7);
    }
}



contract ActionSpell {
    bool      public done;
    address   public pause;
    uint256   public expiration;


    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;


    function setup(address deployer) internal {
        expiration = block.timestamp + 30 days;
        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag; assembly { _tag := extcodehash(deployer) }
        action = deployer;
        tag = _tag;
    }

    function schedule() external {
        require(block.timestamp <= expiration, "DSSSpell/spell-has-expired");
        require(eta == 0, "spell-already-scheduled");
        eta = now + PauseLike(pause).delay();
        PauseLike(pause).plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        PauseLike(pause).exec(action, tag, sig, eta);
    }
}


contract ActionSpellMainnet is ActionSpell {
    constructor() public {
        pause = 0x146921eF7A94C50b96cb53Eb9C2CA4EB25D4Bfa8;
        setup(address(new SpellActionMainnet()));
    }
}


contract ActionSpellKovan is ActionSpell {
    constructor() public {
        pause = 0x95D6fBdD8bE0FfBEB62b3B3eB2A7dFD19cFae8F5;
        setup(address(new SpellActionKovan()));
    }
}