
pragma solidity >=0.5.0 <0.7.0;

import "./PlonkSingleCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkSingleVerifier is SingleVerifierWithDeserialize {

    function isBlockSizeSupportedInternal(uint32 _size) internal pure returns (bool) {
        if (_size == uint32(6)) { return true; }
        else if (_size == uint32(24)) { return true; }
        else if (_size == uint32(48)) { return true; }
        else if (_size == uint32(108)) { return true; }
        else if (_size == uint32(240)) { return true; }
        else if (_size == uint32(480)) { return true; }
        else { return false; }
    }

    
    function getVkExit() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 262144;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0f60c8fe0414cb9379b2d39267945f6bd60d06a05216231b26a9fcf88ddbfebe);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x1360d4580199c4997d4ba4c95ed0577cf4672d086b2818f6e6ad604e7185e7da,
            0x07bd14656eda23c59d7f02c19094f242b50ecb69fb169d1d63877594e797bf81
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x24a435a22b07533a9f71c89407c0390ac2a0548619d8f52712b5bed9268f864b,
            0x05939b3d7e4a7320085e48cb625b9c32749673e6671790181d57f95022ffa003
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x2e823ec36c8b0a8b453581b51058242ce9aa592f1862b55f3b66e6426dee7bbf,
            0x0354110ce3383bfd9af7ef2a92d52d93b90a60e76b1e0cb67eaf18cae022a84d
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x251fffa91e442330d7645b9a22cbacbc5a1a13e4c61429b1efd5ba03d2839eaa,
            0x2b508ba6b6fa40660bfd9bb2ed248a4fcc72f0d78798a4b16c7fd5c93ac57b62
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x2210ea90c32db8a24dcd71dceabf9c8440074ad16056fd3bb99ce5720fd600a1,
            0x2d4e27890cd3fe700af39b50df098c81d8f9dac7ea7f39a078180d44b7f8c215
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x10115c8ad63661c31136f26cd4841fa9603fb0a8d15068a84a945ba027fdddd0,
            0x0421ad5cb895a2a5a0698452eb59f199fd72c1f8c8fb150649fcc887b2a0da21
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x2ef4e2f810e41d13109c14819c24eadbc582ff0c62607292888b198ebf499c98,
            0x0e85b5c05a3789024172ededc3eada603afd17313acb056acdd9ee87083577c3
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x24cc5f0fd58545753ba5874e8f6f2243eb8eb1deb0d980735d8a6cf4c368dfa6,
            0x2fb47cbb3008a4201760340adbf1c2acfb298928c78906d45961557738114d19
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x0d5afddeffe093e9a4b4293058b751a8c4db5ad97bae1b94ca5e2a0cd95455e7,
            0x1903e888f61c545870fc780d3d89ce6a21b601c1003d07b197baca50b2bca80c
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x229183766cf243e99fb9fcc7bb76f425cc9a97768a121dd729aba031cd7a0179,
            0x0b5d2879a5ea9e85b389f276c587d4a1ecf096de60229bc4134d00a5a7194f33
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x1a20d88ed8a07c9df93dd37cdbdda6d37ecc3fbecd92bb90574410d4bcba17db,
            0x0d867c3762edd7bbe0c5ca5c6c1335aacebb1f5f6cebd9cc17687c40a22daaa5
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
            0x0056414a9808c35434b70f00837b0df6096695a4f7bfd8fec55268b46a3c45ac,
            0x12d27e314d3fd2a5bda673353e961f5a2154f385b6829e15b5d3e547b1ce7678
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x1e44e773a20daabce7705a17551ee209c634e4fefe8c871da73ec160e13dff17,
            0x1fed1bedd62db6f55171a540e5d839f7ddb0c3f9839f9b88d9a4a72c2da3b1f5
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x1c7b37eabf1febe3958e41dca63a8c7aedcae08ac0ced628aa98ec30a9093e71,
            0x09f5cd26c7097b259dc0b68e3ff073dcd72cab556e7e84a07a376f23c2a3efbc
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x0f8aaf75061245f1afd39f6c2ddbdd002560d8ade05a3c72fa411498ecd0850f,
            0x0399f219a1d3499a427b07bf64ee9d6a0cdcbf238d999cb205ea28ed40bb53c6
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x2d9e24829410b34c2f478732e5e65d4f671ff50165332c6a65e8eba9cbd8d9c9,
            0x03ab6bb2cb6ead217753c5f5722361f775d5d085b87d4bcf0d542e70e43ffb2f
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x2f88402fef4ee91a3e7621a4648543b0d8ac5a860756c2b9d940f579721bef3d,
            0x27d29dce8ec872ebdfcaebbe993fbf96aec68cb34260cb7f982535ac3a933582
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x2e6fcd05f9201bcecf8ba4eca4e5b36ba4b36ec71cee3b24b23eb4229b850475,
            0x1f9b76f495670289eb2968cba709a832aa320787ad9f4336ad48fdecfff20ace
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x1d2036466b3dccfcd9cbf5044ae3979bc461931dd2cf40046db9a53e48f6d753,
            0x0a3656b72d0cead4d2b1f71559c16ca1d7a0f2866123916d8b11989832fb3b1a
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x1b78245056c25753e12fc07514eee928edc8159d8ea070b3630c1f5c9ee88603,
            0x2acdfa5a12d60d1e71fa1ef1425d37c0dd33dbb899fc2af1cb589fc8ec7ee230
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x148813470615cf6d90bda720078cfb6795e74e9dad829303e96808edec498de4,
            0x0db3ae162ea9ef8f242b3468565952e68b4ea84391034b9115898d01a2c786e3
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x235b7a06df623b1499d06fd1ce673b0f8c55f64df2b23ddcfb9e5cd8698e989e,
            0x0dc9c1ac3479d4d8431f93cd8c140755867a23c9a2167d7fd0a35c7c8359afb1
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
