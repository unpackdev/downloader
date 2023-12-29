
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
            0x1b7fa1de720cdc2b00f479d3a35202d68654dd91a9deb0b05379ea97271afeb7,
            0x0f8008f972e7922e94754b06b9cfb928028fd6f08468f4c744ecb215cf3edb05
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x18365d42e5d139ae2551ce0f35dcde75802a3eda6db726aa72646c32aa48b06b,
            0x0358462dec754b7f358d5d44f054e85d7b483b7981c31d71c0e34e050516f883
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x2445645ddd0bb89a1b83c6bc74bc94175ba1a3fdc368be74b21faf93f953923a,
            0x1dbc5b237083262425c4f63ec5e2de6b0d807f1d88303cb56d0bc75fc1d24de3
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x0382797ba8eeae1e57f130278c885572af26cf07809ab1a4f3080741b58315b7,
            0x0c19775cf8c7824578c02f43762c93c1e8063d23dc28e5ee228d49f75f8f9802
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x1d503a4bc5cf164dc76889f8fcef13908867d216c414799ab865073903947ab7,
            0x1b3732c3f461e604fadf69e7e8f0fde8b573e495cfebb8d15ccfd7572f6bc69c
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x00b44c0c88c5895e9531f7d45503407e8b30183ecf8fdaf1c0e3b97779730635,
            0x08034399d230d4ead30357c8b6ea5fdf0e65c17effa024e94d173cb9332d2327
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x2ffc4b46e96a7912cf417c2a1696fd8eab251671a03899dbd72e9720fadad9fc,
            0x110f44b9dec1efe1e0a8d9408ebc351f2e9e3a4e6781b6c3b328976758c85103
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x1d6b5368111d3c6606742131dd1da0c5073cc89b76bd3c0add22696c595cb06e,
            0x089e09860171419290337f07117448b94d27f130fedd09085e2715bdee19c42a
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x07f2bec19bb75acebd6b16086b56bcf9c1c6126e3fd82f96394ae9c18b453fc6,
            0x1160ac59ecfa2c6a48358aa36dab56a14c9e8fc58d16a9a58601e0c35f77fcde
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x1baf42bafdd5b65227b33f9e5bacde59eef0f9fbe28944955bc4bf1efb9f5da1,
            0x1d834ac270c6effa5bdf5f37b6ea7f86fd87dee8d400d174ace30af27a59ba8a
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x1a6aa64fef657595bea54736fd917459791f0b6f55c5890f4e6c6b0183c59ce6,
            0x18a8823190b856bd14505c3686155379165a6f8d7b2f0380ac72ceeb170f0605
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
            0x0a51ea80462128f55936990b8ebad4b3ac03ca598ef10e322af9c6016efa21f0,
            0x02ee47d84772cde7ffc322cf3704bc9689d6f99d14c3fa6744b971bdb31d541b
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x0b3364c30428840ec9663c6001c69ab340f32e33fb22b6e63ce2b2d7ab6dc39e,
            0x229706225a2e22e40e1b80f04501479ccf805cbb886728e65d3fd522ae8d0593
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x04a7cabf8ee567036ae78405df03ec6b90b2b80c6f0b62d6129e967a37d9ed24,
            0x0a1f7e2229541b50175945e32e192f6b9073499fa30ce9ac13d542e7bbba2d92
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x063f7fdcf4ca3fa2c3ce085e644c693d2a6a6451a0737c1a34b530c98ad0eab7,
            0x305bf32b20d102ecc65ec1ae0cb6a2ec70e8850a0c525ba75484211a33d6909e
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x10bca91f25c1d27ad6422450f449b4e88ab95bb880fff20d7726f0f54ddd1cc3,
            0x1cad88f1e381964ce4c9b50ec63040fbbbd7a1586859d50c6ae994fe5bb942a4
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x12895c715afa08dda4b2e64b452c5cebfba509c44a5ec40c7fc60822d8cfc71b,
            0x2fd6fd651ee440047e75ba856d1d9c905f87a5af94a9c91287359bdd650358c7
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x14502af4737adff4bd0a1bf368195b66c6025ad8fe931133c257654044b7cd67,
            0x1ea1a2da257a5cfb992e804552948b55eb8828e772f4ba8145b906c1c6429c56
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x17fa690797738baba8441cc20310332e104ecab06c3cb7afee26db16d6552e00,
            0x1067e3dfc8e17a65831b6adc15597b774dc31731a8c8c678dd643c3f3bee91f8
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x2e6f8cb6126d8cfb2d52beffb11ada8e9befc68d07c17fcaa6160d4272537c14,
            0x2a47f9f8e4e541455aa6bb2fa5c9e33a6a4b8af8ba2487b6d225918d151aaf4e
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x2e82c35689283a51014da92a2e9f1d72b12975fdae0bd5660eb1de27149465ab,
            0x199a725575c46e1bd25cbead965e3cbd98d40556d67b970319fae3d486327ed1
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x23f09b8c571bf69633a3a6261ac520bbed2202847a631e6938e1cdacac0b2107,
            0x12478416bcee6d8cf02659b663455edb2f7417b70eef27d28c2223f06807712d
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
            0x23f18047e7f13452e2fd9ff957f64a480c7d39e3dddd6079048476e73682fc78,
            0x034bf29d128cebebdce82cae0ecaa822ad727fe128ba23017478d96f8c0c1cda
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x2a6dbbd7a2a0022f89ff9a4550eac7aae746332acdad833065c6a5ced0e061b5,
            0x02079d7199cb75dc81964bfde2b0a7007d5236206fa4f97032ecd53939b3f4e1
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x21a7754b681171ab2bc0bee630fb97df3bd053d3eae6e6986902c456b9636952,
            0x2352c0647771039b72c45e6acdbfb63efb8c2f8c56ed5b33860ddf7d83c4229f
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x2e3f3c1c2cb9870562fc94585c5fb476aab0ffc46ed93475c4c768baac92e474,
            0x0d4417fc21e876e586a469ffa678f155b6c5938eab7d7eb40de203ddeb44d53c
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x2887217f1bf98c084ad1e722ade570ea3b2de97ae19d373be759c3eaf256cde1,
            0x0c7a85ba1ac4bb3be0dedbc2658b7d71eb5435897783a2f2dfde027555cca62c
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x21de0db0c7c54c6936eb1d1a45d6ce6fc8904156a257c09416e11a18e68608af,
            0x236e692ab84cd24a4f644fe6b535a6869c4630fe179ea283fc7c0b888da407f8
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x119208094200a6ad766c323002f1031525a0e149b0333de6fe6cf64f787d12f3,
            0x06fd9bcad5f4a874cebfd1f23f8d68151144c0915c7bd4e8dfa8947d2567189c
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x05ea8d7091eac4933a595bb32a337ea26c1bfafcea43a8497357c9c6e72b083f,
            0x298b58844cfe7381cae17b7a137617a59d221842e24b5864c86483978ce808f0
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x2a9b4734ec68c7e90b2e4849932dd3a62876535f60038248634abcae143d5c8a,
            0x2bdf3e61783efba973e021f9110836e9f04566eb3dc4c5e84701870443b6a010
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x267a8cc6e5401bd2e4f9fb6949e62928193c9aad21eaaf14f7c9af1d091a8ae3,
            0x0174ee0780a86c7d4397f5daf156f8c0433bdc9cd2ede24406f36aa5f0acbf48
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x09945ca4449fa736821cf90aecd390ea930ba95e9b98b7bfebfb8f5dd1cb1735,
            0x2e691bb27e7151439e354b8a24a7dec8a01545f2219f96d852969c61a87000c5
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
            0x0a1a1f5d6db6e9dc584ffff3c212be26a3785b68a61cf237dfd16ffee921e6a9,
            0x00db9a67e6958d30a212bfe4a0e5861380d1ca1055419ebfb484a66353f16d53
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x20ede8e875ef8380ddacd6dc0d31713107ae0ef39e142852a9808d42ccbdb0c1,
            0x08b74e0afc5bf083725f9939568a5581967241a01d5a890e47687089069a7a76
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x057c51ca8cd775db79adc63e82e09a60324fcc95ed13986218b74ba952a18573,
            0x138e5712b1617a9323cb9a6c97a52d454130929d3ca727fbdaf8a18c9f43b55c
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x0bb0efb7375a13e88080e8ee7b9a5163def75d815a0aec53cab077f0b38caa67,
            0x2d9e82fb4d502732ad4babe1877e80e38054f35e5524bf3c24f2e625588fbf21
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x12f1d4a8f4609473250e641ae0b11f10affa18a769ba175caea3fe785edec2ce,
            0x04277b64397307db55f58c20a3d6864003c768fd4e4aab83e26b9963f2e9a002
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x2edfaa6e36baf1c55b177582366264a5866a4cabf98eb3d84a1aedeedecf2a43,
            0x0180c206de268ef3fdf701ca3e3b1c96c5a98649ec3b01b9730f34ffc1a8f7e5
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x0cae0664fdfa45215ec9c98e225557292f71e42b7ee486f6cdbde0aefc015945,
            0x2b661a5b9c3f6130ac77d5d665baf3e286f068a181fb0bf957e850f00156e5e8
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x0f5c9bfacd0cee94b84ff62cc3f26e18b89fb69910a41231b4eef3ad516afd5c,
            0x2379fed7c329f84d7655e6b1145f6f0b428ed8a8df76f62f97b8804ebd3daea0
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x2b3b2d6831f0220f5893c002ecd9e382cf2fbc27da2d3c040ce50d0ed83991ed,
            0x0e245126c4ddab15ae6be4d8db7ea7dd6f94593ed7152ecd73d6b7961decff32
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x0baaf7842b4d13ed569cb4a2bf11f16dc6008259efce1052022b6cb479c47fb7,
            0x0e51f02a004492b8c24c6bb5726725785709c96b00a1b87a97d45b13fd1722a5
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x2fe999258c8a8d18bc545bf57158cac51f94a35be73aed66c03a26c136a1fbd4,
            0x2ce032cd81cc7523a896574f44398de4de8564f24abd860dbeba3e25fbd4be61
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
            0x16b621799bf874320688bdc6001550d974e69b48b8fd5ff9c8fbbd0d23119ae0,
            0x018892a23a02980d9ba2f26cafedc01a7ba5363072328c783c8206f7745a8d79
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x27b747297b97efae9364dc38e7552fbf4ec4fc2c4b3123799eebc75823e75c2f,
            0x1b46cb39ec8c92fae4fa6b31cd2689ef1d80b6e6c2074d45ee90957dc658030f
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x1f634cc98ae4ab87a57423fff29f26c72efeb515805d813755e1c36f6697550c,
            0x0e7f592ab203c92e05ce28548b7508a768f447ddc4d6308340fa197d72654a68
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x150ff91c94a3206cf64fb5b4e59487859fc588dfd6506ae6e358dcd0817412fb,
            0x17d93c2b5f623ef8a68ab03d4cdf85b413cf63aa0e608f3280d2d3ef4f7e2619
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x1fc89917557fbd11b0ee52a13e9f148b096290ef5dff078da0bbcf7871744ec0,
            0x29b444286b18e4a76c624fe1bbccfb730a520d990ad56bffcccfd96f47a7a833
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x0d927553dba7ecf854a7111868d7f8622f2ba196c21e0bfbe5f8af9f185ba442,
            0x1469ca794af0355e04a88189de9776a9cf04fb425dc21b779c6b3e08b854a64c
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x122655733fe0f8653789bfe96c957d6265b7ee6f0b501f3c9adc880f2a637bb0,
            0x0ec03051e54b61a4ad505bc6af98662301c0d8fd403a7f8e6b826bb53e79dd1e
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x2a7ebc7776d4fa15b8651eae44fab392aba9ff7073f3edfd7b848706ef3bfd6f,
            0x03111f951e32e99ef940b10b2c75b04049c11fbe6990da12e03388ca8a187ba2
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x2da022e2195e92fb26c2ec848d996c57ee9e7cca9c409aef7fc5111d97127793,
            0x24d8182529c20362cf46237298d73d0febd7b01706d34f735b7594c1eddd035b
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x1b30ed4b4068fd5794d74b2eb76b0952e29d7cabaaa7bb5cd8afd985b3634293,
            0x09d86602575fd10ceba20e6cd98c182def2a5552978df02ebc6c48a18a5261f8
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x2e8236c1267534ac088b251270ba9e5762a203cb025b636410fb4067096ae9c9,
            0x19c47b480290e45b9eaf9c878372922f3c805d369e072423adfdab846a6b77da
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
            0x12e523281c5e083564f87ebf71e8bcb5615596e8f755056c258341173ef633f8,
            0x0ff470566f5d737f92d3bd33ae407a1bf679804debe1dc33a3f86da8eacdfbd4
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x123af186f997895949cbba9f961b2d012723c8d04eca90d048a66dbdc01cab18,
            0x0a8a416e550417bd7977e51126c7a9af80cd65567eb5ffb4195f17501abe1a9e
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x0091717cac476948a386ff3043b0461f0d0b368cb369586b546b07bb84ce91dd,
            0x20486d6fb751acc889ec358a2df637b966677ccbea9d39de97db1e4f405cf2cd
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x021b1b727fc6b7e0f5f77d11417afb20f6cd492ba086770e88907d6bf56bd4a4,
            0x22b06a74279272942459b65e888f1bc6444a3a15710257ebaa7da25bf17436ea
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x268ebe620f72bf02b32256f1aec10c3214457bcb6c0864a5a3a71f8198a599df,
            0x1d8ba556f2a807f4454c043749cfca65a70bb92e01b3bed01f5ae999b85817f5
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x0c7b608ac4b3a18f55eeffb1e1f6f720b3d9bd7835a120a8d5df60050a157b4a,
            0x2e6acf782b67806832f1a258b0e5f9e7c4ac1de83e9cab49509b9f035f5e9dbb
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x219c6272cbc3ae7d9e8d366e379673414bdf283beed79a959f2e8181cd064144,
            0x06e93645439a57524c4836188cebb6369ae36267e6a9665156c13ae317e0ad4c
        );

         vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x13626ee4cb40e8783c91c9f55272c1f970df3486b98a39d7caf67b188de9109d,
            0x12bf400879bbdb556fda31f1d604df9b48dfe27d9429e4e55a034c2858261eec
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x246b842ca3eeee58b21a59e43c1b9e2da2e697378d79d4260325258b831feeba,
            0x2c9ce5bad6dc5d16cd0a8e9c7c7b9da64cba83fe277cde913497c9eac2aaafc7
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x2b45db9668ca0695cdd74e41bfce4c676f3786d6ff94d4151c80edabe8cdce3a,
            0x0b01705505015831057a6d28285a10f315767904df5cf474e2ad0692eb8c5868
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x245a71570a6a716912e304ea15e1365ea7eb378df8d70665525113ebda0202de,
            0x28003d8b4b1c49b127363f05ff2ea2faa0bac2f722f0d51c9e4b26ab8b6438bf
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
