// Copyright (C) 2020 Centrifuge
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
pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface SpellReserveLike {
    function payout(uint currencyAmount) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MigrationLike {
    function migrate(address) external;
}

interface TrancheLike {
    function totalSupply() external returns(uint);
    function totalRedeem() external returns(uint);
}

interface PoolAdminLike {
    function relyAdmin(address) external;
}

interface MgrLike {
    function lock(uint) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: ns2 migration to rev pool with maker support
// - migrate state & swap contracts: assessor, reserve, coordinator
// - add & wire mkr adapter contracts: clerk & mgr, spotter, vat
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake NS2 migration mainnet Spell";

    address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public SHELF = 0x7d057A056939bb96D682336683C10EC89b78D7CE;
    address constant public COLLECTOR = 0x62f290512c690a817f47D2a4a544A5d48D1408BE;
    address constant public SENIOR_TOKEN = 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0;
    address constant public SENIOR_MEMBERLIST = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
    address constant public SENIOR_OPERATOR = 0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C;
    address constant public JUNIOR_TRANCHE = 0x7cD2a6Be6ca8fEB02aeAF08b7F350d7248dA7707;
    address constant public JUNIOR_MEMBERLIST = 0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD;
    address constant public POOL_ADMIN = 0x6A82DdF0DF710fACD0414B37606dC9Db05a4F752;
    address constant public NAV = 0x41fAD1Eb242De19dA0206B0468763333BB6C2B3D;
    address constant public SENIOR_TRANCHE_OLD = 0xfB30B47c47E2fAB74ca5b0c1561C2909b280c4E5;
    address constant public ASSESSOR_OLD = 0xdA0bA5Dd06C8BaeC53Fa8ae25Ad4f19088D6375b;
    address constant public COORDINATOR_OLD = 0xFE860d06fF2a3A485922A6a029DFc1CD8A335288;
    address constant public RESERVE_OLD = 0x30FDE788c346aBDdb564110293B20A13cF1464B6;

    address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI

    // new contracts -> to be migrated
    address constant public COORDINATOR_NEW = 0xcC7AFB5DeED34CF67E72d4C53B142F44c9268ab9;
    address constant public ASSESSOR_NEW  = 0x83E2369A33104120746B589Cc90180ed776fFb91;
    address constant public RESERVE_NEW = 0xD9E4391cF31638a8Da718Ff0Bf69249Cdc48fB2B;
    address constant public SENIOR_TRANCHE_NEW = 0x636214f455480D19F17FE1aa45B9989C86041767;

    // adapter contracts -> to be integrated
    address constant public CLERK = 0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd;
    address constant public MGR =  0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
    // https://changelog.makerdao.com/releases/mainnet/1.3.0/index.html
    address constant public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    // rwa contracts
    address constant public URN = 0x225B3da5BE762Ee52B182157E67BeA0b31968163;
    address constant public LIQ = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;
    address constant public END = 0xBB856d1742fD182a90239D7AE85706C2FE4e5922;
    address constant public RWA_GEM = 0xAAA760c2027817169D7C8DB0DC61A2fb4c19AC23;

    // Todo: add correct addresses
    address constant public ADMIN1 = address(0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8);
    address constant public ADMIN2 = address(0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9);

    uint constant public ASSESSOR_MIN_SENIOR_RATIO = 0;
    uint constant public MAT_BUFFER = 0.01 * 10**27;
    address self;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);
        self = address(this);
        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(SHELF, self);
        root.relyContract(COLLECTOR, self);
        root.relyContract(JUNIOR_TRANCHE, self);
        root.relyContract(SENIOR_OPERATOR, self);
        root.relyContract(SENIOR_TRANCHE_OLD, self);
        root.relyContract(SENIOR_TOKEN, self);
        root.relyContract(SENIOR_TRANCHE_NEW, self);
        root.relyContract(SENIOR_MEMBERLIST, self);
        root.relyContract(JUNIOR_MEMBERLIST, self);
        root.relyContract(CLERK, self);
        root.relyContract(POOL_ADMIN, self);
        root.relyContract(ASSESSOR_NEW, self);
        root.relyContract(COORDINATOR_NEW, self);
        root.relyContract(RESERVE_OLD, self);
        root.relyContract(RESERVE_NEW, self);
        root.relyContract(MGR, self);

        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateAssessor();
        migrateCoordinator();
        migrateReserve();
        migrateTranche();
        integrateAdapter();
        setupPoolAdmin();

        // for mkr integration: set minSeniorRatio in Assessor to 0
        FileLike(ASSESSOR_NEW).file("minSeniorRatio", ASSESSOR_MIN_SENIOR_RATIO);
    }

    function migrateAssessor() internal {
        MigrationLike(ASSESSOR_NEW).migrate(ASSESSOR_OLD);
        // migrate dependencies
        DependLike(ASSESSOR_NEW).depend("navFeed", NAV);
        DependLike(ASSESSOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(ASSESSOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(ASSESSOR_NEW).depend("reserve", RESERVE_NEW);
        DependLike(ASSESSOR_NEW).depend("clerk", CLERK);
        // migrate permissions
        AuthLike(ASSESSOR_NEW).rely(COORDINATOR_NEW);
        AuthLike(ASSESSOR_NEW).rely(RESERVE_NEW);
    }

    function migrateCoordinator() internal {
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR_OLD);
         // migrate dependencies
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE_NEW);

        DependLike(JUNIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);

        // migrate permissions
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW);
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD);
        AuthLike(SENIOR_TRANCHE_NEW).rely(COORDINATOR_NEW);
    }

    function migrateReserve() internal {
        MigrationLike(RESERVE_NEW).migrate(RESERVE_OLD);
        // migrate dependencies
        DependLike(RESERVE_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(RESERVE_NEW).depend("currency", TINLAKE_CURRENCY);
        DependLike(RESERVE_NEW).depend("shelf", SHELF);
        DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(RESERVE_NEW).depend("pot", RESERVE_NEW);

        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(SHELF).depend("lender", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE).depend("reserve", RESERVE_NEW);
        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE_NEW);
        AuthLike(RESERVE_NEW).rely(ASSESSOR_NEW);

        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE_OLD);
        SpellReserveLike(RESERVE_OLD).payout(balanceReserve);
        currency.transferFrom(self, RESERVE_NEW, balanceReserve);
    }

    function migrateTranche() internal {
        TrancheLike tranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((tranche.totalSupply() == 0 && tranche.totalRedeem() == 0), "tranche-has-orders");
        DependLike(SENIOR_TRANCHE_NEW).depend("reserve", RESERVE_NEW);
        DependLike(SENIOR_TRANCHE_NEW).depend("epochTicker", COORDINATOR_NEW);
        DependLike(SENIOR_OPERATOR).depend("tranche", SENIOR_TRANCHE_NEW);

        AuthLike(SENIOR_TOKEN).deny(SENIOR_TRANCHE_OLD);
        AuthLike(SENIOR_TOKEN).rely(SENIOR_TRANCHE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(SENIOR_OPERATOR);
    }

    function integrateAdapter() internal {
        require(SpellERC20Like(RWA_GEM).balanceOf(MGR) == 1 ether);
        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR_NEW);
        DependLike(CLERK).depend("mgr", MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW);
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE_NEW);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat", VAT);
        DependLike(CLERK).depend("jug", JUG);

        FileLike(CLERK).file("buffer", MAT_BUFFER);

        // permissions
        AuthLike(CLERK).rely(COORDINATOR_NEW);
        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(CLERK);
        AuthLike(RESERVE_NEW).rely(CLERK);
        AuthLike(ASSESSOR_NEW).rely(CLERK);

        // currency
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, uint(-1));
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(MGR, uint(-1));

        // setup mgr
        AuthLike(MGR).rely(CLERK);
        FileLike(MGR).file("urn", URN);
        FileLike(MGR).file("liq", LIQ);
        FileLike(MGR).file("end", END);
        FileLike(MGR).file("owner", CLERK);
        FileLike(MGR).file("pool", SENIOR_OPERATOR);
        FileLike(MGR).file("tranche", SENIOR_TRANCHE_NEW);

        // lock token
        MgrLike(MGR).lock(1 ether);
    }

    function setupPoolAdmin() public {
        PoolAdminLike poolAdmin = PoolAdminLike(POOL_ADMIN);
        AuthLike(POOL_ADMIN).rely(ADMIN1);

        // setup dependencies
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR_NEW);
        DependLike(POOL_ADMIN).depend("lending", CLERK);
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);

        // setup permissions
        AuthLike(ASSESSOR_NEW).rely(POOL_ADMIN);
        AuthLike(CLERK).rely(POOL_ADMIN);
        AuthLike(JUNIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).rely(POOL_ADMIN);

        //setup admins
        poolAdmin.relyAdmin(ADMIN1);
        poolAdmin.relyAdmin(ADMIN2);
    }

}