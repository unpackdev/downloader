// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IGovernance.sol";
import "./ITornToken.sol";
import "./IENSRegistry.sol";
import "./IENSResolver.sol";

contract UpdateENSDataProposal {
    address constant usdtTokenAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant tornTokenAddress = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
    address constant governanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
    address payable constant developerAddress = payable(0x9Ff3C1Bea9ffB56a78824FE29f457F066257DD58);

    address constant ensResolverAddress = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
    address constant ensRegistryAddress = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    IENSRegistry internal constant ensRegistry = IENSRegistry(ensRegistryAddress);
    IENSResolver internal constant ensResolver = IENSResolver(ensResolverAddress);

    bytes32 internal constant rootTornadoDomainNode = 0xe6ae31d630cc7a8279c0f1c7cbe6e7064814c47d1785fa2703d9ae511ee2be0c;
    bytes32 internal constant sourcesDomainNode = 0x4e5775b58e8aeaa32fc2b429c9485da9de5a1c6fead70b8704ce0f970a6f127d;
    bytes32 internal constant docsDomainNode = 0xd7b8aac14a9b2507ab99b5fde3060197fddb9735afa9bf38b1f7e34923cb935e;
    bytes32 internal constant relayersUiSiteDomainNode = 0x5d1d6b09c964d7e0f4511d6dc896d8cc8899508fb73a202ecfa80a7f50ae3d8a;
    bytes32 internal constant relayersUiSiteOldDomainNode = 0x4e37047f2c961db41dfb7d38cf79ca745faf134a8392cfb834d3a93330b9108d;
    bytes32 internal constant downloadScriptSourceDomainNode = 0x4a6bb62eaa2524f194a206df4c15dcc8e9a93036119d40516dab5b7c021fa43b;
    bytes32 internal constant ipfsHostHelpScriptSourceDomainNode = 0xb0406167f975c3168de8d385bb5a6c6bd572727ad505e37734e0a6ec54201a75;
    bytes32 internal constant docsSourceDomainNode = 0xdd158a78d03e8c953fe2b54edcf9f9919efaec1d782a6603b3f8f5871107672c;
    bytes32 internal constant relayersUISourceDomainNode = 0x0315c3730f5894b97933d148a24f1b29f823c6a64caadc4a55b5600b510234b2;
    bytes32 internal constant relayerSoftwareSourceNode = 0xedfb4f99b2a0b005fa627cfd899fabc4ca52f23df310c32597fa23c593220877;

    bytes32 internal constant relayersUiSiteDomainLabelhash = 0xea7c97223b0629f1c3bea11a57dd6179a12e9cc4bbdf8f69fb999c4051c682cf;
    bytes32 internal constant ipfsHostHelpScriptSourceDomainLabelhash = 0x0825203969ee8c01895e26a522db220e9541acc7b27e3cb4a1a9317cb0c30bfb;
    bytes32 internal constant relayerSoftwareSourceLabelhash = 0x802cf867c2da464d4ff0ebc4dfcccdfbd65d75a8bc1c273fb02e80bf3446b516;

    function executeProposal() public {
        // Register missing subnodes, set Governance as an owner
        ensRegistry.setSubnodeRecord(rootTornadoDomainNode, relayersUiSiteDomainLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, relayerSoftwareSourceLabelhash, governanceAddress, ensResolverAddress, 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, ipfsHostHelpScriptSourceDomainLabelhash, governanceAddress, ensResolverAddress, 0);

        // From data/ensDomainsIPFSContenthashes.txt, calculated via scripts/calculateIPFSContenthashes.ts
        bytes memory relayersUiSourceContenthash = hex"e3010170122072dd7fe08bc98404c3a2e402dac817562b2533aa549c475e8e85b9a266bc507c";
        bytes memory relayersUiSiteContenthash = hex"e3010170122052a5331f2ff57ce75b2fb48870e2f1f0752d0da2a0d612104028ce5930976adb";
        bytes memory downloadScriptSourceContenthash = hex"e301017012208f759bcffb194cb59161916ee7f1f1d225016f03514b5430d3fb4c5fb254a3bb";
        bytes memory ipfsHostHelpScriptSourceContenthash = hex"e301017012200c8e358709e32756da156639a8aedbf6950090d4e73c2dc6e1c012fe5b78e4e9";
        bytes memory downloadInstructionsHtmlContenthash = hex"e301017012201a9748cd5f0f64c682d309f6af6354944e0d2e572e81c301ea8ce76c11dee1f5";
        bytes memory tornadoRelayerSoftwareSourceContenthash =
            hex"e301017012205d51d0e5b49830f59f91f6a36e44c40d69474078c5e5b41e0df4f23fddd89b13";
        bytes memory docsSourceContenthash = hex"e30101701220a02b6c5846715cae70d0f7a7df09cbc929b5af97d38dd130ffd44aa0adf21daa";
        bytes memory docsSiteContenthash = hex"e30101701220615111f92c8087a46a397f77046d8c0eed57b27fbb9221e4d270307f0fb317a4";

        // Set IPFS Cids in ENS subdomain contenthashes
        ensResolver.setContenthash(sourcesDomainNode, downloadInstructionsHtmlContenthash);
        ensResolver.setContenthash(downloadScriptSourceDomainNode, downloadScriptSourceContenthash);
        ensResolver.setContenthash(relayerSoftwareSourceNode, tornadoRelayerSoftwareSourceContenthash);
        ensResolver.setContenthash(docsSourceDomainNode, docsSourceContenthash);
        ensResolver.setContenthash(relayersUISourceDomainNode, relayersUiSourceContenthash);
        ensResolver.setContenthash(relayersUiSiteDomainNode, relayersUiSiteContenthash);
        ensResolver.setContenthash(relayersUiSiteOldDomainNode, relayersUiSiteContenthash);
        ensResolver.setContenthash(ipfsHostHelpScriptSourceDomainNode, ipfsHostHelpScriptSourceContenthash);
        ensResolver.setContenthash(docsDomainNode, docsSiteContenthash);

        ITorn(tornTokenAddress).rescueTokens(usdtTokenAddress, developerAddress, 0);
    }
}
