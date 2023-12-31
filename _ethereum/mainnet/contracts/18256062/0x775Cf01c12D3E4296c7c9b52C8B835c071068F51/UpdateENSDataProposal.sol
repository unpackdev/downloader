// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IGovernance.sol";
import "./IENSRegistry.sol";
import "./IENSResolver.sol";

contract UpdateENSDataProposal {
    address constant governanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;

    address constant ensResolverAddress = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
    address constant ensRegistryAddress = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    IENSRegistry internal constant ensRegistry = IENSRegistry(ensRegistryAddress);
    IENSResolver internal constant ensResolver = IENSResolver(ensResolverAddress);

    bytes32 internal constant rootTornadoDomainNode = 0xe6ae31d630cc7a8279c0f1c7cbe6e7064814c47d1785fa2703d9ae511ee2be0c;
    bytes32 internal constant sourcesDomainNode = 0x4e5775b58e8aeaa32fc2b429c9485da9de5a1c6fead70b8704ce0f970a6f127d;
    bytes32 internal constant minifiedSourcesDomainNode = 0xe0df66963d3ee12f2f360e193f0443eaffb41afc582166678b806d25b9941ce2;
    bytes32 internal constant packagesDomainNode = 0x205450e4bb0700adede3b5117ed52080e8433e9287815066aea78582107db04e;
    bytes32 internal constant downloadScriptSourceDomainNode = 0x4a6bb62eaa2524f194a206df4c15dcc8e9a93036119d40516dab5b7c021fa43b;
    bytes32 internal constant classicUISourceDomainNode = 0xc0048472a571cb1a08f3ab829dc02e499a23802da54cc5a9a621d96f08acb124;
    bytes32 internal constant novaUISourceDomainNode = 0xa53a41e448ef36a88eb023695dd2e4db15897f6b6e02ce7cb81fe7603da1d860;
    bytes32 internal constant docsSourceDomainNode = 0xdd158a78d03e8c953fe2b54edcf9f9919efaec1d782a6603b3f8f5871107672c;
    bytes32 internal constant relayersUISourceDomainNode = 0x0315c3730f5894b97933d148a24f1b29f823c6a64caadc4a55b5600b510234b2;
    bytes32 internal constant tornTokenSourceDomainNode = 0xd817f80f72b6a337289ab88b44ba896365e52c5a08e816baef170fde21297ad9;
    bytes32 internal constant classicRelayerSoftwareSourceDomainNode = 0x28fe01fe7f28555b980620b2b69388adec9a8879ecc9648d8c32cd4107697408;
    bytes32 internal constant novaRelayerSoftwareSourceDomainNode = 0xdb0f46e0901b38c81ac357482fb43ea4c4da6655cade719cc228ccdedea39504;
    bytes32 internal constant tornadoCliSourceDomainNode = 0xccf6a9a7714d27164199e07b6443821e152be908ec362e4b16af8acc6bd47950;
    bytes32 internal constant infoPageSourceDomainNode = 0xb1735298044f249ea99f70f266979643a3a3ba2c6c7902fbb5aadcca6a04923c;
    bytes32 internal constant classicUIMinifiedDomainNode = 0x394177cecfcf0a9fdc53ffac572e0ad8d40448784e39f40442242e52dc405c8d;
    bytes32 internal constant novaMinifiedDomainNode = 0xb9d9bd7ba34401e9c30df77f171da6fbdb9acf16601d6b822c0f8ebb4e6fb34c;
    bytes32 internal constant tornadoCliMinifiedDomainNode = 0x8994773ddc1fa2e11e4b86dbe1e0905f8744bfe12d9760cd781b4b836b946d8b;
    bytes32 internal constant websnarkPackageDomainNode = 0x09a48ede99da7705e43c9fde7ec88ffb4fb61c77b8adb3a682f3d16849d708da;
    bytes32 internal constant circomlibPackageDomainNode = 0xc49cefe6742a807155aeb894fb982bef5ac0b7c64fcb383d4b54e7408dbf3e74;
    bytes32 internal constant snarkjsPackageDomainNode = 0xa5981a1a101fb57b405ec65007bfcc2d966f0cea15fa5720d288db7edb08160c;
    bytes32 internal constant tornadoOraclesPackageDomainNode = 0xa25976ac1e06a4cd62256c85d7eeb4721e011881d831a5fdf213b640e8c6ab0f;
    bytes32 internal constant gasPriceOraclePackageDomainNode = 0xb1eb7029ca628d908ee8f8de858985817e7d3003c8cb2c24d353822b7dde96f2;
    bytes32 internal constant tornadoConfigPackageDomainNode = 0xcb97b63094a6ffae96dca34ba12a51d9d4bce5c805dcbcc9f96267acc80c56b0;
    bytes32 internal constant anonymityMiningPackageDomainNode = 0x246e925f01d12a5dd0240023bebf85db3d64345941bfd5a0a1eb391cabfe04b0;
    bytes32 internal constant tornadoTreesPackageDomainNode = 0xde4753a77b1a26aa43bac29de191be4a48ed63b4d2232e91754cfe08bbf758ae;
    bytes32 internal constant fixedMerkleTreePackageDomainNode = 0x6f21b84dba16087fcd3620e24e632716a38eb0e39513bf540818bf2d5edea44e;
    bytes32 internal constant txManagerPackageDomainNode = 0xedb16516abf2f454740bab0349fc287887cc4395eb691873a6f4533ae5c5913a;
    bytes32 internal constant merkleRootUpdaterPackageDomainNode = 0xb4d53f6fa2f2ca1006da4c94cd391b54d98eacdf09bef972e0146e8735b21c4f;

    bytes32 internal constant rootTornadoDomainLabelhash = 0xe5b71d8431579082519dd1ae04b9f23df1cecbfd6f54a6cd9ae12eb0ab7f96f3;
    bytes32 internal constant sourcesDomainLabelhash = 0x6ee89d35dcb4b9803f51dc5e513c1c1714149cf0821537078d8ad61616e49f2b;
    bytes32 internal constant minifiedSourcesDomainLabelhash = 0x26403be8dc5694ba56b8d49945b813cff19140637d1fa38a3187a07faf4ee073;
    bytes32 internal constant packagesDomainLabelhash = 0x89c4c51c9264344cbc2ab3aa255b085918a2841af8ffaa3133ceabee961afffd;
    bytes32 internal constant downloadScriptSourceDomainLabelhash = 0xedb311f245ef85f918a5790470448cf17c7d06961f4dfa42cc41616de7f8c2e1;
    bytes32 internal constant classicUISourceDomainLabelhash = 0x4e27b2a330e4a0d8d8521393df67e9a24fb2ab5f10f9e640c244d504874322bc;
    bytes32 internal constant novaUISourceDomainLabelhash = 0xc90e7e9184dce6e0d7fff2e19e72ffa35430aca54bd634ada091bef2d2bb0635;
    bytes32 internal constant docsSourceDomainLabelhash = 0x6bf9054545420e9e9f4aa4f353a32c7d0d52c11dbcdda56c53be8375cafeebb1;
    bytes32 internal constant relayersUISourceDomainLabelhash = 0xea7c97223b0629f1c3bea11a57dd6179a12e9cc4bbdf8f69fb999c4051c682cf;
    bytes32 internal constant tornTokenSourceDomainLabelhash = 0x5d8fec99a5792d7772f788343c7991bf1049b821dcd1b0b900f86e6b7fe7fb25;
    bytes32 internal constant classicRelayerSoftwareSourceDomainLabelhash =
        0x7bece1009df269e16c3552ea6ced49b1d66c22438cda5caf73f55ac74bcadea9;
    bytes32 internal constant novaRelayerSoftwareSourceDomainLabelhash = 0xe01bed58384f9ee9a9dccf26a4236eca42aa8b767efe27c5d191a51885118e5b;
    bytes32 internal constant tornadoCliSourceDomainLabelhash = 0x92c0fea2a18f1747f48f5503806e5f24d5ccb2c360ef56a462ce254707afa64a;
    bytes32 internal constant infoPageSourceDomainLabelhash = 0x41c8b7e0e9650ab5d1f55454c8ad68d9d4c6d42f1a8a14878b77e92e9794e610;
    bytes32 internal constant classicUIMinifiedDomainLabelhash = 0x4e27b2a330e4a0d8d8521393df67e9a24fb2ab5f10f9e640c244d504874322bc;
    bytes32 internal constant novaMinifiedDomainLabelhash = 0xc90e7e9184dce6e0d7fff2e19e72ffa35430aca54bd634ada091bef2d2bb0635;
    bytes32 internal constant tornadoCliMinifiedDomainLabelhash = 0x92c0fea2a18f1747f48f5503806e5f24d5ccb2c360ef56a462ce254707afa64a;
    bytes32 internal constant websnarkPackageDomainLabelhash = 0x50d1752a9b1f31ebf05378927a112194d33596cc02a04c06970477bd8a40c931;
    bytes32 internal constant circomlibPackageDomainLabelhash = 0x68dc231d08143bcf7cf261e63071bdcb7d606e41dec696e34482f6d1068c4afa;
    bytes32 internal constant snarkjsPackageDomainLabelhash = 0x31df71a9eb77699aba0f0e6d565af942889afef76e60ee8a9f80c27f2e946065;
    bytes32 internal constant tornadoOraclesPackageDomainLabelhash = 0xb7a48206cd37ed309fdcdf62fe4b65d6871298645d5e41942f0cd89c08a65cbf;
    bytes32 internal constant gasPriceOraclePackageDomainLabelhash = 0x05048648c60bebc220ad5a82188a966f910539a7e1947cc8a9ac0ec1cd99ca40;
    bytes32 internal constant tornadoConfigPackageDomainLabelhash = 0x0b49c88cd3d1ba3c99fdd9a41ced95ec8629bda85e80b6c506c15db62ab8f761;
    bytes32 internal constant anonymityMiningPackageDomainLabelhash = 0xc3520c36e06133299b24abf819a008b22bc3e9adfa39a38bbccd5cf829831d48;
    bytes32 internal constant tornadoTreesPackageDomainLabelhash = 0xef1496a9cbb93e123ce8e3a0868374bda8446faafa4c2eb7fce3c7a9465be8df;
    bytes32 internal constant fixedMerkleTreePackageDomainLabelhash = 0x37441881d8c14192cbe636eb3d4318346c6af80d92971e1357419a1a94e8a2e2;
    bytes32 internal constant txManagerPackageDomainLabelhash = 0x0d3be7866f858f24a43fd40d3844a410405b3d6abd2255102d8327fa242a4ff3;
    bytes32 internal constant merkleRootUpdaterPackageDomainLabelhash = 0x1b162702ef4549cb2e6522252d90c0d44fcce15b939897373cfa4f829488cab4;

    function executeProposal() public {
        // Register all subnodes, set Governance as an owner
        ensRegistry.setSubnodeRecord(rootTornadoDomainNode, sourcesDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, minifiedSourcesDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, packagesDomainLabelhash, governanceAddress, ensResolverAddress, 0);

        ensRegistry.setSubnodeRecord(sourcesDomainNode, downloadScriptSourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);

        ensRegistry.setSubnodeRecord(sourcesDomainNode, classicUISourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, novaUISourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, docsSourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, relayersUISourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, tornTokenSourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, novaRelayerSoftwareSourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(
            sourcesDomainNode, classicRelayerSoftwareSourceDomainLabelhash, governanceAddress, ensResolverAddress, 0
        );
        ensRegistry.setSubnodeRecord(sourcesDomainNode, tornadoCliSourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, infoPageSourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);

        ensRegistry.setSubnodeRecord(minifiedSourcesDomainNode, classicUIMinifiedDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(minifiedSourcesDomainNode, novaMinifiedDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(minifiedSourcesDomainNode, tornadoCliMinifiedDomainLabelhash, governanceAddress, ensResolverAddress, 0);

        ensRegistry.setSubnodeRecord(packagesDomainNode, websnarkPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, circomlibPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, snarkjsPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, tornadoOraclesPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, gasPriceOraclePackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, tornadoConfigPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, anonymityMiningPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, tornadoTreesPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, fixedMerkleTreePackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, txManagerPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(packagesDomainNode, merkleRootUpdaterPackageDomainLabelhash, governanceAddress, ensResolverAddress, 0);

        // From data/ensDomainsIPFSContenthashes.txt, calculated via scripts/calculateIPFSContenthashes.ts
        bytes memory downloadInstructionsHtmlContenthash = hex"e30101701220810e2b756845f89793b616c56a0b5ab9689da7f6e7fdf93280d05a0969a4902c";
        bytes memory downloadScriptSourceContenthash = hex"e301017012208d6f8f48d3c2bcb6eaafae3110ad59b5aa2137010d827996ea1b87f39266b4f5";
        bytes memory classicUiSourceContenthash = hex"e30101701220b674829af0777f2b89ed96020184ee6f04f6cfd2eb176ad2b653b1f2a5563d98";
        bytes memory classicRelayerSourceContenthash = hex"e301017012205ad0c59d5fcc60e4866ab37f063480ffa305eb84da143894be5baeff2bb8e931";
        bytes memory novaRelayerSourceContenthash = hex"e30101701220c9106227570ab16e639adb5f05ccde1b367b004f582e0700a00dfb54f914068c";
        bytes memory relayersUiSourceContenthash = hex"e3010170122046847feae11b2774438df322e014e04652fe029ba59b79df90fafba040ba6550";
        bytes memory novaUiSourceContenthash = hex"e30101701220b554eed2a9ba47011b6790ff6d23d0480419de78abf723ea7ada55e1664f5976";
        bytes memory docsSourceContenthash = hex"e30101701220a140c7c35f6f2cc72f77d69b73dbab14ac0ccd6ba611a394282ac29f05b89951";
        bytes memory tornadoCliSourceContenthash = hex"e30101701220cb1d7ca2be9c5d7ddba48d5c2b5bb027359ac4c0cf077327a14c9ffe1db057e6";
        bytes memory infoPageSourceContenthash = hex"e30101701220269c131010a479474d82d7926cc14394d01c41bfb4cda23c26aa3defd65ad4fe";
        bytes memory classicUiMinifiedContenthash = hex"e301017012201cbffa16ff8f8bd88f2600f1826648aead1ad513b2f3b1118ef873db9f2add59";
        bytes memory novaUiMinifiedContenthash = hex"e30101701220f1e9f532b9a96e8d808f983d4471da7c261daeacbd9d8e76f82d04875d5ad9fa";
        bytes memory tornadoCliMinifiedContenthash = hex"e3010170122057be20935fa635689427856a462b288fe353df7b588dcb30ff1b7e6cbffe0d9c";
        bytes memory tornTokenSourceContenthash = hex"e30101701220fdee0b6906de7f60179c44103dc0bfd4600233f3737c48eb2e7279850970fd92";
        bytes memory merkleRootUpdaterPackageContenthash = hex"e301017012204c9d433771e8e97cece783366a16c6cd4357b6fb94c6602a90d98e54c4179a3d";
        bytes memory gasPriceOraclePackageContenthash = hex"e3010170122073e0f65b60d455058aff4fd9b2d0ba2b87f62fb59069433439810dad2d54e615";
        bytes memory tornadoOraclesPackageContenthash = hex"e30101701220968d7fb0c0b8981bc8ec464e27ad2a90ef0dbcf67df5990498d94718fa9c6361";
        bytes memory snarkjsPackageContenthash = hex"e30101701220e5d69d83d296c8623aa1b1ff5f9ddc3242914df2bd5f20c1682f07ee095dc6d4";
        bytes memory websnarkPackageContenthash = hex"e3010170122033fa876a2752cc124fec5c61ebedaf623b42ac50ff348322f8f08183c5aabb8f";
        bytes memory circomlibPackageContenthash = hex"e30101701220663529c784c5702922344a1035884949317cd59a529160cfb4571709df9c7059";
        bytes memory txManagerPackageContenthash = hex"e30101701220952a5880f8b175e2206e7502b9891710876e2c970031616b7ede68ce994dea4b";
        bytes memory fixedMerkleTreePackageContenthash = hex"e30101701220615d9d0986e8fd6a233615d792a70cf5125e188aa82c7493816a5d83c384b924";
        bytes memory tornadoTreesPackageContenthash = hex"e30101701220b8ea77533cc9b2f434bac48d96d8bc48183cc335fd726b8c5edf11dfa36a78dc";
        bytes memory anonymityMiningPackageContenthash = hex"e301017012204f3d3a8f0a8a183261288f6012844f74605fd7813d9adc5200784125fb1f671c";
        bytes memory tornadoConfigPackageContenthash = hex"e301017012202d419e8834b28e8aafabe3dfe39e3d71f2c07c3911c856248a6e6587bfec195a";

        // Set IPFS Cids in ENS subdomain contenthashes
        ensResolver.setContenthash(sourcesDomainNode, downloadInstructionsHtmlContenthash);
        ensResolver.setContenthash(downloadScriptSourceDomainNode, downloadScriptSourceContenthash);
        ensResolver.setContenthash(classicUISourceDomainNode, classicUiSourceContenthash);
        ensResolver.setContenthash(novaUISourceDomainNode, novaUiSourceContenthash);
        ensResolver.setContenthash(docsSourceDomainNode, docsSourceContenthash);
        ensResolver.setContenthash(relayersUISourceDomainNode, relayersUiSourceContenthash);
        ensResolver.setContenthash(tornTokenSourceDomainNode, tornTokenSourceContenthash);
        ensResolver.setContenthash(classicRelayerSoftwareSourceDomainNode, classicRelayerSourceContenthash);
        ensResolver.setContenthash(novaRelayerSoftwareSourceDomainNode, novaRelayerSourceContenthash);
        ensResolver.setContenthash(tornadoCliSourceDomainNode, tornadoCliSourceContenthash);
        ensResolver.setContenthash(infoPageSourceDomainNode, infoPageSourceContenthash);
        ensResolver.setContenthash(classicUIMinifiedDomainNode, classicUiMinifiedContenthash);
        ensResolver.setContenthash(tornadoCliMinifiedDomainNode, tornadoCliMinifiedContenthash);
        ensResolver.setContenthash(websnarkPackageDomainNode, websnarkPackageContenthash);
        ensResolver.setContenthash(circomlibPackageDomainNode, circomlibPackageContenthash);
        ensResolver.setContenthash(novaMinifiedDomainNode, novaUiMinifiedContenthash);
        ensResolver.setContenthash(snarkjsPackageDomainNode, snarkjsPackageContenthash);
        ensResolver.setContenthash(tornadoOraclesPackageDomainNode, tornadoOraclesPackageContenthash);
        ensResolver.setContenthash(gasPriceOraclePackageDomainNode, gasPriceOraclePackageContenthash);
        ensResolver.setContenthash(tornadoConfigPackageDomainNode, tornadoConfigPackageContenthash);
        ensResolver.setContenthash(anonymityMiningPackageDomainNode, anonymityMiningPackageContenthash);
        ensResolver.setContenthash(tornadoTreesPackageDomainNode, tornadoTreesPackageContenthash);
        ensResolver.setContenthash(fixedMerkleTreePackageDomainNode, fixedMerkleTreePackageContenthash);
        ensResolver.setContenthash(txManagerPackageDomainNode, txManagerPackageContenthash);
        ensResolver.setContenthash(merkleRootUpdaterPackageDomainNode, merkleRootUpdaterPackageContenthash);
    }
}
