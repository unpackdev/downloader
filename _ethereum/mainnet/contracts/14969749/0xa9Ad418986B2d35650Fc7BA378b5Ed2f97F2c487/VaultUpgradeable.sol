// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC1155PausableUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./Supply.sol";
import "./SignatureAccessControlUpgradeable.sol";

import "./IVault.sol";

/**
 * @dev Alt Vault
 *
 * Minting and Burning Alt vaulted cards cannot be achieved through this contract. Rather, we implement minter contracts
 * along with {MINTER_ROLE} for minter contracts.
 *
 * @dev Alt Vault registers all Alt minted tokens and acts as a gate keeper to ensure the security around minting/burning.
 *  Different minter contracts can be implemented to provide different minting experiences depending on the use case
 *
 * The Vault is pausable by Alt Admin through DEFAULT_ADMIN_ROLE in case of emergency.
 */
contract VaultUpgradeable is ERC1155PausableUpgradeable, SignatureAccessControlUpgradeable, Supply, IVault {
    using StringsUpgradeable for uint256;

    /* ================================================ VAULT VARIABLES ================================================ */

    string private _baseUri;

    string public name;

    /* ================================================ VAULT INITIALIZER ================================================ */

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the admin
     *
     * Initialize the baseUri, the name, the admin and the default maximum supply of the Vault
     */
    function initialize(
        string memory baseUri_,
        string memory name_,
        address admin_,
        uint256 defaultMaxSupply_,
        address _signingAddress
    ) external initializer {
        _SignatureAccessControlUpgradeable_init(_signingAddress);

        _baseUri = baseUri_;
        name = name_;

        _setDefaultMaxSupply(defaultMaxSupply_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /**
     * ======================================== TOKEN ID & PROOF OF INTEGRITY ========================================
     *
     * A token's Proof of Integrity is a 32 bytes hex value, which translates to a uint256 in a deterministic way.
     * This method saves about 27% in gas fees by using a direct translation {tokenId} <> {proofOfIntegrity}, rather
     * than storing the two attributes separately on chain.
     */

    /**
     * @dev {proofOfIntegrity} => {tokenId}.
     */
    function _tokenId(bytes32 proofOfIntegrity) private pure returns (uint256) {
        return uint256(proofOfIntegrity);
    }

    /**
     * @dev {tokenId} => {proofOfIntegrity}.
     */
    function _proofOfIntegrity(uint256 tokenId) private pure returns (bytes32) {
        return bytes32(tokenId);
    }

    /**
     * @dev {tokenId} => {proofOfIntegrity} as a hex string.
     */
    function _proofOfIntegrityAsHexString(uint256 tokenId)
        private
        pure
        returns (string memory)
    {
        return tokenId.toHexString(32);
    }

    /**
     * @dev get the Proof of Integrity of a particular token.
     * Requirement:
     *      - the token must exist.
     */
    function getProofOfIntegrity(uint256 tokenId) external view returns (bytes32) {
        require(_exists(tokenId), 'VaultUpgradeable: Nonexistent token.');
        return _proofOfIntegrity(tokenId);
    }

    /**
     * @dev get the Proof of Integrity of a particular token as a string.
     * Requirement:
     *      - the token must exist.
     */
    function getProofOfIntegrityAsHexString(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        require(_exists(tokenId), 'VaultUpgradeable: Nonexistent token.');
        return _proofOfIntegrityAsHexString(tokenId);
    }

    /* ================================================ URI HELPERS ================================================ */

    /// @inheritdoc ERC1155Upgradeable
    function uri(uint256 _id)
        public
        view
        virtual
        override(ERC1155Upgradeable, IVault)
        returns (string memory)
    {
        require(_exists(_id), 'VaultUpgradeable: Nonexistent token.');
        return string(abi.encodePacked(_baseUri, '/', _proofOfIntegrityAsHexString(_id)));
    }

    /// @inheritdoc IVault
    function getBaseUri() external view override returns (string memory) {
        return _baseUri;
    }

    /// @inheritdoc IVault
    function setBaseUri(string memory newUri) external override onlyVaultAdmin {
        emit BaseUriChanged(_baseUri, newUri);
        _baseUri = newUri;
    }

    /* ================================================ BEFORE MINT HELPER ================================================ */

    /// @dev Call this before minting to ensure safe mint.
    /// @param id token id to mint
    /// @param amount amount of tokens to mint
    function _beforeMint(uint256 id, uint256 amount) internal view {
        uint256 maxSupply;
        if (_maxSupplyExists(id)) {
            maxSupply = _maxSupply[id];
        }
        else {
            maxSupply = defaultMaxSupply;
        }
        require(
                maxSupply > _currentSupply[id] + amount - 1,
                'VaultUpgradeable: mint amount exceeds max supply'
            );
    }

    /* ================================================ ERC1155 FUNCTIONS  ================================================ */

    /// @inheritdoc IVault
    function mint(
        address to,
        bytes32 proof,
        uint256 amount,
        bytes memory data
    ) external override onlyMinter {
        uint256 id = _tokenId(proof);
        _beforeMint(id, amount);
        _mint(to, id, amount, data);
    }

    /// @inheritdoc IVault
    function mintBatch(
        address to,
        bytes32[] memory proofs,
        uint256[] memory amounts,
        bytes memory data
    ) external override onlyMinter {
        uint256[] memory ids = new uint256[](amounts.length);
        for (uint256 i = 0; i < amounts.length; ++i) {
            uint256 id = _tokenId(proofs[i]);
            _beforeMint(id, amounts[i]);
            ids[i] = id;
        }

        _mintBatch(to, ids, amounts, data);
    }

    /// @inheritdoc IVault
    function burn(
        bytes32 proof,
        uint256 amount,
        bytes calldata signature
    ) external override {
        address caller = msg.sender;
        require(_hasAccess(caller, signature), 'VaultUpgradeable: This address cannot burn.');
        uint256 id = _tokenId(proof);
        _burn(caller, id, amount);
    }

    /// @inheritdoc IVault
    function burnBatch(
        bytes32[] memory proofs,
        uint256[] memory amounts,
        bytes calldata signature
    ) external override {
        address caller = msg.sender;
        require(_hasAccess(caller, signature), 'VaultUpgradeable: This address cannot burn.');
        uint256[] memory ids = new uint256[](amounts.length);
        for (uint256 i = 0; i < amounts.length; ++i) {
            uint256 id = _tokenId(proofs[i]);
            ids[i] = id;
        }
        _burnBatch(caller, ids, amounts);
    }

    /* ================================================ PAUSER FUNCTIONS  ================================================ */

    /// @inheritdoc IVault
    function pause() external override onlyVaultAdmin {
        _pause();
    }

    /// @inheritdoc IVault
    function unpause() external override onlyVaultAdmin {
        _unpause();
    }

    /* ================================================ MISC HELPERS  ================================================ */

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Before any
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _currentSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 supply = _currentSupply[ids[i]];
                uint256 amount = amounts[i];
                require(
                    supply > amount - 1,
                    'VaultUpgradeable: burn amount exceeds currentSupply'
                );
                unchecked {
                    _currentSupply[ids[i]] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlEnumerableUpgradeable,
            ERC1155Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IVault).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
