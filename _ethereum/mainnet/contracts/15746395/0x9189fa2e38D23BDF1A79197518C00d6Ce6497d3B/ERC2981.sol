// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./ERC2981.sol";

abstract contract ERC2981 is IERC165, IERC2981 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId;
    }
}
