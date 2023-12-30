
pragma solidity >=0.5.0 <0.7.0;

import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    function isBlockSizeSupportedInternal(uint32 _size) internal pure returns (bool) {
        if (_size == uint32(6)) { return true; }
        else if (_size == uint32(30)) { return true; }
        else if (_size == uint32(74)) { return true; }
        else if (_size == uint32(150)) { return true; }
        else if (_size == uint32(334)) { return true; }
        else if (_size == uint32(678)) { return true; }
        else { return false; }
    }

    function getVkBlock(uint32 _chunks) internal pure returns (VerificationKey memory vk) {
        if (_chunks == uint32(6)) { return getVkBlock6(); }
        else if (_chunks == uint32(30)) { return getVkBlock30(); }
        else if (_chunks == uint32(74)) { return getVkBlock74(); }
        else if (_chunks == uint32(150)) { return getVkBlock150(); }
        else if (_chunks == uint32(334)) { return getVkBlock334(); }
        else if (_chunks == uint32(678)) { return getVkBlock678(); }
    }

    
    function getVkBlock6() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 2097152;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x032750f8f3c2493d0828c7285d0258e1bdcaa463f4442a52747b5c96639659bb);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x0af568a35305efe9043e30a66e5dbf46219e16a04c7681e0291759114257a9a4,
            0x2f35e4f3c521dcd57b7f7cc1548df2a4877eda3d6bf6e47830b7b4c5c78247fa
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x15facf3c62fdc8eb795512905e6756fbdab12f583e92f847fe04ebed1de2b0d9,
            0x145ba3f0cd63989a960af1652ace370d8ebae9ccf8462780216625d812100623
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x16d73cc25f2f549e265a5cc871d5350a340e53bfab24118d30d6dd3276b9edf5,
            0x1eaf73c1e29c3c3a1702e2375bbee02458c04ae316a603c9509ac9f041bdf67e
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x1f652d9f3fb289cfaff303e35b53e4a1915f2a4f631115e572cfb7dd7e72c9a8,
            0x165827a3b413c30dd0e22f10b58e7e64774325e5a213821b953b20d26374b1b1
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x0bb9329eaae8b9979ccf377d312778494b03642e3a1f629f1c4a78dcc759b348,
            0x213616224ae180ef4c0010301e037e281689f84d5a9121191957eff36770d526
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x0b478d136e36e67ef049746e8b452afa88c13547cdc341eef713fa7e42f6dcd6,
            0x24ef9c90e617fcf3adf998dff4c3238f8fe564ba2da8d15ac3c673d0b16d9bd6
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x09a2c2eeb91944b93013a95e6a63a780e881f101249375d9732ba74c6e54186b,
            0x2599f0b0d736bfb3f66cdff99c9f5557f7b82a1fa4029d0d5770d1d194019533
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x199f1e85e793132f1ce19e86967efb1ed606e68b7af0478532fa182163fefa6e,
            0x21698d34ed8a715d0086ecab6c1b7fcf4d9a1d7995db29d517031084f2764f95
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x2389c84e9eaf7f61ad69dd4d19299530c4027f083c6976b5e7cc7f3b7cb57b55,
            0x18ee0d9df2d37dda5e85a5764088e89ee8ce32eb7ff45173f0fd102c522d41e1
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x0f922b9348896b282f12aff0610e39dfa1b6066aaeb5a04f0a5a29d2bb0096c8,
            0x1e24a9abbf50778a8d2fd51b37a8eae7836cde2c559740d6ec322c8584274442
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x2abf5027b8f2a88015873d2b3f97ae97da5f771e800acf89098c5d2228086cf1,
            0x1e245aa8ee95af522f204a3e62b82cc62361cf604efac1dd27d49252d1d360c4
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
    
    function getVkBlock30() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 4194304;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x0dabeb092c842c9877aab11b2242490061cef35c2631e3c383f1ce13c386aaf3,
            0x0d34932557f52b84c523dc2474e79eb343f84718d7f20e519a85d10bdb4611eb
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x1c0ea096536ef84a9ee46457b44d4bf9f4b147e9cfd9157f9291d50e59de2512,
            0x0b84d8085ef5989f16bc03822d3c3232c2d5df22a0d0a3ac80e6338094909b3b
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x2f6dd701052fc5e95812f5c0da0bf96d5120d7dd5a60bfcc7705aeb212593949,
            0x1275cd37c2e0b36830d7a0a3000668064b28c3ff4071614d5992e7a9720fe5a8
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x1466533cc8c309aca62e5571d170e056b570358ba73bdf921d914a96deef85b1,
            0x2f1d1375359dcd5c881b144b64698f15e8227d3f4cb9507f463eecb14173942d
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x0d23903b411253d6e1ea85334f072b75da815db364e96b600003f3f95e3af56c,
            0x1130d37d579a1c54aab11ac4e7b7e3fb12e2632682c41f40042cf5e0de646e32
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x130a475c0d12c09535079832afded260636cea2d3acf638b3645f6f18b1defd8,
            0x0bf9f1bc4fe3d87628e43c5f87634164bb4a7baedeb578e8b036e72bc5da9038
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x153b616b629aa926262a08d03f3626b2623b1a2aad95dba19d80878fe4d2701a,
            0x0ce4c47b8656ea235b974df7b7ec7e3cb62a952704ebcb084ecf521da22c1549
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x0ec6a763e129c400eeaa8bf1d66498ff92286d1bed142f92c932f5ef8cf8c5e3,
            0x23a13322172b50c6f624e9c7c924260e2894f84ab928dbb718d0c391b0d43abf
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x246a73716676323f05a5d6137eb98c7f6c8d6ca5f9b63c397271ce820175599e,
            0x08ac8dc778bb4998b6d8440fb25463d7810986439aae3f3ddc6e24b0e8a8da2f
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x1174638606b9dc726499db27c34f317db4bd0475678827972fa0da4fab6da1f7,
            0x17ceb003ecee92a35fa0ab0989de9d6aafedd821c6d89a0dcded8b096f5b45cb
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x1e7f3863aacbcbb3a43318c621b0abcae89a145bc950dd161fb793fb425ae8cb,
            0x2980f2f25fd142c92a55560529f7080e7d55ed8c3cfbb1cd421186c3c3f799e7
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
    
    function getVkBlock74() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 8388608;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x1021fcff6a718826f54ecb1ed30b237b453a8d16a68c5d473ddd1a98ce4d3ffe,
            0x1ff632b0f6b06f344c7790260938e21fefeda3c4428e4f3ffce28301de847934
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x04d1cc2c538b6bc75450f955d21550a948cb38b8aec7c9775795a96aabdb412e,
            0x159a35771ccd356ab60f186c9efc8767df370c28e2231ec98e6a674bc95f7612
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x23eeccd095551b0357be6eea8bd9ecabd4a446cb7993c545c7193a2d5bb8657f,
            0x00827f6f318c00d7dd2e4a7f3bd94810af906e62eb6844bd110e17ee1ec16f8d
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x1d3bdf4f220278fc7fc8be20ced77647dc38be36f8d9b84e61ddf46e1d593d14,
            0x2396a7d5704823939ead4a2bfc6510a7f6470e2a1f447072c9534d62372873f3
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x040be274be43c2d83ae606ec3636fec5c4e7d8c99becf7d33b52adbd0d724b8a,
            0x0dec58400efeed3381f71ad1e83582c139a8b728fa9e25ca61e92ef46a09e025
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x0adf559b5270e352f9ab28f549922da636aef8bdba57d67f85434dc56e78c744,
            0x2e70f0eda4beb23c457fb274b0aa553b82a94f07c6015ee589481cfa2b3496b1
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x2a8d0d37052e369ff5f5f03b3263deae82cbb555557050c6332488ec2be812ae,
            0x2fa789399c26b85d1cf48961bbc44dca2eaf75016720f9e2ba78c1133fadf0bb
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x238b4d00fa2d36e7ab351a32f91a2125622a5bb0ae9af7fdbd9b60cf000e6e91,
            0x08ff4499abe98d10e1b6b2fc77fa32333dd5f41cf726cdc71503e0eb8595f4de
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x0cd7e807d8ed7749d99f27e58c871f6feb2036ed6cfcc5a411dc38c7fd307be6,
            0x292f00dd8d21c1ce8124bd9f82ab249dbbdb6f45c3696481ae38ee77b22f849b
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x2809b958f09357f3a419ce2245cc5b38e8faecc1ec767d5c868349e588fe5d44,
            0x2624d43f0e037f39b0a6fb9f5ae4499849d54c54c0dc3ac8f9c292ac8551e6bc
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x276a858b024e5d82607fac4ee82e97719b25fae9853e2c394236ebc15bdc07ed,
            0x11de57c72d139056394203bcac52a132a9d2a012edba72949518e3b986694a8e
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
    
    function getVkBlock150() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 16777216;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x2b980886069d87943728e229dd4c9e983a0ce1a319b5ab964fced0bc02e2cf96,
            0x176f6a4a15b95fa93edb949de5510ee84c50040e05c5ee1e2b928ec013d2c0da
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x251f54507ddd45d703e5a81b666217e0c3e9231fdbfd382188dafc03268931ce,
            0x27d916677565037db4532f2846e10f42cd20499ec54989c42a996c86429786c0
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x00e1d3e897a5f0fea282b120762ed656204c7b05c6716f92047c88991a6776f9,
            0x1c83d49caa16f271c2f7250bbc4bba028d4dfd65ed880bc294005253ea7c846a
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x29692360bdfa1c1fde3828cf2b903f6ec3853a1073368db46ab444edf5989cc4,
            0x1fb7acc4736be1008144d100c5d447cc55d36c988e6ca974afb2d6039ad19c71
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x2324d61f18207e8135bd2f290e4acd36fc9a977411da6c7e404702d120a4aa4a,
            0x12f7ce81186f570986229da30c136c85473d552fe1c214a7eb3b2d305b7b2ae5
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x1d1d3df125d46c06153985ada847816cdcafbf7c8f72d99ae779680bed23e935,
            0x1685aa96e1c7d4be8e4993d2b50e8ea76fca9166c223749492f31ebf22915853
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x234111b09c5d38dd313eb1ef80a12cbbdc20bc6066310cd5109f93a4545852da,
            0x02441d140d85197884cc9cce20f80670cd94daf51153e61d99381ad85f9d3421
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x02f194881a81ef07ab23dd4552157fb3b83a67df10ffd6916c6ac9f8f5a088ba,
            0x0cfb413a65eb6880ffb16277e56b6e1f2474bbb5e2de0a71f06a94118f54bdab
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x1292198bff3ce83fc2410250e998a49ae2d15080555ab268e2714e7cd7e68078,
            0x206789f5461397abcaed25062e0881928a9ad05d02f031944dc3a3c3b0955eec
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x2204220f2bfff0ff22d77c9c66c3fdc00b431e92e930dc65ba3a6b91a3350a98,
            0x0e46f948f7b703fd7c100575ed47db8d559b93fba62cefaa6f65458249b1e52c
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x2b627b695c64b566e4f4b8f0be454d1de004cce7fa19e6f7fdcb2de2397e67d6,
            0x264b1bb8361351d44e34c89162185f489f8e823c649dbbd1f65a1d10e3e196af
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
    
    function getVkBlock334() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 33554432;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0d94d63997367c97a8ed16c17adaae39262b9af83acb9e003f94c217303dd160);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x29d9574cd4b98e563db05a14d1ecf9dd7b8e3cd5d901e140d04181c9f53db97e,
            0x2ee352008474de4960ca513838e407cd27cbd5c5a8cffd67f67d8a49d4861279
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x1b1dffc6fde1dd941557412626ddebedd2bcb6f9f8cc9c19bc1f1cca2f9635c7,
            0x0f2a6292bb6dacecaa6cb3c71240504f417d8e45f8b345707486afb658fd9d4a
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x0210cb0963ab20ff896d704feb4aadf889ebfe3c3fe1555744ec562fc8bc24b6,
            0x156b1a7294328baadcb080d01237d031acf66f63c2d91659d16e1b80cbf3a890
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x1c3228a3e68fe3ade8c48d516595407359570842d2ab66127b77dc076488be5b,
            0x2497ee062b253369cdf12f373e8bd7c9bde6942074b7fea52d1751e9b0de7a24
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x291088d66f3e2f19861c488ab28c619a8fb0ead716cbf1182be4c857a738e37b,
            0x010eaf9bab2047a22c90b03c95a8d4f4f45ed0f3410777fc572ca249398017e5
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x18c2e15408ba31f91aec85db8edf934f6ad294b1ef641109f026090c7ce788af,
            0x215a339e53528e9c9247987610f93f0854de562fd78ba34aebd8e0e82d5a45a2
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x14a4455b1da8964b29fe75d6b19283f00fd58d3db10afce417cca2a69cd993ae,
            0x12d468900ccdc72f0f2e7f41b9a29329c46dd8ba3b0344bf453e2d172a26bc9c
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x04a3e03c4f3e964d756e69a0de2d331c8679cfbdce806849931efe547d493b4b,
            0x20871a71fdb6f7e12839bc53ff8b0559d30db42e523d1754121b2ee8f967361b
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x1e8f25a49a753a938da78263003a4dc0e68492940abd9b6294da149c7c927216,
            0x0bcd44d08ffc48a289e87b0604c7a16b5e119e3c47b293c3c6c29762a4a5d326
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x2f3b23257c3437e10631f5dc5da61a622f17dd1516294e013fe484a3adf42462,
            0x0b0a21cb5384dc0669f58d54671732385cf96065680255d46861f9a7456267f5
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x01ec6c4541fb1b4342d219856f1805bf7b94de582b261b096ea2b11b62205633,
            0x05a9b67927c90079c45907f9ba67105b47b15dcf480b3bf3514582dc18d357bf
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
    
    function getVkBlock678() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 67108864;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1dba8b5bdd64ef6ce29a9039aca3c0e524395c43b9227b96c75090cc6cc7ec97);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x10fac38e585fc150fa6f7470ff88f978bd906bd5454fd067381816c296f89870,
            0x1b5424e03353a60155d057d5b0303c2b0d78410cd2f7b0abeb2928b76f808816
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x0ff633c9b1ed5af3bd5882da5354dfcccd698066d4050ff0c7fd20aa9cd01218,
            0x2ab1ee7db81f3e504032e3e36e297c38d15e55171a49cee01ff42d1c954d63a5
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x03aafad8e4a648f6339fc48f229b8672c64dd64e7866263fa8c4e0e716961dea,
            0x03bc02bc248d3d3aa917b9eec4a335dc7b1c21ae694c6166911b7246fc95a539
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x303d788f44e34b61d5671389e8e4a7bfa4f13c02b8c2d345d0eba623e5a6f17f,
            0x00a6d7d77556ccff73f1ce9fd0ddce9eb8940731dbdca250fad108ffbccb744d
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x03cacd9bc51ff522d6cc654b17483cf5f044a15eec12f1837fcb9d7f717d5a67,
            0x0de3f25d9a6865cd7cc72e529edd802a0cee06d1b45830a294bd6a2240d4bdd0
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x02c54c3ac215172724f0b8138e212e793b28af7ae06b5b53c2f56b52cf32fff6,
            0x25093d56e5e5dfad1b1c75b94250fcb4fc430ba214bba40989855d142dcf29b2
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x222cfccd491605b4b9e15a18b8b0d841c8c5104ed3f96a97d546b0b33cdc67db,
            0x0f4ea5620594b707d6d37c4292df6889bd835574abec790b97fd0af88b1d1edd
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x230f568480422793e27ba60859477b363d50ae18c48ace23d6cfcf04abe29dd6,
            0x1c6c663735ff13ab1332598f552fc3d01410b18cfa9c6a7bb88df553c79a38b0
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x0955c07d90bf6d48aa1aec00c060f9aec57f10fa76285684a16cd023192af01c,
            0x290ff005de85504f475b596b72bcf1623b71b30534cd360576626d6737f1b763
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x0cac2104abcde1bf215788c18be6a5c2d73da416f8c5b6e0a2a2222a24deb32f,
            0x02dde54e719bc243cda9febc88187582a0983ff1a85d6f888bfe13e4567d9aa5
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x27fce095aa4c68adbd01f5fd8e64864f6c1625cc577e13a2b80051947b2e8ff6,
            0x2583c01600426f9b3873ffef651187c82c0e55a6e5de762355a458fc388f4585
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
    
    function getVkExit() internal pure returns(VerificationKey memory vk) {
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
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
             0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
             0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    

}
