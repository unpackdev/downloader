// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./StringsUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./FWBMembershipSkeletonNFT.sol";
import "./draft-EIP712Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

// FWB Core membership contract (Updatable)
contract FWBMembershipNFT is
    OwnableUpgradeable,
    FWBMembershipSkeletonNFT,
    EIP712Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant NFT_MANAGER_ROLE = keccak256("NFT_MANAGER_ROLE");

    /// @notice URLBase for metadata
    string public urlBase;

    /// @notice Upgradeable init fn
    function initialize(string memory _urlBase, address admin)
        public
        initializer
    {
        __EIP712_init("FWBMembershipNFT", "1");
        __UUPSUpgradeable_init();
        __ERC165_init();
        __AccessControl_init();
        _grantRole(AccessControlUpgradeable.DEFAULT_ADMIN_ROLE, admin);

        urlBase = _urlBase;
    }

    /**
        Admin permission functions and modifiers
     */

    /// @notice UUPS admin upgrade permission fn
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // only owner/admin can upgrade contract
    }

    /**
        URI Management tools
     */

    /// @notice admin function to update base uri
    function updateUrlBase(string memory newUrlBase)
        external
        onlyRole(NFT_MANAGER_ROLE)
    {
        urlBase = newUrlBase;
    }

    /// @notice Getter for url server nft base
    function tokenURI(uint256 id) external view returns (string memory) {
        require(_exists(id), "ERC721: Token does not exist");
        return
            string(abi.encodePacked(urlBase, StringsUpgradeable.toString(id)));
    }

    /// @notice Admin function to revoke membership for user
    function adminRevokeMemberships(uint256[] memory ids)
        external
        onlyRole(NFT_MANAGER_ROLE)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            _burn(ids[i]);
        }
    }

    function burn(uint256 id) external {
        require(msg.sender == ownerOf(id), "NFT Burn: needs to be owner");
        _burn(id);
    }

    /// @notice Admin function to transfer a wallet to a new NFT address
    function transferFrom(
        address from,
        address to,
        uint256 checkTokenId
    ) external override onlyRole(NFT_MANAGER_ROLE) {
        uint256 tokenId = addressToId[from];
        require(checkTokenId == tokenId, "ERR: Token ID mismatch");

        _transferFrom(from, to, tokenId);
    }

    /// Mint mew membership from the manager role
    function adminMint(address to, uint256 id)
        external
        onlyRole(NFT_MANAGER_ROLE)
    {
        _safeMint(to, id);
    }

    /// @notice list of used signature nonces
    mapping(uint256 => bool) public usedNonces;

    /// @notice modifier for valid nonce with signature-based call
    modifier withValidNonceAndDeadline(uint256 nonce, uint256 deadline) {
        require(block.timestamp <= deadline, "Deadline time passed");
        require(!usedNonces[nonce], "nonce used");
        usedNonces[nonce] = true;
        _;
    }

    modifier needsRole(bytes32 role, address account) {
        _checkRole(role, account);
        _;
    }

    /// @notice signature permitted mint function typehash
    bytes32 private immutable _PERMIT_MINT_TYPEHASH =
        keccak256(
            "PermitMint(address signer,address to,uint256 tokenId,uint256 deadline,uint256 nonce)"
        );

    /// @notice Mint with signed message data
    function mintWithSign(
        address signer,
        address to,
        uint256 tokenId,
        uint256 deadline,
        uint256 nonce,
        bytes memory signature
    )
        external
        withValidNonceAndDeadline(nonce, deadline)
        needsRole(SIGNER_ROLE, signer)
    {
        // We allow any user to execute a signature to mint the NFt.
        require(to == msg.sender, "Needs to be receiving wallet");

        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                // signer is the signer
                signer,
                _hashTypedDataV4(
                    keccak256(
                        abi.encode(
                            _PERMIT_MINT_TYPEHASH,
                            signer,
                            to,
                            tokenId,
                            deadline,
                            nonce
                        )
                    )
                ),
                signature
            ),
            "NFTPermit::mintWithSign: Invalid signature"
        );

        _safeMint(to, tokenId);
    }

    bytes32 private immutable _PERMIT_TRANSFER_TYPEHASH =
        keccak256(
            "PermitTransfer(address signer,address from,address to,uint256 tokenId,uint256 deadline,uint256 nonce)"
        );

    /// @notice Transfer with signed message data
    function transferWithSign(
        address signer,
        address from,
        address to,
        uint256 tokenId,
        uint256 deadline,
        uint256 nonce,
        bytes memory signature
    )
        external
        withValidNonceAndDeadline(nonce, deadline)
        needsRole(SIGNER_ROLE, signer)
    {
        require(to == msg.sender, "Needs to be receiving wallet");

        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                signer,
                _hashTypedDataV4(
                    keccak256(
                        abi.encode(
                            _PERMIT_TRANSFER_TYPEHASH,
                            signer,
                            from,
                            to,
                            tokenId,
                            deadline,
                            nonce
                        )
                    )
                ),
                signature
            ),
            "NFTPermit::transferWithSign: Invalid signature"
        );

        _transferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(FWBMembershipSkeletonNFT, AccessControlUpgradeable)
        returns (bool)
    {
        return
            FWBMembershipSkeletonNFT.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}
