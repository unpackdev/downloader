// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetStructsUpgradeable.sol";
import "./AssetEnumsUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./RoleConstantsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./INeatFiProtocolStorage.sol";

/**
 * @title AssetTransferOperationsUpgradeable
 * @author NeatFi
 * @notice This contract holds the internal operations for asset transfer within NeatFi.
 */
contract AssetTransferOperationsUpgradeable is
    AssetEnumsUpgradeable,
    AssetStructsUpgradeable,
    RoleConstantsUpgradeable,
    AccessControlUpgradeable
{
    address internal neatFiProtocolStorage;

    /**
     * @dev Updates the NeatFi Protocol storage address.
     */
    function _updateNeatFiProtocolStorageAddress(
        address newNeatFiProtocolStorage
    ) internal {
        neatFiProtocolStorage = newNeatFiProtocolStorage;
    }

    /**
     * @dev Resolves ownership transfer of Token assets. Loops over the Token
     *      assets of the Order and invokes transfer functions via interfaces.
     * @param order - The Order struct.
     * @param from - The address of the current owner of the asset.
     * @param to - The address of the new owner of the asset.
     */
    function _transferResolver(
        Order memory order,
        address from,
        address to,
        bytes calldata data
    ) internal returns (bool transferResult) {
        for (uint256 i = 0; i < order.tokenHashes.length; i++) {
            Token memory token = INeatFiProtocolStorage(neatFiProtocolStorage)
                .getToken(order.tokenHashes[i]);
            if (token.tokenType == TokenType.ERC721) {
                IERC721(token.tokenContract).safeTransferFrom(
                    from,
                    to,
                    token.tokenId,
                    data
                );
                return true;
            } else if (token.tokenType == TokenType.ERC1155) {
                IERC1155(token.tokenContract).safeTransferFrom(
                    from,
                    to,
                    token.tokenId,
                    token.amount,
                    data
                );
                return true;
            } else if (token.tokenType == TokenType.ERC20) {
                return
                    IERC20(token.tokenContract).transferFrom(
                        from,
                        to,
                        token.amount
                    );
            }
        }
    }

    /** Initializers */

    function __AssetTransferOperations_init(address newNeatFiProtocolStorage)
        internal
        initializer
    {
        __AssetStructs_init();
        __AssetEnums_init();
        __RoleConstants_init();
        __AccessControl_init();

        _updateNeatFiProtocolStorageAddress(newNeatFiProtocolStorage);
    }
}
