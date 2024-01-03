pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    uint256 constant VK_TREE_ROOT = 0x2d30d1a0fc7880759a9a38f5f2b2faeeb449186dbb1ea3461980b1defdd3d009;
    uint8 constant VK_MAX_INDEX = 5;
    uint256 constant VK_EXIT_TREE_ROOT = 0x1a0126b1a46229ab86d1596d8c1c0129629f8aaf71d08027471d1ceaa22e76ad;

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
            0x22da2b43b4df083c8d97322b24a754206832f897545426a34c89a31ce32e6d71,
            0x14a0228494b414796322c2ddf4794bb2a2afa71f0b683037be1e801c953fd7f7
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x2407f20cabd71cc784c73d07fae1e54973a1fe4d1a95730f6df91782436a4f0e,
            0x09d62eab4b956798b26b81b81a15d6dbb60d9635104ae1df2b492e1d813a47da
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x19c4e2f820f273c8150cbe436f614625e1c5d063a3d1111e46a59252442b7488,
            0x11f8af93dbd520e0b509f74acc3614dc30e45d6245aa46634e3e0226c1246bc4
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x14373af9f615150befae0d36a71a1552a5097b4c211cbc0da44a285bbebe1603,
            0x2f50004d7f85b687ff124a9cd5bcaacb3e0ef31e3cd71a1932e8d099c6af7e09
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x08062a059421bea203eac68d062f0dc2aff7ffa6eaea202f627937110d635b07,
            0x03b46067547509211b66876b13cade17ac3e506341718e53dcc265457e68654c
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0965e36d9da3434423e4f19d0cac1620e138b736566a5a101110d99b431b6675,
            0x1a76b366f4b7ee995f1e2cb32dc765a563d4c8e5b2c5e3a11fea4725b7ce2c14
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x178f79ba2a4b88f667ae4ff1b83f833950613add9ae264ae90561f277b0e1c06,
            0x0a8b1c5b1a072bf70095f03228a8325cdf99d90ab0c2df622c4a451a7f953682
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x237149b5bf5ac6fe9fe5cfeafd4a3f067bed6c47109a82af74337e5baa225b2c,
            0x2f6ab33cd38c19824e98eca955d87f7711cd6440870db31d9620e08965ba2cde
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x28c30d305efd384e35c4e8e1c2269c3ba2d2e3b4bb2e477d4fba08b4bf47253c,
            0x119f92e3028a299468a036b7e88cf8629b9d0287b61e50994b06ce477bdac91f
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x1ea2c1d8e434d0d195cd3e241b0628e534bc32721ab52e83ef1b2812a9eb8540,
            0x0b2216fe4842960e9ca45622864318e70276c263b31c9a1889b0d9801204fcd1
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x1ea74d3f2cabc47c8027080d9b1fdcdbc0e1d5e81ad4cd0cd51c2a033152e0e7,
            0x22ad474557334081aae6f9663b8a7e65d5cc27846b63a19e2980cd4b23584152
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x11046c6546a01c31b9f9a78aa0afaf3da9bf684c6e3fff530e7bfb918385ad01,
            0x21a1da279a3388ddd2625d90ca358ab0fd28b92a485dc7e704e2bcfd7c886491
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x1ad755a68efa80314226acc7e50a9e59c5ea5e3e736d58eb31dd0d5d25b1b20c,
            0x1b6d12a361b9f715f94cea5222ea51fd977206e05d2615ce31defdffc700b9da
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
            0x2266b592818440dbc63787f3a1aa042c0205806e8bcaa85fd9731bd804f1336c,
            0x00cea1098cbe6b4281ff3cfef2cf473b71f7f112095bab2b2363113dbf786c79
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x1ec307f5fadd8403d2fb5832adaf282ae098c5cdfcacc96840dac6ecf5831fa9,
            0x15de86892d8219441aa9b5c446ec106ee43d598ab38716dd5d611a8b53a26893
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x197cbf225725dc443e24ab535435678435f56861f2ffef2595feb0951249e7cb,
            0x11a18010639b7b200170e28a840d9d1fafc8d97726dd303b9b03a6d59e6ed222
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x290b4842d6cde9120e2224129812643df0a801d2a50c6453ca64c943b83e37f5,
            0x1dc4be4821c84779c2e3f798143fd15702ffe1a5c237acad46d0f1399fddb24e
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x114784b9c2e7493e44a05de353457d68bc500922477b14eb87bd0a37f915d1a2,
            0x12f2d0247671d07610974806a5a770fda023e4b3b2b2e0463c3b56edadc7a943
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x188056ff46003a1deab44d44c19287ab9a76bea879edb31c1bc0174dbefa1f95,
            0x299cb5a8f96818e8bf450f9b5b7a4ff62f4b59949de68d21be2415e7e9d6eec1
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x2b4d114709231f87407121e792c4fecc56d0763a28261bc1a46e571e260635a5,
            0x2a391a14ca0ea7e1b905fbef60aeb27990209b01eb324592ced93591b7cbb5fc
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x2d544c51aa523a26d054dff6da0f86c1a756c3ad5ef1827b059e56804f9a0d28,
            0x0129aba2ce479db66e18414a47de275d12c16b6ea416502d2156a97224c12645
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x06db383f9ff92a9a6e3269612bce2c606949588309fe6aac6a62f56dc1652bb1,
            0x1e6e5dcd2fa0f37683075cc55a8012b4e3d50d0c47a5297869316792b6d40f0a
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x28ee9697ebf38f6cfe491ac0f0ce10982cf52800f9eee5b797d9c7c3f8a947ad,
            0x0f38da2c8b0c6b2c075f7cdcf2df6ef5055f9280201bf592d7cc837083c60258
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x2057c00374fad5ec29eec51150dcd5c2bfa676e483c86669d74bf14d74bf6b68,
            0x100997e07f3e9e784d1b8fd83d6cc8e6fb85efbe7a172edd80a1a801381548ec
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x236f1b6dac13cefc0cff6faef765072033c36929ead1fe29ce34ae60729be60a,
            0x0b54185abb9cebb9afb1a731919d69d1017120a8e0fc1dcb69c1b9c1d43a56ab
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x1f9a8a5c55bf9ce3e162eda25aac82b8cc6e461d43c54055f2d1ea8b8499948c,
            0x10473a3f95e08a754f67308d33bc8f0c9be19d71b89feb2f99768e3d5eeebf6c
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
            0x1f80ecf9e07df072876d928e78cadd4be8223efa5de7a639990f717e6d68129a,
            0x0cc24ea3be8508f4e06a0a1702569834eaf4e7c565bf1a6e464a97524d51e53a
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x0c8fd9c7f0307514d11ae4ea1f9ae220af20662d55209c9669ed671e17a6d7a9,
            0x1a908e93618a0694c6edc47388e0fd17a8eddb2dc2a76a590991397ec20302d0
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x16544a6923d0ea48e2b69e19a0b4b466e08dd1b56c252ea713b419961644f441,
            0x29cde074c979f212c771d211c5514f7e50473684b8b760ad18a7ec06424e180c
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x06e77ffa22b90d36a5bfe5a580524836bc33be848039761764d951cc85735b7b,
            0x26545911b48574aab42adf3466f6e2d90222bbad17bfb47205bd01735299318e
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x07af8afd0d08848659b99ba71aa80ad5ffe8cc37d28f638a27309084ee905e72,
            0x177fb27cd9ade55205b5bf7b0a1d95639466cb18600efeb0df780d3dd8267327
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0c8368b5b9f4be800e3c10c8c1a0dd99323c0c990e81b347147f78193132ea4f,
            0x082a1019087dc5501e4d117fb811d9e7ae4a0e51e9b28759de722600623f57ad
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x12828a7fe9d46b3a10bcfa6f23ba41b8948fcff1b6654e4942db9d28247510c0,
            0x0121deedb8cb6b747238db8ccf345e0f64502af13eac5787212ebfdfd9c8a590
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x02c418dd647e62b1ce21329064b49c5ac3d631d7e2a4422482f90364eb9e2ffc,
            0x1c6265347386b476081e0f46d9b353f78784a38a55a89388f8a31648693dbc8a
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x1012ee4f289e19a5dad4b261d8619fe8643327b22b11df175c0a244e62d982cb,
            0x0629cb024cb181471346a3126b389473f1a546188093384ff9837a6136a50352
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x0b1a35615ab9c34a8ff7c645eaf2e4597e6b3ede7c00b5f2af5b798cee0e1574,
            0x226e72be44f6000c4de8e8e3a6769cc2f643faebfbf65ac84f9dd23a24300a83
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x0dd4b4998d775f0e90c5dfe3c9f3f86eafd7f5e97b97831175570f3aaeb9c71c,
            0x0bec5afdd4f230b469ed00602c1d02201bb76ccd22931ad9318da00fea312d88
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x2c4890d6e52bd86bfc68992150628815bb2eeb4f7c038f33247e18062923106a,
            0x01c5e5fdf091264a70d9ccbd1844173c349120387c15a4d90d4c48abf767aca3
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x2b4bfd08af94fdd100ca8dc8f97f05d1e3952987a0d00ee80d0b0f5e91734e5b,
            0x0f44b87cc4627711335babadf98d28f44e8a02fb321e869dff626c4fbd34d09a
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
            0x08926991f4c681831e6fe1fd3b4e6a0cf658fd404e0cca92864e514b96478161,
            0x17867a63c89789d74c26b600a385cfdbda51cb596a237e29d0d88f2b4c0629f5
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x0fd7d94afc0788dba7b0e7652f776798ea08e883e075ead5f465bbd81e6fc99b,
            0x04090c3d0ddf060e405abb11802427e052b6720af4eef5e48d1935b1be0ca06b
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x075f268e92b3301b34f9ce5496b047038e0cf60af4fb305ea1778076a3e9b092,
            0x2051024d75a7b5b3d3fb0ffff24f103d91725663943f6b02adcfb01f30c27e50
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x117a97c8bd2f4cdd59eedb61b68801de7bf8881af79d210d08d6ebe370073cac,
            0x27ccdf3a13b329826cafc1903d66dd40e2a7aab70d1a272500af3e708038df1c
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x18838fc7904eb1fc84afce3437f52830ce78d5386cdcbdff0915113be1fc7d66,
            0x08cb9e758bb069e113a2d1a4aa55f3de2539128ffed2d42ab1d3b142da9a3022
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0be0b03c8447224df15da6e669a3d43a530adedb28b338d4c7b8569d088c6ac0,
            0x2d2e57e1e72a245312ce3cabdc21f576a3942a78ce0b67518b4d7ae960913c64
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x202604814117abd6df7e8bb156d83b1631238519d7a864afdb1f6821ad84dbd0,
            0x2073d36dc8f1f3d3557c1b6e70908181f4492dba571131f111909ad8e9a4c23b
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x1363a8519f225f173b5fa21caecefdfa6aa2edfba5d316ead638dbd4d89c6418,
            0x03296e2faa2915f7acc0806e6679cf716da531a9b7eb14624b9a58b1933e120f
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x19dfcebbb55db8c3cc9af354b262bbd1f72e103eaa93c83bf503783b80ec362c,
            0x086fa13bd394c8fa2dddae1995fbcf6acb5c561e43fbaf5c66321bdc5037a78e
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x11e73d5046c3a7e2253c703aac9f825fb4a4943efdbd3777b938dc43956d29c3,
            0x07161cb02534f8a483011aee48140d31270578cfc7200269b4e938742da669de
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x24c3a8df1bf71d5a3fd7495bf2fafd43d75c845ac0599cdf5bbb31c72b8d807a,
            0x0b6914dc01f33047cb6278fcd729f56fb3b77ad8a669f5cb9077323c161fbb3a
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x21ae18f1c9b1414d512ed1dada4e5d31ea6854edd3bde66053799c4e9f5f6f65,
            0x1661d279963c2798739381d19b375340098d296bd1ace972012aae93695100aa
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x0c1a45ae969673533f1cd3cef4f2f56e9fe4967777cae2cf29daf195d7c9d18e,
            0x2f85f3f301134e9165f9cc32c0717e0c2dc87a3bfaac6e2aea73cdfda0b0546f
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
