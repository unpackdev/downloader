// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";
import "./ERC165Checker.sol";
import "./INFT.sol";

/**
 * An allowlist for tokens
 */
abstract contract TokenAllowlist is AdminControl {
    //
    // Libraries
    //

    using ERC165Checker for address;

    //
    // Structs
    //

    // struct for the unique identifier of a token with contract address and token id
    struct Token {
        uint96 tokenId;
        address contractAddress;
    }

    //
    // Errors
    //

    error ContractWithInvalidInterface();

    //
    // State
    //

    // Array with the contract address and tokenId pair
    Token[] public allowedTokens;

    // boolean to signal if the token allowlist is enabled or not
    bool public tokenAllowlistEnabled;

    //
    //Internal API
    //

    /**
     * if the allowlist is enabled
     * checks if the sender owns one of the
     * allowedlisted tokens
     */
    function ifEnabledCheckTokenAllowlist(address sender)
        internal
        view
        returns (bool)
    {
        return !tokenAllowlistEnabled || isOnTokenAllowlist(sender);
    }

    /**
     * Check if a given address owns one of the
     * allowedlisted Tokens
     */
    function isOnTokenAllowlist(address sender) internal view returns (bool) {
        // query support of each interface in _interfaceIds
        uint256 allowedTokensLength = allowedTokens.length;
        for (uint256 i = 0; i < allowedTokensLength; ++i) {
            Token memory allowedToken = allowedTokens[i];

            // if one is supported returns
            if (
                quantityOf(
                    INFT(allowedToken.contractAddress),
                    allowedToken.tokenId,
                    sender
                ) > 0
            ) {
                return true;
            }
        }

        // no interface supported
        return false;
    }

    /**
     * For a given ERC721 or ERC1155 gives the quantity owned by an address
     * If the address doesn't own one of the token returns 0
     */
    function quantityOf(
        INFT nft,
        uint96 tokenID,
        address potentialOwner
    ) internal view returns (uint256) {
        bytes4[] memory interfaceIds = new bytes4[](2);

        //ERC721 interface
        interfaceIds[0] = bytes4(0x80ac58cd);
        //ERC1155 interface
        interfaceIds[1] = bytes4(0xd9b67a26);

        bool[] memory interfaceIdsSupported = address(nft)
            .getSupportedInterfaces(interfaceIds);

        if (interfaceIdsSupported[0]) {
            address ownerOf = nft.ownerOf(tokenID);

            if (ownerOf == potentialOwner) {
                return 1;
            } else {
                return 0;
            }
        } else if (interfaceIdsSupported[1]) {
            return nft.balanceOf(potentialOwner, tokenID);
        }

        return 0;
    }

    /**
     * Checks if a given address supports one of the interfaces passed to the
     * function
     */
    function supportsOneInterface(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool)
    {
        bool[] memory interfaceIdsSupported = account.getSupportedInterfaces(
            interfaceIds
        );

        for (uint256 i = 0; i < interfaceIdsSupported.length; i++) {
            // if one is supported returns
            if (interfaceIdsSupported[i]) {
                return true;
            }
        }

        // no interface supported
        return false;
    }

    //
    // Queries
    //

    /**
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl)
        returns (bool)
    {
        return AdminControl.supportsInterface(interfaceId);
    }

    //
    // Admin required
    //

    /**
     * Toggle the allowlist on or off depending on its
     * current state
     */
    function toggleTokenAllowlist() external adminRequired {
        tokenAllowlistEnabled = !tokenAllowlistEnabled;
    }

    /**
     * Set the list of Tokens on the allowlist
     */
    function setTokenAllowlist(Token[] calldata _allowedTokens)
        external
        adminRequired
    {
        delete allowedTokens;

        bytes4[] memory interfaces = new bytes4[](2);

        //ERC721 interface
        interfaces[0] = bytes4(0x80ac58cd);
        //ERC1155 interface
        interfaces[1] = bytes4(0xd9b67a26);

        uint256 _allowedTokensLength = _allowedTokens.length;
        for (uint256 i = 0; i < _allowedTokensLength; ++i) {
            address contractAddress = _allowedTokens[i].contractAddress;

            if (!supportsOneInterface(contractAddress, interfaces)) {
                revert ContractWithInvalidInterface();
            }

            allowedTokens.push(_allowedTokens[i]);
        }
    }

    /**
     * Resets the list of Tokens on the allowlist
     */
    function unsetTokenAllowlist() external adminRequired {
        delete allowedTokens;
    }

    /**
     * set the allowlist on or off deterministically
     */
    function setTokenAllowlistStatus(bool status) public adminRequired {
        tokenAllowlistEnabled = status;
    }
}
