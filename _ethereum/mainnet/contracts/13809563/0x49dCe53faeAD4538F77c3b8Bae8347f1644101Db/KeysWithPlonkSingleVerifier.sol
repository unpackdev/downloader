
pragma solidity >=0.5.0 <0.7.0;

import "./PlonkSingleCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkSingleVerifier is SingleVerifierWithDeserialize {

    function isBlockSizeSupportedInternal(uint32 _size) internal pure returns (bool) {
        if (_size == uint32(12)) { return true; }
        else if (_size == uint32(36)) { return true; }
        else if (_size == uint32(78)) { return true; }
        else if (_size == uint32(156)) { return true; }
        else if (_size == uint32(318)) { return true; }
        else { return false; }
    }

    
    function getVkExit() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 262144;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0f60c8fe0414cb9379b2d39267945f6bd60d06a05216231b26a9fcf88ddbfebe);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x135a8971e309397099f1c5c0b9c2a141e83b888ff0504ba8c9a7c13b8c66873f,
            0x0eed3feed06aa8e4d3493aefd4c6f9a6c337e20b7e2f20d22b08b3b4129f8efc
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x0b97dc8947583759347e13c8f2abdccf1004e13f771fe9c46155af71d336de2e,
            0x1d39ffdb681fca7ce01b775e9aaaf5d8b71d9b7602ac00c60bbde91dca816dec
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x04b4d20919f8c66794a986ad27a0e4e820fb7a1bf863048017a59b1f7b3030f6,
            0x2da162d6902e64de2d4f6178f090bf9db7fbb9199d1640d5eab9c0a26869524f
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x242d28e776c833130fb04fb097c1c166c4293018e64947c46086f1bea2184732,
            0x277463020cda47c42366610a37cde00ef3a32b44906e1adee02fcd66bbe44a75
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x24d289d00964c5501b4a32521df5685264fb490a4549e794f998f18f169f3195,
            0x14307765ce1383efab72009df36fd97d28b94c9c1fce57a64697e5633d8d4e0d
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x0c3697df5aef9952def7b12d29447e9ae12fe6580f0e00399237bee51a5fa0e0,
            0x2b120b7d414a0843aa2e9e606bcec5ff8eb3c38d8b73479de42fc8901bb626e6
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x0e09a50a8e0635250a3a200dab94a1a51de811b179f61df2d4683e59fd1774ee,
            0x251732ea6c2951b7b54f2dbc349b14db2b63def8d132f86499d2e43edc21ad51
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x1889e41a3cebf0b097ec6cef8849e66480c344c422ed9a2e4d63fe75155af0d0,
            0x0ed098f479a2f229cd47f645517737f512612915010cb576398cd4ec7c803baf
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x141171280664b7aea2c65ddb87f28391cab60913a74f4255b3dd4295d162a02c,
            0x033c1cc5f1e58a035eb5f3951e79cc90e9fccf3c82781c2553b1d49694a18991
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x0fc9a25cc839ef11afab0a9f320cf2b7346054f566135611bb25b6cec46205b3,
            0x16ea53198b77ab1e469d166b36d89d9fd88b3c356958cdf377a534d73f47a9a3
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x2040345b5f92cc70a9607cf5fc28e5be26f673852450488d4e65f70890649b45,
            0x2c0e0bf512b4aa690449b589513e2b34cbc5e748a4217947331e0350c73be310
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
            0x26aafba448a6c22abfa5286eef01b17a6bffaacf20a8a0fca1a59035c8e45ddd,
            0x160835d2c20ea81f2f4c2c7f1644e30ae41b2541588a27552c08c190d5b32af8
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x20954e6cd2ad660dd9723263311b03986d6f8993ebfeb67a60a46608b35701fe,
            0x059ce6f6469bb72b8758473f86e86a959c4b9f74193d931dd172883c641a25c7
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x26245ff891a4328caa0da951efba1b5b3cc13136cd315ac7c8794053e47a4315,
            0x1681b7685491b5f8fb470a21a326bc91bd75178d411ead030aefcddd9b51bd06
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x2857e4543592da2693e7e97477f186736c4a0a325bd9477bbd996819dc0ca4ce,
            0x0ffe00e34dd8592675469bb7a92b1e78e7c9e4ace22343605fb3a48dd4f15970
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x0180059910e776f202efcb1b96d72ab597e811caef2a9af5d8b42fc79949d913,
            0x1a43d65fba7b7340f6cb120a31ad0a1d5a26e0a1151398d9a80d6930e623be21
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x007b755d547d62eaf1375f3efe8a62ef52ed1b40ef2ec0943ab9a1de7198f274,
            0x28f96cb876dc97aada23aa73d202682e3f29a29126d5711df0747234660cd83d
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x00dfc41dc088a145be5a6978121abea7dffaef90012b9d6f1b577e957a28dd24,
            0x2ef1b64e6b0afe751b5531869a17dd9d5c90d734880de7fed3d3ae74a01d989a
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x1d69be00b5e7d9d2af9d10da25eda41333effe6b9435caefe07ddae096d30ddf,
            0x162137b0ead7f1be6f448f36db186c5bee0e44f19a926e88b53f7760b64e9dbd
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x179c8e2df764ec8a2a5f5dbd37ffdde057178b6c10ef04bbb3331a7843934331,
            0x1a71e27ade54b801c811bd10d93c2b9e6c80bfea3d808487cf375f50e065e896
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x2fc48aa7bcba72e922843e8732398afe655368a3aedca1f204b0e1bd9ddbf981,
            0x2f6adc4261e3dd2fc80affdb39de386de5c38aa0066a8560f76dff220341071a
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x2a096bb764588fb3f422291918e33c1d8d9f5a8ef6c9cf41d288a5ddea0cf26a,
            0x1e2ab7435be44f4101b1af83f76d5b621f4ecdd9d673a4b019ffb41072413f9b
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
    
    function getVkNFTExit() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 262144;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0f60c8fe0414cb9379b2d39267945f6bd60d06a05216231b26a9fcf88ddbfebe);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x27ad08e12b6087f6fe0d7e1d8d8f14f53e92aaabf05e4f7d1051b0fbe3db046d,
            0x11f1f49ccf9f433366c3dc71fe9efa794678b87cbb2b07deea0cfbb7093e5369
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x1ee701b0be61332b7de5d4260ad352a3f50a8e51ac4a761f6ab5077c8dffab51,
            0x21451115294a50d06c5c442e9a61b04699fd8f296e70ef00e78a5908ef541444
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x1eccd5e119cc4a7bc8d274e0d8f61a054ee38694796790dacd22a098642bf2bc,
            0x10bb95ce678a633560f0a704001e4c148aff47b7aee0856bfec735fb13884e02
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x013fa8820794811964f35f04adb7600a9a3c76c9960b9cbb162b8324e09a14f5,
            0x0c110889cdf3554c95c7876f3e9d64804b3f0a6effa2baaf8bcb4ca847e5ed1d
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x1d5d922608eb262a5b05dc872b81238a352ba3521a1e847b06606d0937c7a34c,
            0x291cd60f7f242bd5e1075f99ed70583f40460758aa58c8cd418cb5b6929e8c12
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x2bc438c9650f27fd6b4125e098c5d87f874cfd29efad4a3e4ecae04e23b05009,
            0x283af270ef1c1c897e85b844536745dbf4d744f2e0fe8dc113143b5209a60baa
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x16f50151d8dccdd5e06a29eee62a9f614d534c542640bee31e9e9a3f2b708a83,
            0x120854cacf85957ca9777576bda620a21312769ab9596c7c64dc742156839882
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x27d2cd3c7a778fed777f6410fca3a65521282818e187e901827b1e666281d38b,
            0x1f5484c3976cadaea11704759c33ecfffe4900b696febcffb397ec15324c484a
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x26a13c2a6968f979cfc4ef24b965487c5f22f2dfc5e9008942fa32bbb72f7b3c,
            0x2bbb803702a9e0c0d4e3a078e2ffa2c525165f940a551555efbdd8876cc3f06e
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x17210a663b894d0d08db4ba0f2da65bf67b5e4c94317d03e0eb6077b11e849ef,
            0x2c98fb45631bd244290296ce55afc885e0e3cc96b506037183338141e97fdf61
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x1ef739c21d81d82ecb30445c5c6e775597aed256ee615b84c71dff243c81dd9e,
            0x072138b9876fc2f52d29b5cf35478fe4091f384c034fa59ab4b29deb69e98281
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
