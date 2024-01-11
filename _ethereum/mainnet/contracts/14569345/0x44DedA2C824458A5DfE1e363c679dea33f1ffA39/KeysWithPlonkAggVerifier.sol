
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./PlonkAggCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkAggVerifier is AggVerifierWithDeserialize {

uint256 constant VK_TREE_ROOT = 0x00872d9bddf7cab15e7a5b6d68f0d07cf87182773cc4a02ebc767650fef80bc6;
uint8 constant VK_MAX_INDEX = 4;

function isBlockSizeSupportedInternal(uint32 _size) internal pure returns (bool) {
if (_size == uint32(12)) { return true; }
else if (_size == uint32(36)) { return true; }
else if (_size == uint32(78)) { return true; }
else if (_size == uint32(156)) { return true; }
else if (_size == uint32(318)) { return true; }
else { return false; }
}

function blockSizeToVkIndex(uint32 _chunks) internal pure returns (uint8) {
if (_chunks == uint32(12)) { return 0; }
else if (_chunks == uint32(36)) { return 1; }
else if (_chunks == uint32(78)) { return 2; }
else if (_chunks == uint32(156)) { return 3; }
else if (_chunks == uint32(318)) { return 4; }
}


function getVkAggregated(uint32 _blocks) internal pure returns (VerificationKey memory vk) {
if (_blocks == uint32(1)) { return getVkAggregated1(); }
else if (_blocks == uint32(5)) { return getVkAggregated5(); }
else if (_blocks == uint32(10)) { return getVkAggregated10(); }
else if (_blocks == uint32(20)) { return getVkAggregated20(); }
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

function getVkAggregated5() internal pure returns(VerificationKey memory vk) {
vk.domain_size = 16777216;
vk.num_inputs = 1;
vk.omega = PairingsBn254.new_fr(0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb);
vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
0x023cfc69ef1b002da66120fce352ede75893edd8cd8196403a54e1eceb82cd43,
0x2baf3bd673e46be9df0d43ca30f834671543c22db422f450b2efd8c931e9b34e
);
vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
0x23783fe0e5c3f83c02c864e25fe766afb727134c9a77ae6b9694efb7b46f31ab,
0x1903d01005e447d061c16323a1d604d8fbd4b5cc9b64945a71f1234d280c4d3a
);
vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
0x2897df6c6fa993661b2b0b0cf52460278e33533de71b3c0f7ed7c1f20af238c6,
0x042344afee0aed5505e59bce4ebbe942a91268a8af6b77ea95f603b5b726e8cb
);
vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
0x0fceed33e78426afc38d8a68c0d93413d2bbaa492b087125271d33d52bdb07b8,
0x0057e4f63be36edb56e91da931f3d0ba72d1862d4b7751c59b92b6ae9f1fcc11
);
vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
0x14230a35f172cd77a2147cecc20b2a13148363cbab78709489a29d08001e26fb,
0x04f1040477d77896475080b5abb8091cda2cce4917ee0ba5dd62d0ab1be379b4
);
vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
0x20d1a079ad80a8abb7fd8ba669dddbbe23231360a5f0ba679b6536b6bf980649,
0x120c5a845903bd6de4105eb8cef90e6dff2c3888ada16c90e1efb393778d6a4d
);
vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
0x1af6b9e362e458a96b8bbbf8f8ce2bdbd650fb68478360c408a2acf1633c1ce1,
0x27033728b767b44c659e7896a6fcc956af97566a5a1135f87a2e510976a62d41
);

vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
0x0dbfb3c5f5131eb6f01e12b1a6333b0ad22cc8292b666e46e9bd4d80802cccdf,
0x2d058711c42fd2fd2eef33fb327d111a27fe2063b46e1bb54b32d02e9676e546
);
vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
0x0c8c7352a84dd3f32412b1a96acd94548a292411fd7479d8609ca9bd872f1e36,
0x0874203fd8012d6976698cc2df47bca14bc04879368ade6412a2109c1e71e5e8
);

vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
0x1b17bb7c319b1cf15461f4f0b69d98e15222320cb2d22f4e3a5f5e0e9e51f4bd,
0x0cf5bc338235ded905926006027aa2aab277bc32a098cd5b5353f5545cbd2825
);
vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
0x0794d3cfbc2fdd756b162571a40e40b8f31e705c77063f30a4e9155dbc00e0ef,
0x1f821232ab8826ea5bf53fe9866c74e88a218c8d163afcaa395eda4db57b7a23
);
vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
0x224d93783aa6856621a9bbec495f4830c94994e266b240db9d652dbb394a283b,
0x161bcec99f3bc449d655c0ca59874dafe1194138eec91af34392b09a83338ca1
);
vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
0x1fa27e2916b2c11d39c74c0e61063190da31c102d2b7da5c0a61ec8c5e82f132,
0x0a815ee76cd8aa600e6f66463b25a0ee57814bfdf06c65a91ddc70cede41caae
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
0x118a33d75bd2b49bc91e7e9b60592a9e93128780f0ee45909d5c1583fc312e2b,
0x029bfeb33d7ea821336d26518d0ea369963ed9a697feab042ed9c1196ce60fcd
);
vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
0x237c2be6d5ab05dac2f085e603d16a40474d8507e9e3ffb26ca054b71bec84e8,
0x0a041723d3c5882a11f0380cab33ba8c0ec5d333b7618b477073970b93e4161b
);
vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
0x06e8bb6c2c9ef293a5273b2a501c8484c81cf8907eb20b3b3e8745670d3edf9c,
0x144efe2e483905c439661fdce23df9ebbadd45dd8002ff5658356e4448c12cdf
);
vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
0x186679a0b8edcf535be61dd0c4b3d9f1f1d570f53ace4100c154bc8d857467a3,
0x0b294653f6bba0293f8d9a91dff2bf2156d7a7169e22ae80f31dc10a500d1275
);
vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
0x1b097f651e551cfca089d6483aa78c9fca8022f11cc0f5210062df4ea09675dc,
0x08cd7b2c48da8faefa0d79d5ca5e6106d9375e17a65d8ff184eed450e4d90de4
);
vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
0x2f558b39270c076e92f12a09863a5b70ba3f471e75bc4a76c5bf0709bc39410a,
0x25f36985d8ede876604c7f5d08dd2fb6f4b069d6e8d587dbb50f7418b3ff87d3
);
vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
0x194e7f1cf485a42a4d4313a28ba289a9a2d80a09482cc85acbc2b39713bae24a,
0x2f9491a38a23267390e77c706ad178a4884cf960708c601e2841cc173c580427
);

vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
0x11aea225adaaced8cadf40634b8ec791133a571f1ef60e9857305d1b6c4af319,
0x1c71a79c4433117ec0ef80d773cf03dc2555d10cfa8726301f4fda6a273f9790
);
vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
0x12f7e96a400593a494e9d5541b641c804edabdb56f9a3004187e82fc97f45e41,
0x14205d243f5a63f318b0826e2b69aaa61dd8e19cb1b353545619b063dc2a4c52
);

vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
0x1faf8943996cbaa6882e78b34bce97e5c2e623e7ba4c1f46cbfba88da7ffd132,
0x1fbb80b092682f790975ae9323c957b49d51f9e5562152fc73bc00c291a71664
);
vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
0x0871ff65b88a40eec8c8a9573625b76eb7c5cd07e1374fb29b984c8e9bdac46b,
0x2788d12e2329037f8184ee892a22a92d056616921d3df424a208ebd06b7870e7
);
vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
0x1b54676a721bbeb1304eb2721a0ce8d8f147e792481880a3e9164de4ed8958c7,
0x0af99225ab387d31f9654e8b26de1b67a175e47d59adaf6340fbc1dcc7ce2196
);
vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
0x1313fcb16f52505aee519aff9adc46c81d7fc702d41ce04a89516c7da5a5cc4a,
0x060a56882fc5eeb6f267876174fb0490c0c6ccde2ed4f56b021370d47051caac
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
0x2657afa69e15a3998bde27116082a0e8cfe5e7fe9be3ffb37d318b5368e92a2f,
0x15b2c5e18b45bdc797c1102ad693259df3f3cdf7432b21337a93dd428878d4dc
);
vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
0x120d7974239dd8111afeb34cca058db63227e5eea30495479c2f86ef2704239d,
0x185de0bdd64bb1f78e9de92bd71d112ce1b5290bd4f15f58e54ef783730bdb2e
);
vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
0x20c77a6ac5ec6a5cf728a6496bad151a7fa84583a4e44cafab5335ece5b68e92,
0x28955c55fa76091bb1beb3bc81f3f0abea9c1772b213e9cc24fb32ce017fdc19
);
vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
0x072a5373c38c252bbd9dbd16ea4ff418e3e6c3d13073c17347805af6afc016a0,
0x150ff2f3ae9c31a8c94c31605f5f70804bdf3bc601269bca4b6b4137eaf2db53
);
vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
0x2d8fc65e12e3262a891d252a81f13f75e03e5e3be04ca03a0c376a1aafa833c5,
0x14b32a4898df4aa936fe124a5dc886263e12b0f173b8e96eb011eea6b43a6c2b
);
vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
0x2a10059adb643c8fd510fa78b1d3ca75acfabf6dd02e777421510f59b7fe35db,
0x0de555189d42fbe10d0f1f325b431499562fc0bdfa631e24babc3b08f2b40239
);
vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
0x15aebf231748de2a113e3b78d4778ee429485ee725192adcd83d90195ae46a62,
0x1643482806d5c12ed94b8843ed3ab29b443be1c4303757b4494965e2725aca21
);

vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
0x22e8fa104dc1110e140f69f66defd24c501459661ab45680be88107773596583,
0x0dea216f16fedc871f884b081d934b7be1637c1705e33cee7e33d301e9dd0a31
);
vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
0x24830cfaa291d8dcd99a8f7fcfe313645286e26c427a75ec64bb385d03d18a62,
0x0cf6a160da9f331955256a0fba54561e82b6ee0ce2f4fa434addf1e07304f4ea
);

vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
0x05a5a5b8bd64cb5c0ec27397ece0f4c00e1f0889f1516b4ba8b821f832b24bb6,
0x22d6f8ac4a745aaaa9b48b388f7ca383f13d1684e04b24f627fbfa65d10404c0
);
vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
0x0b44251fce15393e219d9bec3e17261f9b041b2b837ed6897735544e0d7d195d,
0x15c907d4d776e0878ab9491847edc0a857ef4c7ca77acd365d95f00dddc327aa
);
vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
0x132f2aafa0add2184b557aa5e5a75cbef16661fd28209728a658dbda6fdccfbb,
0x223da3cd1f9ad3cf6a0cd37ceb1010286bcd88a92a16eef81447bbd0b365042c
);
vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
0x3006215b71c3d3ce7dd057f3a139fbb293e44a6ed529494b4e32e4517f51b6f4,
0x061a53d503897b89fd301316a738bf7b0e483232dc9e38677a18a8d3742cb370
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
