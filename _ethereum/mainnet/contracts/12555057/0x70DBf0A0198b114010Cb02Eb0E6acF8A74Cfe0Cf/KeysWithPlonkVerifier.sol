pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    uint256 constant VK_TREE_ROOT = 0x12d3ca8e7e185734779f3969f1d0a9dbb357a737ed605c37c7157c341012e6d9;
    uint8 constant VK_MAX_INDEX = 3;

    function getVkAggregated(uint32 _proofs) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(1)) { return getVkAggregated1(); }
        else if (_proofs == uint32(4)) { return getVkAggregated4(); }
        else if (_proofs == uint32(8)) { return getVkAggregated8(); }
    }

    
    function getVkAggregated1() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 4194304;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x19fbd6706b4cbde524865701eae0ae6a270608a09c3afdab7760b685c1c6c41b,
            0x25082a191f0690c175cc9af1106c6c323b5b5de4e24dc23be1e965e1851bca48
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x16c02d9ca95023d1812a58d16407d1ea065073f02c916290e39242303a8a1d8e,
            0x230338b422ce8533e27cd50086c28cb160cf05a7ae34ecd5899dbdf449dc7ce0
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x1db0d133243750e1ea692050bbf6068a49dc9f6bae1f11960b6ce9e10adae0f5,
            0x12a453ed0121ae05de60848b4374d54ae4b7127cb307372e14e8daf5097c5123
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x1062ed5e86781fd34f78938e5950c2481a79f132085d2bc7566351ddff9fa3b7,
            0x2fd7aac30f645293cc99883ab57d8c99a518d5b4ab40913808045e8653497346
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x062755048bb95739f845e8659795813127283bf799443d62fea600ae23e7f263,
            0x2af86098beaa241281c78a454c5d1aa6e9eedc818c96cd1e6518e1ac2d26aa39
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0994e25148bbd25be655034f81062d1ebf0a1c2b41e0971434beab1ae8101474,
            0x27cc8cfb1fafd13068aeee0e08a272577d89f8aa0fb8507aabbc62f37587b98f
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x044edf69ce10cfb6206795f92c3be2b0d26ab9afd3977b789840ee58c7dbe927,
            0x2a8aa20c106f8dc7e849bc9698064dcfa9ed0a4050d794a1db0f13b0ee3def37
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x136967f1a2696db05583a58dbf8971c5d9d1dc5f5c97e88f3b4822aa52fefa1c,
            0x127b41299ea5c840c3b12dbe7b172380f432b7b63ce3b004750d6abb9e7b3b7a
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x02fd5638bf3cc2901395ad1124b951e474271770a337147a2167e9797ab9d951,
            0x0fcb2e56b077c8461c36911c9252008286d782e96030769bf279024fc81d412a
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x1865c60ecad86f81c6c952445707203c9c7fdace3740232ceb704aefd5bd45b3,
            0x2f35e29b39ec8bb054e2cff33c0299dd13f8c78ea24a07622128a7444aba3f26
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x2a86ec9c6c1f903650b5abbf0337be556b03f79aecc4d917e90c7db94518dde6,
            0x15b1b6be641336eebd58e7991be2991debbbd780e70c32b49225aa98d10b7016
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x213e42fcec5297b8e01a602684fcd412208d15bdac6b6331a8819d478ba46899,
            0x03223485f4e808a3b2496ae1a3c0dfbcbf4391cffc57ee01e8fca114636ead18
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x2e9b02f8cf605ad1a36e99e990a07d435de06716448ad53053c7a7a5341f71e1,
            0x2d6fdf0bc8bd89112387b1894d6f24b45dcb122c09c84344b6fc77a619dd1d59
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
    function getVkAggregated4() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 8388608;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x2988e24b15bce9a1e3a4d1d9a8f7c7a65db6c29fd4c6f4afe1a3fbd954d4b4b6,
            0x0bdb6e5ba27a22e03270c7c71399b866b28d7cec504d30e665d67be58e306e12
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x20f3d30d3a91a7419d658f8c035e42a811c9f75eac2617e65729033286d36089,
            0x07ac91e8194eb78a9db537e9459dd6ca26bef8770dde54ac3dd396450b1d4cfe
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x0311872bab6df6e9095a9afe40b12e2ed58f00cc88835442e6b4cf73fb3e147d,
            0x2cdfc5b5e73737809b54644b2f96494f8fcc1dd0fb440f64f44930b432c4542d
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x28fd545b1e960d2eff3142271affa4096ef724212031fdabe22dd4738f36472b,
            0x2c743150ee9894ff3965d8f1129399a3b89a1a9289d4cfa904b0a648d3a8a9fa
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x2c283ce950eee1173b78657e57c80658a8398e7970a9a45b20cd39aff16ad61a,
            0x081c003cbd09f7c3e0d723d6ebbaf432421c188d5759f5ee8ff1ee1dc357d4a8
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x2eb50a2dd293a71a0c038e958c5237bd7f50b2f0c9ee6385895a553de1517d43,
            0x15fdc2b5b28fc351f987b98aa6caec7552cefbafa14e6651061eec4f41993b65
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x17a9403e5c846c1ca5e767c89250113aa156fdb1f026aa0b4db59c09d06816ec,
            0x2512241972ca3ee4839ac72a4cab39ddb413a7553556abd7909284b34ee73f6b
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x09edd69c8baa7928b16615e993e3032bc8cbf9f42bfa3cf28caba1078d371edb,
            0x12e5c39148af860a87b14ae938f33eafa91deeb548cda4cc23ed9ba3e6e496b8
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x0e25c0027706ca3fd3daae849f7c50ec88d4d030da02452001dec7b554cc71b4,
            0x2421da0ca385ff7ba9e5ae68890655669248c8c8187e67d12b2a7ae97e2cff8b
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x151536359fe184567bce57379833f6fae485e5cc9bc27423d83d281aaf2701df,
            0x116beb145bc27faae5a8ae30c28040d3baafb3ea47360e528227b94adb9e4f26
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x23ee338093db23364a6e44acfb60d810a4c4bd6565b185374f7840152d3ae82c,
            0x0f6714f3ee113b9dfb6b653f04bf497602588b16b96ac682d9a5dd880a0aa601
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x05860b0ea3c6f22150812aee304bf35e1a95cfa569a8da52b42dba44a122378a,
            0x19e5a9f3097289272e65e842968752c5355d1cdb2d3d737050e4dfe32ebe1e41
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x3046881fcbe369ac6f99fea8b9505de85ded3de3bc445060be4bc6ef651fa352,
            0x06fe14c1dd6c2f2b48aebeb6fd525573d276b2e148ad25e75c57a58588f755ec
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
    function getVkAggregated8() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 16777216;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x218bdb295b7207114aeea948e2d3baef158d4057812f94005d8ff54341b6ce6f,
            0x1398585c039ba3cf336687301e95fbbf6b0638d31c64b1d815bb49091d0c1aad
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x2e40b8a98e688c9e00f607a64520a850d35f277dc0b645628494337bb75870e8,
            0x2da4ef753cc4869e53cff171009dbffea9166b8ffbafd17783d712278a79f13e
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x1b638de3c6cc2e0badc48305ee3533678a45f52edf30277303551128772303a2,
            0x2794c375cbebb7c28379e8abf42d529a1c291319020099935550c83796ba14ac
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x189cd01d67b44cf2c1e10765c69adaafd6a5929952cf55732e312ecf00166956,
            0x15976c99ef2c911bd3a72c9613b7fe9e66b03dd8963bfed705c96e3e88fdb1af
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x0745a77052dc66afc61163ec3737651e5b846ca7ec7fae1853515d0f10a51bd9,
            0x2bd27ecf4fb7f5053cc6de3ddb7a969fac5150a6fb5555ca917d16a7836e4c0a
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x2787aea173d07508083893b02ea962be71c3b628d1da7d7c4db0def49f73ad8f,
            0x22fdc951a97dc2ac7d8292a6c263898022f4623c643a56b9265b33c72e628886
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x0aafe35c49634858e44e9af259cac47a6f8402eb870f9f95217dcb8a33a73e64,
            0x1b47a7641a7c918784e84fc2494bfd8014ebc77069b94650d25cb5e25fbb7003
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x11cfc3fe28dfd5d663d53ceacc5ec620da85ae5aa971f0f003f57e75cd05bf9f,
            0x28b325f30984634fc46c6750f402026d4ff43e5325cbe34d35bf8ac4fc9cc533
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x2ada816636b9447def36e35dd3ab0e3f7a8bbe3ae32a5a4904dee3fc26e58015,
            0x2cd12d1a50aaadef4e19e1b1955c932e992e688c2883da862bd7fad17aae66f6
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x20cc506f273be4d114cbf2807c14a769d03169168892e2855cdfa78c3095c89d,
            0x08f99d338aee985d780d036473c624de9fd7960b2a4a7ad361c8c125cf11899e
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x01260265d3b1167eac1030f3d04326f08a1f2bb1e026e54afec844e3729386e2,
            0x16d75b53ec2552c63e84ea5f4bfe1507c3198045875457c1d9295d6699f39d56
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x1f4d73c63d163c3f5ef1b5caa41988cacbdbca38334e8f54d7ee9bbbb622e200,
            0x2f48f5f93d9845526ef0348f1c3def63cfc009645eb2a95d1746c7941e888a78
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x1dbd386fe258366222becc570a7f6405b25ff52818b93bdd54eaa20a6b22025a,
            0x2b2b4e978ac457d752f50b02609bd7d2054286b963821b2ec7cd3dd1507479fa
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
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

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifierOld is VerifierWithDeserializeOld {

    
    function getVkExit() internal pure returns(VerificationKeyOld memory vk) {
        vk.domain_size = 524288;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0cf1526aaafac6bacbb67d11a4077806b123f767e4b0883d14cc0193568fc082);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x114dd473f77a15b602201577dd4b64a32a783cb32fbc02911e512df6a219695d,
            0x04c68f82a5dd7d0cc90318bdff493b3d552d148ad859c373ffe55275e043c43b
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x245e8c882af503cb5421f5135b4295a920ccf68b42ae7fb967f044f54e2aaa29,
            0x071322ee387a9ce49fe7ef2edb6e9237203dee49ec47483af85e356b79fb06fd
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x0187754ab593b07a420b3b4d215c20ed49acf90fc4c97e4b06e8f5bc0a2eb3f4,
            0x0170f9286ce950286a16ea25136c163c0b32019f31b89c256a612d40b863d0b6
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x0defecfae1d2b9ec9b2ee4d4798c625fa50f6a4ddb7747a7293df0c17fcb90c2,
            0x0f91d08fceebf85fb80f12cda78cefa1ee9dbf5cfe7c4f0704b3c6620fa50c55
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x2f7fef3b3fb64af6640f93803a18b3e5ce4e0e60aecd4f924c833fa6fa6da961,
            0x03908fc737113ac7f3529fe3b36efca200c66d1d85d2fc081973214c586de732
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x14ce3c0e9b78fc331327249e707f58fa4bb0ed746bdc9c2262ad0cf905609627,
            0x09e64fdac452b424e98fc4a92f7222693d0d84ab48aadd9c46151dbe5f1a34a9
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x1d10bfd923c17d9623ec02db00099355b373021432ae1edef69b0f5f461f78d6,
            0x24e370a93f65f42888781d0158bb6ef9136c8bbd047d7993b8276bc8df8b640a
        );

        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x1fd1755ed4d06d91d50db4771d332cfa2bc2ca0e10ac8b77e0d6b73b993e788e,
            0x0bdbf3b7f0d3cffdcf818f1fba18b90914eda59b454bd1858c6c0916b817f883
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x1f3b8d12ffa2ceb2bb42d232ad2cf11bce3183472b622e11cc841d26f42ad507,
            0x0ce815e32b3bd14311cde210cda1bd351617d539ed3e9d96a8605f364f3a29b0
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x123afa8c1cec1956d7330db062498a2a3e3a9862926c02e1228d9cfb63d3c301,
            0x0f5af15ff0a3e35486c541f72956b53ff6d0740384ef6463c866146c1bd2afc8
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x01069e38ea6396af1623921101d3d3d14ee46942fb23bf1d110efb994c3ee573,
            0x232a8ce7151e69601a7867f9dcac8e2de4dd8352d119c90bbb0fb84720c02513
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
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1, 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4, 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
}
