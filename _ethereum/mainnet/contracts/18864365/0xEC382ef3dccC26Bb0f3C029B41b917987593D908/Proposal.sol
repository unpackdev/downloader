// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./EnsNamehash.sol";
import "./IERC20.sol";
import "./IENSResolver.sol";
import "./Base58.sol";

contract Proposal {
    using ENSNamehash for bytes;
    using Base58 for bytes;

    string constant mainEns = "tornadocash.eth";
    string constant mainSourceEns = "classic-ui.sources.tornadocash.eth";
    string constant uiIpfs = "QmNqVxKyNp9wcNAN68raNqvTKnnfrjKxvSC6gM2nJn61Lp";
    string constant uiSourceIpfs = "QmVuPi7eXyrF1sZBpXEoZtBmBP7xD1Tx54cdhzfzP64zR4";

    IENSResolver constant ensResolver = IENSResolver(0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41);
    address constant me = 0xeb3E49Af2aB5D5D0f83A9289cF5a34d9e1f6C5b4;
    address constant torn = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;

    function calculateIpfsContenthash(string memory ipfsCid) internal pure returns (bytes memory) {
        return bytes.concat(hex"e3010170", Base58.decodeFromString(ipfsCid));
    }

    function executeProposal() external {
        ensResolver.setContenthash(bytes(mainEns).namehash(), calculateIpfsContenthash(uiIpfs));
        ensResolver.setContenthash(bytes(mainSourceEns).namehash(), calculateIpfsContenthash(uiSourceIpfs));

        IERC20(torn).transfer(me, 100 ether);
    }
}
