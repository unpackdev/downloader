
pragma solidity >=0.5.0 <0.7.0;

import "./PlonkSingleCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkSingleVerifier is SingleVerifierWithDeserialize {

    function isBlockSizeSupportedInternal(uint32 _size) internal pure returns (bool) {
        if (_size == uint32(6)) { return true; }
        else if (_size == uint32(12)) { return true; }
        else if (_size == uint32(48)) { return true; }
        else if (_size == uint32(96)) { return true; }
        else if (_size == uint32(204)) { return true; }
        else if (_size == uint32(420)) { return true; }
        else { return false; }
    }

    
    function getVkExit() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 262144;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0f60c8fe0414cb9379b2d39267945f6bd60d06a05216231b26a9fcf88ddbfebe);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x1abc710835cdc78389d61b670b0e8d26416a63c9bd3d6ed435103ebbb8a8665e,
            0x138c6678230ed19f90b947d0a9027bd9fc458bbd1d2b8371fa72e28470a97b9c
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x28d81ac76e1ddf630b4bf8e4a789cf9c4470c5e5cc010a24849b20ab595b8b22,
            0x251ca3cf0829b261d3be8d6cbd25aa97d9af716819c29f6319d806f075e79655
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x1504c8c227833a1152f3312d258412c334ac7ae213e21427ff63028729bc28fa,
            0x0f0942f3fede795cbe624fb9ddf9be90ba546609383f2246c3c9b92af7aab5fd
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x1f14a5bb19ea2897ac6b9fbdbd2b4e371be09f8e90a47ae26602d399c9bcd311,
            0x029c6ea094247da75d9a66cea627c3c77d48b898003125d4f8e785435dc2cf23
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x102cdd83e2d70638a70d700622b662607f8a2d92f5c36053a4ddb4b600d75bcf,
            0x09ef3679579d761507ef69eaf49c978b271f0e4500468da1ebd7197f3ff5d6ac
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x2c2bd1d2fa3d4b3915d0fe465469e11ee563e79751da71c6082fcd0ca4e41cd5,
            0x0304f16147a8af177dcc703370931d5161bda9dcf3e091787b9a54377ab54c32
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x14420680f992f4bc8d8012e2d8b14a774cf9114adf1e41b3c02c20cc1648398e,
            0x237d3d5cdee5e3d7d58f4eb336ecd7aa5ec88d89205861b410420f6b9f6b26a1
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x221045ae5578ccb35e0a198d83c0fb191da8cdc98423fc46e580f1762682c73e,
            0x15b7f3d74fcd258fdd2ae6001693a7c615e654d613a506d213aaf0ad314e338d
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x03e47981b459b3be258a6353593898babec571ccf3e0362d53a67f078f04830a,
            0x0809556ab6eb28403bb5a749fcdbd8656940add7685ff5473dc3a9ad940034df
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x2c02322c53d7e6a6474b15c7db738419e3f4d1263e9f98ebb56c24906f555ef9,
            0x2322c69f51366551665b584d797e0fdadb16fe31b1e7ae2f532847a75b3aeaab
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x2147e39b49c2bef4168884c0ac9e38bb4dc65b41ba21953f7ded2daab7fe1534,
            0x071f3548c9ca2c6a8d10b11d553263ebe0afaf1f663b927ef970bd6c3974cb68
        );

        vk.permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
             0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
             0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
    function getVkLpExit() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 524288;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0cf1526aaafac6bacbb67d11a4077806b123f767e4b0883d14cc0193568fc082);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x067d967299b3d380f2e461409fbacb82d9af8c85b62de082a423f344fb0b9d38,
            0x2440bd569ac24e9525b29e433334ee98d72cb8eb19af65250ee0099fb470d873
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x086a9ed0f6175964593e516a8c1fc8bbd0a9c8afb724ebbce08a7772bd7b8837,
            0x0aca3794dc6a2f0cab69dfed529d31deb7a5e9e6c339e3c07d8d88df0f7abd6b
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x00b6bfec3aceb55618e6caf637c978c3fe2344568c64515022fcfa00e490eb97,
            0x0f890fe6b9cb943fb4887df1529cdae99e2494eabf675f89905215eb51c29c6e
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x0968470be841bcbfbcccc10dd0d8b63a871cdb3289c214fc59f38c88ab15146a,
            0x1a9b4d034050fa0b119bb64ba0e967fd09f224c6fd9cd8b54cd6f081085dfb98
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x080dbe10de0cacf12db303a86049c7a4d42f068a9def099e0cb874008f210b1b,
            0x02f17638d3410ab573e33a4e6c6cf0c918bea2aa4f1025ca5ee13d7a950c4058
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x267043dbe00520bd8bbf55a96b51fde6b3b64219eca9e2fd8309693db0cf0392,
            0x08dbbfa17faad841228af22a03fab7ec20f765036a2acae62f543f61e55b6e8c
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x215141775449677e3dbe25ff6c5e5d99336a29d952a61d5ec87618346e78df30,
            0x29502caeb6afaf2acd13766d52fac2907efb7d11c66cd8beb93c8321d380b215
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x150790105b9f5455ae6f91daa6b03c5793fb7bcfcd9d5d37d3b643b77535b10a,
            0x2b644a9736282f80fae8d35f00cbddf2bba3560c54f3d036ec1c8014c147a506
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x1b898666ded092a449935de7d707ad8d65809c2baccdd7dd7cfdaf2fb27e1262,
            0x2a24c241dcad93b7bdf1cce2427c9c54f731a7d50c27a825e2af3dabb66dc81f
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x049892634dbbfa0c364523827cd7e604b70a7e24a4cb111cb8fccb7c05b04d7f,
            0x1e5d8d7c0bf92d822dcf339a52c326a35cadf010b888b8f26e155a68c7e23dc9
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x04f90846cb1598aa05164a78d171ea918154414652d07d3f5cab84a26e6aa158,
            0x0975ba8858f136bb8b1b043daf8dfed33709f72ba37e01e5de62c81f3928a13c
        );

        vk.permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
             0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
             0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    

}
