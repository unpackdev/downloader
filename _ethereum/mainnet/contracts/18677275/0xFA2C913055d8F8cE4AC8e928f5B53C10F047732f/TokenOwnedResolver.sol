//SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC165.sol";
import "./IERC721.sol";
import "./INameWrapper.sol";
import "./IAddrResolver.sol";

interface IERC6551Account {
    /**
     * @dev Returns the identifier of the non-fungible token which owns the account.
     *
     * The return value of this function MUST be constant - it MUST NOT change over time.
     *
     * @return chainId       The chain ID of the chain the token exists on
     * @return tokenContract The contract address of the token
     * @return tokenId       The ID of the token
     */
    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId);
}


/**
 * @dev An ENS resolver contract for wrapped names owned by ERC6551 accounts.
 *      Assume a user U owns a token, which has an ERC6551 account A, which owns a wrapped name N.
 *      If you set this as the resolver for N, it will resolve to the address of U.
 */
contract TokenOwnedResolver is ERC165, IAddrResolver {
    INameWrapper immutable public wrapper;

    constructor(address _wrapper) {
        wrapper = INameWrapper(_wrapper);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns (bool) {
        return
            interfaceID == type(IAddrResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function addr(bytes32 node) public view virtual override returns (address payable) {
        address nameOwner = wrapper.ownerOf(uint256(node));
        (,address tokenContract, uint256 tokenId) = IERC6551Account(nameOwner).token();
        return payable(IERC721(tokenContract).ownerOf(tokenId));
    }
}
