// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./Address.sol";
import "./ProjectProxy.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//    @@@@@@@@@@@@@@@    @@@@@@@@@      @@@                           @@                 //
//          @@@        @@       &@@@    @@@                           @@                 //
//          @@@        @@         @@@   @@@            @@@@@@@@@@     @@  ,@@@@@@@       //
//          @@@        @@       @@@@    @@@          @@@&        @@   @@        @@@@     //
//          @@@        @@@@@@@@@@@      @@@          @@          @@   @@          @@     //
//          @@@        @@      @@@      @@@          @@@        @@@   @@         @@@     //
//          @@@        @@        @@@    @@@@@@@@@@@@  @@@@@@@@@@ @@   @@@@@@@@@@@@       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////

/**
 * @dev ERC721Project Upgradeable Proxy
 */
contract ERC721ProjectProxyV2 is ProjectProxy {
    constructor(
        address _impl,
        address treasury,
        address signer,
        string memory name,
        string memory symbol,
        string memory contractUri
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        upgradeToAndCall(_impl, abi.encodeWithSignature("initialize(address,address,string,string,string)", treasury, signer, name, symbol, contractUri));
    }
}
