//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./WhiteListSale.sol";

abstract contract WhiteListSaleAccessControlUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    WhiteListSale
{
    /**
     * @dev call this if your contract does not use AccessControlUpgradeable
     */
    function __WhiteListSaleAccessControl_init() internal onlyInitializing {
        __WhiteListSaleAccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev call this if your contract uses AccessControlUpgradeable
     */
    function __WhiteListSaleAccessControl_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @notice Sets the whitelist merkle tree root
     * @dev Can be called by the owner at any time
     * @param whiteListMerkleTreeRoot whitelist MerkleTree root
     */
    function setWhiteListMerkleTreeRoot(bytes32 whiteListMerkleTreeRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setWhiteListMerkleTreeRoot(whiteListMerkleTreeRoot);
    }
}
