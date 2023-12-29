// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC1155.sol";

/**
 * @title Access Pass
 */
contract APToken is ERC1155, ERC2981, AccessControl, Ownable {
    /// @notice Role that can mint tokens
    bytes32 public constant PRIVATE_MINTER_ROLE =
        keccak256("PRIVATE_MINTER_ROLE");

    /// @notice Role that can burn tokens
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @dev Same category for all holders
    uint256 public immutable CATEGORY = 1;

    /// @notice Name of the token
    string public name;

    /// @notice Symbol of the token
    string public symbol;

    /// @notice OpenSea standard to update metadata
    event MetadataUpdate(uint256 _tokenId);

    /**
     * @notice 'msg.sender' gets the Admin role. Royalty value is set to 5%.
     */
    constructor(string memory _uri, address _royaltyReceiver) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(_royaltyReceiver, 500);
        name = "HUXLEY Codec";
        symbol = "CODEC";
    }

    /**
     * @dev It mints 1 AccessPass Token calling `_mint()` from ERC1155 OpenZeppelin implementation.
     * To be called by another smart contract or wallet with the PRIVATE_MINTER_ROLE role.
     *
     * It has a fixed category/tokenId equal to 1.
     *
     * @param _account Token owner address - cannot be the zero address.
     * @param _amount Amount to mint
     */
    function privateMint(
        address _account,
        uint256 _amount
    ) external onlyRole(PRIVATE_MINTER_ROLE) {
        _mint(_account, CATEGORY, _amount, "");
    }

    /**
     * Burns a certain amount of tokens from CATEGORY 1.
     *  - It doesn't revert if wallet tries to burn 0 tokens
     *  - It reverts if tries to burn over its balance
     *  - Burner must verify token ownership first before burning tokens from a wallet
     *
     * @param _account Account to burn tokens
     * @param _amount Amount to burn
     */
    function burnBatch(
        address _account,
        uint256 _amount
    ) external onlyRole(BURNER_ROLE) {
        _burn(_account, CATEGORY, _amount);
    }

    /**
     * @dev Sets a new URI for all token categories. Only Admin can call it
     */
    function setURI(
        string memory _newuri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(_newuri);
    }

    /**
     * Emits an event so Marketplaces can detect metadata were updated. Token id is fixed.
     */
    function updateMetadata() external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit MetadataUpdate(CATEGORY);
    }

    /// @dev IP Licenses
    function IPLicensesIncluded() external pure returns (string memory) {
        return "Personal Use, Commercial Display, Merchandising";
    }

    /**
     * Sets a new receiver and/or new royalty value
     * @param receiver Address that will receiver royalty
     * @param numerator New royalty value
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 numerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC2981._setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
