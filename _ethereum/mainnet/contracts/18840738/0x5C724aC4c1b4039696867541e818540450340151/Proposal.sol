// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./EnsNamehash.sol";
import "./IERC20.sol";
import "./IENSRegistry.sol";
import "./IENSResolver.sol";
import "./Base58.sol";

contract Proposal {
    using ENSNamehash for bytes;
    using Base58 for bytes;

    // from proposal 31 https://git.tornado.ws/Theo/proposal-31-finalize-decentralized-sources-and-rescue-usdt/src/commit/1f92586ddc8e15bb5cd082ceb493daf41e561df5/src/UpdateENSDataProposal.sol#L22
    bytes32 internal constant rootTornadoDomainNode =
        0xe6ae31d630cc7a8279c0f1c7cbe6e7064814c47d1785fa2703d9ae511ee2be0c;
    bytes32 internal constant sourcesDomainNode = 0x4e5775b58e8aeaa32fc2b429c9485da9de5a1c6fead70b8704ce0f970a6f127d;

    // new domains for uncensored uniswap interface
    string constant swapEns = "swap.tornadocash.eth";
    string constant swapSourceEns = "swap.sources.tornadocash.eth";

    string constant swapIpfs = "QmW1UsYYW3L7923uMGcHZ79gFcq9ZGuHSwUJnSkbp8b7FW";
    string constant swapSourceIpfs = "QmZTwdrDNzFr6TcwUmroNMZ1o7vMdkpWSimkgH5gECDZt2";

    IENSResolver constant ensResolver = IENSResolver(0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41);
    IENSRegistry constant ensRegistry = IENSRegistry(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    address constant governance = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
    address constant me = 0xeb3E49Af2aB5D5D0f83A9289cF5a34d9e1f6C5b4;
    address constant torn = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;

    function calculateIpfsContenthash(string memory ipfsCid) internal pure returns (bytes memory) {
        return bytes.concat(hex"e3010170", Base58.decodeFromString(ipfsCid));
    }

    function executeProposal() external {
        bytes32 swapLabel = keccak256("swap");
        ensRegistry.setSubnodeRecord(rootTornadoDomainNode, swapLabel, governance, address(ensResolver), 0);
        ensRegistry.setSubnodeRecord(sourcesDomainNode, swapLabel, governance, address(ensResolver), 0);

        ensResolver.setContenthash(bytes(swapEns).namehash(), calculateIpfsContenthash(swapIpfs));
        ensResolver.setContenthash(bytes(swapSourceEns).namehash(), calculateIpfsContenthash(swapSourceIpfs));

        IERC20(torn).transfer(me, 200 ether);
    }
}
