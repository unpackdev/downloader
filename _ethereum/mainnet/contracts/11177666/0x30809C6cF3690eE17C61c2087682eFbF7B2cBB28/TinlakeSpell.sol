// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol
pragma solidity >=0.5.15 <0.6.0;

////// src/spell.sol
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
/* pragma solidity >=0.5.15 <0.6.0; */

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface CoordinatorLike {
    function file(bytes32 name, uint value) external;
    function minimumEpochTime() external returns(uint);
}

interface NAVFeedLike {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function discountRate() external returns(uint);
}

// This spell makes changes to the tinlake mainnet CF4 deployment:
// modify discount rate in nav feed to 10.35%
// adds new risk groups to nav feed 12-23
// sets min epoch length to 24hrs
// revokes permissions from old admin address on assessor 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8
// revokes permissions from old admin address on coordinator 0x97b2d32FE673af5bb322409afb6253DFD02C0567
// gives permissions to admin wrapper contract on assessor 0x533Ea66C62fad098599dE145970a8d49D6B5f9C4
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Mainnet Spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address constant public ROOT = 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6;
    address constant public ASSESSOR = 0x6aaf2EE5b2B62fb9E29E021a1bF3B381454d900a;
    address constant public COORDINATOR = 0xFc224d40Eb9c40c85c71efa773Ce24f8C95aAbAb;
    address constant public NAV_FEED = 0x69504da6B2Cd8320B9a62F3AeD410a298d3E7Ac6;
    
    // permissions to be set
    address constant public ASSESSOR_ADMIN_WRAPPER = 0x533Ea66C62fad098599dE145970a8d49D6B5f9C4;  

    // permissions to be revoked                                           
    address constant public ASSESSOR_ADMIN_TO_BE_REMOVED = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address constant public COORDINATOR_ADMIN_TO_BE_REMOVED = 0x97b2d32FE673af5bb322409afb6253DFD02C0567;

    // new minEpochTime
    uint constant public minEpochTime = 1 days;
    // new discountRate1     
    uint constant public discountRate = uint(1000000003281963470319634703);

    uint256 constant ONE = 10**27;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(address(ROOT));
       CoordinatorLike coordinator = CoordinatorLike(address(COORDINATOR));
       NAVFeedLike navFeed = NAVFeedLike(address(NAV_FEED));
   
        // add permissions  
        // Assessor
        root.relyContract(ASSESSOR, ASSESSOR_ADMIN_WRAPPER);
        // Coordinator
        root.relyContract(COORDINATOR, address(this)); // required to modify min epoch time
        // NavFeed 
        root.relyContract(NAV_FEED, address(this)); // required to file riskGroups & change discountRate

        // revoke permissions
        // Assessor
        root.denyContract(ASSESSOR, ASSESSOR_ADMIN_TO_BE_REMOVED);
        // Coordinator
        root.denyContract(COORDINATOR, COORDINATOR_ADMIN_TO_BE_REMOVED);

        // set minEpochTime to 24 hrs
        coordinator.file("minimumEpochTime", minEpochTime);

        // change discountRate
        navFeed.file("discountRate", discountRate);
        
        //file risk groups
        //risk group: 12 - ADF2, APR: 11%
        navFeed.file("riskGroup", 12, ONE, ONE, uint(1000000003488077118214104515), 99.93 * 10**25);
        // risk group: 13 - BDF2, APR: 11.5%
        navFeed.file("riskGroup", 13, ONE, 95 * 10**25, uint(1000000003646626078132927447), 99.9 * 10**25);
        // risk group: 14 - CDF2, APR: 11.5%
        navFeed.file("riskGroup", 14, ONE, 90*  10**25, uint(1000000003646626078132927447), 99.88 * 10**25);
        // risk group: 15 - DDF2, APR: 12%
        navFeed.file("riskGroup", 15, ONE, 80 * 10**25, uint(1000000003805175038051750380), 99.86 * 10**25);
        // risk group: 16 - ARF2, APR: 11%
        navFeed.file("riskGroup", 16, ONE, ONE, uint(1000000003488077118214104515), 99.92 * 10**25);
        // risk group: 17 - BRF2, APR: 11.5%
        navFeed.file("riskGroup", 17, ONE, ONE, uint(1000000003646626078132927447), 99.9 * 10**25);
        // risk group: 18 - CRF2, APR: 11.5%
        navFeed.file("riskGroup", 18, ONE, ONE, uint(1000000003646626078132927447), 99.88 * 10**25);
        // risk group: 19 - DRF2, APR: 12%
        navFeed.file("riskGroup", 19, ONE, ONE, uint(1000000003805175038051750380), 99.87 * 10**25);
        // risk group: 20 - ATF2, APR: 11%
        navFeed.file("riskGroup", 20, ONE, 80 * 10**25, uint(1000000003488077118214104515), 99.92 * 10**25);
        // risk group: 21 - BTF2, APR: 11.5%
        navFeed.file("riskGroup", 21, ONE, 70 * 10**25, uint(1000000003646626078132927447), 99.9 * 10**25);
        // risk group: 22 - CTF2, APR: 11.5%
        navFeed.file("riskGroup", 22, ONE, 60 * 10**25, uint(1000000003646626078132927447), 99.89 * 10**25);
        // risk group: 23 - DTF2, APR: 12%
        navFeed.file("riskGroup", 23, ONE, 50 * 10**25, uint(1000000003805175038051750380), 99.88 * 10**25);
     }   
}
