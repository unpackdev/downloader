pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    uint256 constant VK_TREE_ROOT = 0x1a31a259c1161ef96ebd7c9bb4c1e4201227ffe39f22d5dd2ca1dbca1d9087f0;
    uint8 constant VK_MAX_INDEX = 5;

    function getVkAggregated(uint32 _proofs) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(1)) { return getVkAggregated1(); }
        else if (_proofs == uint32(5)) { return getVkAggregated5(); }
        else if (_proofs == uint32(10)) { return getVkAggregated10(); }
        else if (_proofs == uint32(20)) { return getVkAggregated20(); }
    }

    
    function getVkAggregated1() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 4194304;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x1b2d28f346ba6302090869b58c0ccf45994c8aaee54101d489e4605b9b9d69a5,
            0x05b254b5537aede870276a46ae3046ae4cb36a5e41b1a1208355a4b2de0fc3c4
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x0e111faf12e663d8e6aa9b7c434376e13fb4ae52bb597bcc23f2044710daa60a,
            0x16505d91104cdf110698ebe99f0abd162630e4b108356640d1abd8596c4680d2
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x0e6aaf4f2ceb4d0b781ccbcb8c6b235d6c74df0079e8db8eefc9539b6ca2d920,
            0x0779a9706bd1a8315662914928188f51a2081d1bbeb863a1f6945ab6e1752513
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x12f8cc0d6eaa884fa1fa6ec2c23cd21892dff4298c67451f6c234293a85d977b,
            0x165d8106e03536fcf8c66391ee31e97b00664932d63d61a008108d68f8da2dcd
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x282ab78735c94c7d4fe2b134e7cee6bf967921c744b2df5b1ac7980ca39a6ef4,
            0x0f627a1b42661cca9fa1e2de44d78413a1817b0ea44506de524f3aeb43b00c69
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0f1abdaaea6fc0c841cbdbb84315392c7de7270704d2bd990f3205f06f3c2e72,
            0x18e32227065587b5814b4d1f8d7f78689af94f711d0521575c2ad723706403ac
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x2e43a380b145f473c7b76c29110fa2a54d29e39e4c3e7a0667656f5d7c6fa783,
            0x0c56e0e6679b4b71113d073ad16a405c62f1154a37202dcefce83ab2aa2bfd99
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x287f80f33b27cac8c1d7ea38e3f38b9547fc64241f369332ced9f13255f02a11,
            0x0019b4dfa8d1fa5172b3609a3ee75532a8fcdd946df313edb466502baec90916
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x262c679d64425eba4718852094935ed36c916c8e58970723ab56a6edfec8ee53,
            0x11512b535dcd41a87ff8fe16b944b0fc33a13b6ab82bed1e1fef9f887fb8bd17
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x06e470b8f5828b55b7c2a1c25879f07c2e60ff3936de7c7a9a1d0cf11c7154cb,
            0x0183d6431267f015d722e1e47fae0d8f6a66b1b75c271f6f2f7a19fd9bde0deb
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x2c42b01e3e994120ebbc941def201a6242ceca9d24a5b0c21c1e00267126eb03,
            0x2b3ee88ed3e1550605d061cb8db20ff97560e735f23e3234b32b875b2b0af854
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x20f62698b7f1defcc8da79330979c7d176d2c9b72d031dac96e1db91c7596f22,
            0x0ff81068a3a7706205893199514f4bbf06aa644ba08591b2b5cf315136fbbe89
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x1645e6c282336dfd4ec70d4ebb71050390f70927a887dcfd6527070659f3a7e7,
            0x1c93ca29a27a931a34482db88bed589951aa7d406b5583da235bf618fb4d048e
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
    
    function getVkAggregated5() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 16777216;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x20798e765493cd6c469f4ce0fb7b28da9a5f7953c8cec9a5735f06f389cafde5,
            0x17251e248d9e9bcfdd48c67b819e975ad3dafb103f4970fe2c5c7c09c7a5c01d
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x2fc13898392af94dde4dc8522b3d40059ed91645d3d67dc828310e742bb367ff,
            0x1901ae3711afcac1852051b9a0b2b849fe421d823f1abcb21dc951c88773d5ec
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x044f772c23604be394e1552d017e90e8ce76107b47436df67e6cf8af217df127,
            0x0b2c6cfb5740376c4ad4bdf448e23ca636e3d63fd0e21509e19bfd2f17e4f9db
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x2d6e15e221beaa35378a2dc4eec988cad1a9bdaabb7a94939747506a7c11fb07,
            0x07f0555dd28e1849d2dfb67d09b6cd0a044d8e1598b7f2dabac47d02afbde104
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x0f75e4f497f3ab4badccb48d638b32a1c72d725683cb579587c56345c7b5c5ca,
            0x0cfcffa462dd360860a637ec6c85aca924738472a1890904ffb3b12035cd2a95
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x1b452c4ed0d39f1a0c3509e6c0e0716206daf34ac56d7b392381b77b831d04b8,
            0x2ec5fc94a3d9fa7f7e8d8f4c976634a4c581469202cdf0962c6bbc1cfe1e2854
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x1d76ec2121fd568d20f6a3225bd9f605502941e2fa885972084509bd7b792f83,
            0x10e264487cf80e39e94079e84f9a7805a9c5f50a9f8f9c18490927dec45c015a
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x1b4c31be5bb7126ffee8a38dbc07b0b1f134144d6ae9a7cc4012408caeefd287,
            0x2bcc49e52073baa3db469867cc6e69ba5c058a70e53c37d7cfc1a4930265f506
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x1284551f36faeb407cc7032eaea6f3c1ce0709a7a5487d5b6cad65e93cc9f5ad,
            0x2ab751e5e2e598d6bff15eff38df0042bd609b0c9cae2a276153883cdf0db65f
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x2461419a8b3fa4852edd1962d47f839a7d6d0aa03d7854c5e5fa9f616082720d,
            0x2a33adabc8e1348789e0f6fe74d3a1627d2971067a6f564fe836add79cd4fb8e
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x26c5de18a55d3e05389089e4f87c22e4a65fdfb3c8ceebe94fad480762005d8b,
            0x12cae9a5899d7582e5f95fd9fab2b9907b9f72728630e816de77154b759f757a
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x2ac7330d3ca44d25eac57b4882bddf9ac755354701b0ad3f59c79b5af701bc50,
            0x1b295eee1b5472020b65ae792c4b1857457a32f56b93b0258f1ad6a6cbd9121e
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x0587644c2baa2878f893a96eccaa3393e213496aefbcbba257faf04aaa22bff5,
            0x00e27f098241d232356ce65b1b2eabc53e6920f407667d9834450ad6cba32cee
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
    
    function getVkAggregated10() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 33554432;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0d94d63997367c97a8ed16c17adaae39262b9af83acb9e003f94c217303dd160);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x195ddaa40f4b6e9b30d12fa31b569a464bc6bfed3ee6ff93d9e682f2feead9be,
            0x2ff44a308801b2e8c089531d6aef1c36934f397d61bcd4b0d40a374bf9df9436
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x0d3fa3f06569639bf5bbaf07f4938f56590e0ef1fc40bf3b1a38c833c520e06d,
            0x03f5fac1bb71bb9f9995989addf5dc96077149859b9e04f0a1c3155daf209dda
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x2fd417c4292d8d98209fbf5e4f2d9db2ccac53347a5a6a47ec844afedc7bcc1c,
            0x2c283b236436a7263d2e67971df7cd534a0c7afd5a6709540cb9e42b464a1306
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x0992d873a69f092ad514b93050c8a380a29638aece0ee6119558bc441cfcb0ab,
            0x2773318f90e7ac7591f681caae174e2bc81d85406a0224d0d6709311293f1ad6
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x287a21ccbbb448f17ea093bf72e5ffa6408ab0c42b5a0a2ba6cfa54dfa81ca8e,
            0x30276a7e2e21e76cb5e6d11dfd8c9fdf21ef1d39ce8b6322198ff83e0d2abf2f
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x2928f5217dc1375eac8c7b4d695d6fafacf012f98262defe9c5b09a851921176,
            0x0e0c579f9a0bfa1d6ce0e510814a16f24298db9545d1dabc2bb303e329c91716
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x06546546c2d7526784dcfc955ae3f714514efdf93f1672c3ae89227c237552f6,
            0x0bf25d7526789defc06fcd53246265f050341964806b46c615696ab4e6482abf
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x22b4669582b192b994fd4fece3a71194e117258c25118d8bc62be88e394862ab,
            0x0368275fa2196f8f73814e96cf0a650568969b6e0e65c66049519dc01250ab3b
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x13164c9232db87769529343c77e90d4e5d178b0695d5acc44b9e3af5e138d3cd,
            0x2b95e0779238d9324dda354e700d8747856b5885f42de8ac8f119e690bc6b4ce
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x09b9984565afa4a789d6ba629d81bc7a8f191f609a415dd071d68068f1ece1a9,
            0x0c7ade93f30c15025e00ec419a8234e23c75b8b41a6d262a0567e1494a63a089
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x050ab6d4715d929e6a03d246665bdb3ae3fb330cb1624b9dd80a16915f919097,
            0x05080bc8892e8cfa5173c161655d0d9604de4246ce93ee0f39aecc44643c8338
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x144272056d3bfd3a20817bd9e83db9255bf75d1087ea026ed265f350558bdbdb,
            0x1291171a46ae520cfeb48306f75bd9b6bcc682c25f5491bbae05967032226db7
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x135e1e48ff5f743ef65611bd6c035d609898a3aa0e1e7ac73ff84aa1591a0ff0,
            0x29e8199b33b3c240d61b5bdd63758876283dc51abb963c8a3ed6d7c39f9f61d4
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
    
    function getVkAggregated20() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 67108864;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1dba8b5bdd64ef6ce29a9039aca3c0e524395c43b9227b96c75090cc6cc7ec97);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x27310730dd3548df041a98ca4440019aac2ff23896dc0b311131e3bd258ed585,
            0x2afba6db2001ec0fb46a7aa815df9d284f93be7735f4603183df22810a8d34eb
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x2b6e6a32d4e82fd7c982ec92a970e99ca6fece8a7426f0f03c82674e285f3abc,
            0x0b1cd760a8d7c2956f620733013b687515d1a8667453eb6ebddef095d9c82c6e
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x01382f6465a7bed9283aeb0d42bfec55233220397fd54c5c31b3b0358d97840d,
            0x098ceef2375246c73b544e0e6d59942d555997f58d71fe650b3c56cb7b0c1e1f
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x0d05c024a2e0990fb0dd6831d5768ad0e5ea2cab4e56f70c02b5d20eccd59242,
            0x1caef11577704020cb0bc332a06cfcbdc91688826ecfce4d7fa95b1d356e33c6
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x150f1c2a2da8b30067f44c774dc7c913ce5b503794489eae66117ab28d7f0d56,
            0x1315bfe5e9c07a370e62ac4ee82677259abd15b698b5c679bb9cf97112406602
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x16ee6c88117311a18268d276280d151ef746b429d4e3bebde63432220fcc43af,
            0x12af9840baa1f43fe449b3aba6fbcd9a96dfd50bfb670227c5299191722b676b
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x0a4ff4dbdd532c7848559ca80b18d0e026aa05481e41bf0c7f3c3d2033c504c1,
            0x03b1b5f40650541a02900534cf4b941f3c3abf54d0dce8753fbf41905067fba2
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x1aeed9f925d1a9021bf63cace33e5e329a2fc2bc3ff2f15d44bd64b2612f776c,
            0x161e4b64f846f86f1a86cb57a179d18deb4d5485e90384c343c42827062717b2
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x08bb3a04dfc8a05064f3cca8ef52d8eeb2f3a0b2d3b3c243dc2d2c37ac63b09d,
            0x0f9cd3f78f222982e949d97119c5197553bce77ecc808d9360b5d98c9323dada
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x2d6933d1ead2cc32e1743d39f9230f34b2ba7cbd6f0ce4a495e2a6c06f56527c,
            0x2537cf3a2fbd9f49da269c2ac8f980347e7d6c3063bb4fbaf079976e86880849
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x174beb42335087164d215735b4ed67200735d97b35deb24e946388b851b54ebc,
            0x0ed913c69e882565aa8fcda65f9029b0c8e388790af40e802ea7c3ad6f114246
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x01088efa71f09d3067482a7383fe52b37417cf7fe85410b67dcb2e28139efbca,
            0x270b2a49ecbf9852a418726bdbe9df4d453eb88e39927089d5a0d27338798d75
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x2fcc3bec8b60cca2c3d9b8ef77883b04eb896124157b8356cef0436177fb6ab8,
            0x24eb48d7484ae4bb0163d49e165a27c6375b9969c3bad591a1e0a1355e2e128f
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
        vk.domain_size = 262144;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0f60c8fe0414cb9379b2d39267945f6bd60d06a05216231b26a9fcf88ddbfebe);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x117ebe939b7336d17b69b05d5530e30326af39da45a989b078bb3d607707bf3e,
            0x18b16095a1c814fe2980170ff34490f1fd454e874caa87df2f739fb9c8d2e902
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x05ac70a10fc569cc8358bfb708c184446966c6b6a3e0d7c25183ded97f9e7933,
            0x0f6152282854e153588d45e784d216a423a624522a687741492ee0b807348e71
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x03cfa9d8f9b40e565435bee3c5b0e855c8612c5a89623557cc30f4588617d7bd,
            0x2292bb95c2cc2da55833b403a387e250a9575e32e4ce7d6caa954f12e6ce592a
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x04d04f495c69127b6cc6ecbfd23f77f178e7f4e2d2de3eab3e583a4997744cd9,
            0x09dcf5b3db29af5c5eef2759da26d3b6959cb8d80ada9f9b086f7cc39246ad2b
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x01ebab991522d407cfd4e8a1740b64617f0dfca50479bba2707c2ec4159039fc,
            0x2c8bd00a44c6120bbf8e57877013f2b5ee36b53eef4ea3b6748fd03568005946
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x07a7124d1fece66bd5428fcce25c22a4a9d5ceaa1e632565d9a062c39f005b5e,
            0x2044ae5306f0e114c48142b9b97001d94e3f2280db1b01a1e47ac1cf6bd5f99e
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x1dd1549a639f052c4fbc95b7b7a40acf39928cad715580ba2b38baa116dacd9c,
            0x0f8e712990da1ce5195faaf80185ef0d5e430fdec9045a20af758cc8ecdac2e5
        );

        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x0026b64066e39a22739be37fed73308ace0a5f38a0e2292dcc2309c818e8c89c,
            0x285101acca358974c2c7c9a8a3936e08fbd86779b877b416d9480c91518cb35b
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x2159265ac6fcd4d0257673c3a85c17f4cf3ea13a3c9fb51e404037b13778d56f,
            0x25bf73e568ba3406ace2137195bb2176d9de87a48ae42520281aaef2ac2ef937
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x068f29af99fc8bbf8c00659d34b6d34e4757af6edc10fc7647476cbd0ea9be63,
            0x2ef759b20cabf3da83d7f578d9e11ed60f7015440e77359db94475ddb303144d
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x22793db6e98b9e37a1c5d78fcec67a2d8c527d34c5e9c8c1ff15007d30a4c133,
            0x1b683d60fd0750b3a45cdee5cbc4057204a02bd428e8071c92fe6694a40a5c1f
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
