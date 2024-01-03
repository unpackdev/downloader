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


// This spell swaps the senior operator in the PC2 pool
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Mainnet Spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    // PC2 contracts
    address constant public ROOT = 0x23e11B3f2CD3d73f68a4A3AF436e2ED3459d0260;
    address constant public SENIOR_OPERATOR_OLD = 0x5BdCeF4d70D7Df939cb52be639F6a189423837eE;
    address constant public SENIOR_OPERATOR_NEW = 0xB1319831F7BC0cbc9813eA731A1bD5684a2f0ae3;
    address constant public SENIOR_TRANCHE = 0xF2C43699306DAB17Ec353886272BdFB4f443aD84;
   
    // permissions to be revoked
    address constant public SENIOR_OPERATOR_ADMIN_OLD = 0x790c2c860DDC993f3da92B19cB440cF8338C59a6;  

    // permissions to be set 
    address constant public SENIOR_OPERATOR_ADMIN1 = 0x6c98A86035D93ec71cc79372bFBC16f4D7c48ED6;                                             
    address constant public SENIOR_OPERATOR_ADMIN2 = 0x6ff40A231CA4E33DD8A5F7FDdA2a90A991052aB1;
    address constant public SENIOR_OPERATOR_ADMIN3 = 0x9B15cBAb38a0408E5DBaB9636145C862bFA5Ce53;

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        TinlakeRootLike root = TinlakeRootLike(address(ROOT));
      
        // Tranche: revoke permissions for old operator
        root.denyContract(SENIOR_TRANCHE, SENIOR_OPERATOR_OLD);

        // Tranche: give permissions for new operator
        root.relyContract(SENIOR_TRANCHE, SENIOR_OPERATOR_NEW);

        // new Senior Operator: revoke admin permissions
        root.denyContract(SENIOR_OPERATOR_NEW, SENIOR_OPERATOR_ADMIN_OLD);

        // new Senior Operator: give admin permissions
        root.relyContract(SENIOR_OPERATOR_NEW, SENIOR_OPERATOR_ADMIN1);
        root.relyContract(SENIOR_OPERATOR_NEW, SENIOR_OPERATOR_ADMIN2);
        root.relyContract(SENIOR_OPERATOR_NEW, SENIOR_OPERATOR_ADMIN3);
    }   
}
