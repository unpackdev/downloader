// SPDX-License-Identifier: MIT
/**
    @author 0xMaster
 */

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./draft-EIP712.sol";
import "./ERC1967Proxy.sol";

import "./ERC721L.sol";

contract AlienInfinityProxy is ERC1967Proxy, Ownable{
    using Strings for uint256;

    constructor(address _logic, bytes memory _data)
        ERC1967Proxy(_logic, _data)
    {
    }

    function getImplementation() public view returns (address) {
        return _implementation();
    }
}
