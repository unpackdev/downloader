// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./ERC173.sol";
import "./ERC1155.sol";

/**
 * @title Jungle by ESCAPEPLAN smart contract
 */
contract Jungle is ERC1155, ERC173, IERC165 {

    address BigNightRecords = 0x590AfC242d692d6B4b9BD8d69783BFb099E8BCf5;

    constructor() ERC1155("Jungle by ESCAPEPLAN", "JNGL") ERC173(BigNightRecords) {
        _mint(BigNightRecords);
    }

    /**
     * @dev ERC165 supports interface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC173).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155Metadata).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
