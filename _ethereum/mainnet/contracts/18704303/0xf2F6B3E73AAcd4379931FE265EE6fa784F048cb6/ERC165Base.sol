// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./IERC165.sol";
import "./IERC165Base.sol";
import "./ERC165BaseInternal.sol";
import "./ERC165BaseStorage.sol";

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public virtual view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}
