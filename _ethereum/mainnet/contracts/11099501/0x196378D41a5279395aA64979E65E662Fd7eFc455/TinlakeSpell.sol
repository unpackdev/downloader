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
}


// This spell adds two wards to the CF4 DROP token memberlist
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Mainnet Spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    // REVPOOL 1 root contracts
    address constant public ROOT = 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6;
    address constant public SENIOR_MEMBERLIST = 0x26129802A858F3C28553f793E1008b8338e6aEd2;
   
    // permissions to be set
    address constant public SENIOR_MEMBERLIST_ADMIN1 = 0x97b2d32FE673af5bb322409afb6253DFD02C0567;                                             
    address constant public SENIOR_MEMBERLIST_ADMIN2 = 0x6f5B7AF64fbb449020A74713E77262792165f0B6;

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(address(ROOT));
      
       // add permissions for SeniorToken MemberList  
       root.relyContract(SENIOR_MEMBERLIST, SENIOR_MEMBERLIST_ADMIN1);
       root.relyContract(SENIOR_MEMBERLIST, SENIOR_MEMBERLIST_ADMIN2);
    }   
}
