// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./CBWCBase.sol";
import "./ICBWCPieces.sol";
import "./ECDSAUpgradeable.sol";

/// @title Crypto Bear Watch Club Watch
/// @author Kfish n Chips
/// @notice ERC721 Watch Watch to be forged by CBWC holders
/// @dev pieces needed to forge a Watch are managed at the backend
/// @custom:security-contact security@kfishnchips.com
contract CBWCWatch is CBWCBase {
    using ECDSAUpgradeable for bytes32;

    /// @notice CBWCPieces contract
    ICBWCPieces public cbwcPieces;

    // @notice Role assigned by DEFAULT_ADMIN_ROLE with access to burn
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /// Array of unique string used to prevent signature hijacking
    mapping(string => bool) private nonces;

    /// @notice Emitted when CBWCPieces contract change
    /// @dev only DEFAULT_ADMIN_ROLE can perform this action
    /// @param sender address with the role of DEFAULT_ADMIN_ROLE
    /// @param previousCBWCPieces previous contract address
    /// @param cbwcPieces new contract address
    event CBWCPiecesChanged(
        address indexed sender,
        address previousCBWCPieces,
        address cbwcPieces
    );

    /// @notice Emitted when a Watch is forged
    /// @dev only DEFAULT_ADMIN_ROLE can perform this action
    /// @param sender address with the role of DEFAULT_ADMIN_ROLE
    /// @param tokenId address with the role of DEFAULT_ADMIN_ROLE
    /// @param cbwcPiecesTokenIds Array of CBWC Pieces token ids used in forge
    event WatchForged(
        address indexed sender,
        uint256 indexed tokenId,
        uint256[] cbwcPiecesTokenIds
    );

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    function initialize() external initializer {
        __CBWCBase_init(
            "CBWCWatch",
            "CBWCW",
            "https://cryptobearwatchclub.mypinata.cloud/ipfs/QmRBA1ikWecB6CeKLT6HDybxTVk9XkwhbS6g2Sew5BLBoG",
            "https://api.cbwc.io/watches/metadata/"
        );
        _grantRole(SIGNER_ROLE, 0xc86bb6F67cf5e898986c43E389B32114F72cBc38);
    }

    /// @notice Mints multiple tokens to `recipients_`.
    /// @dev pieces needed to forge are checked in backend
    /// @param cbwcPiecesTokenIds_ Array of CBWC Pieces token ids for forge
    /// @param nonce_ Unique string used to prevent signature hijacking
    /// @param deadline_ Deadline in which the signature must be used
    /// @param signature_ Signature from the address with SIGNER_ROLE to verify the payload
    /// Emits a {WatchForged} event
    function forge(
        uint256[] calldata cbwcPiecesTokenIds_,
        string calldata nonce_,
        uint256 deadline_,
        bytes calldata signature_
    ) external {
        _mint(msg.sender, 1);
        _isValidSignature(signature_, nonce_, deadline_, cbwcPiecesTokenIds_);

        cbwcPieces.burnPieces(cbwcPiecesTokenIds_, msg.sender);

        emit WatchForged(msg.sender, _nextTokenId - 1, cbwcPiecesTokenIds_);
    }

    /// @notice Set CBWCPieces contract address
    /// @param cbwcPieces_ The new CBWC pieces address
    /// Emits a {CBWCPiecesChanged} event
    function setCBWCPieces(address cbwcPieces_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(cbwcPieces_ != address(0), "CBWCW: cannot set address zero");

        ICBWCPieces previousCBWCPieces = cbwcPieces;
        cbwcPieces = ICBWCPieces(cbwcPieces_);

        emit CBWCPiecesChanged(msg.sender, address(previousCBWCPieces), cbwcPieces_);
    }

    /// @notice Check a valid Signature
    /// @param signature_ Signature from the address with SIGNER_ROLE to verify the payload
    /// @param nonce_ Unique string used to prevent signature hijacking
    /// @param deadline_ Deadline in which the signature must be used
    /// @param cbwcPiecesTokenIds_ Array of CBWC Pieces token ids for forge
    function _isValidSignature(
        bytes calldata signature_,
        string calldata nonce_,
        uint256 deadline_,
        uint256[] calldata cbwcPiecesTokenIds_
    ) internal {
        bytes32 msgHash = keccak256(abi.encodePacked(cbwcPiecesTokenIds_, nonce_, deadline_));
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        require(!nonces[nonce_], "CBWCW: nonce already used");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < deadline_, "CBWCW: tx deadline missed");
        require(hasRole(SIGNER_ROLE, (signedHash.recover(signature_))));
        nonces[nonce_] = true;
    }
}
