//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./EIP712Upgradeable.sol";
import "./IERC4494Upgradeable.sol";

/// @dev OpenZeppelin's ERC721Upgradeable extended with EIP-4494-compliant permits
/// @notice Based on the reference implementation of the EIP-4494
/// @notice See https://github.com/dievardump/erc721-with-permits and https://eips.ethereum.org/EIPS/eip-4494
abstract contract ERC721WithPermitUpgradable is
    IERC4494Upgradeable,
    Initializable,
    EIP712Upgradeable,
    ERC721Upgradeable
{
    /// @dev value is equal to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH = 0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    mapping(uint256 => uint256) private _nonces;

    function __ERC721WithPermitUpgradable_init(
        string calldata name_,
        string calldata symbol_
    ) internal onlyInitializing {
        __EIP712_init_unchained(name_, "1");
        __ERC721_init_unchained(name_, symbol_);
    }

    /// @notice Builds the DOMAIN_SEPARATOR (eip712) at time of use
    /// @dev This is not set as a constant, to ensure that the chainId will change in the event of a chain fork
    /// @return the DOMAIN_SEPARATOR of eip712
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @notice Allows to retrieve current nonce for token
    /// @param tokenId token id
    /// @return current token nonce
    function nonces(uint256 tokenId) public view override returns (uint256) {
        require(_exists(tokenId), "!UNKNOWN");
        return _nonces[tokenId];
    }

    /// @notice function to be called by anyone to approve `spender` using a Permit signature
    /// @dev Anyone can call this to approve `spender`, even a third-party
    /// @param spender_ the actor to approve
    /// @param tokenId_ the token id
    /// @param deadline_ the deadline for the permit to be used
    /// @param signature_ permit
    function permit(address spender_, uint256 tokenId_, uint256 deadline_, bytes memory signature_) external override {
        require(deadline_ >= block.timestamp, "EXPRIED");

        bytes32 digest = _buildDigest(spender_, tokenId_, _nonces[tokenId_], deadline_);

        (address recoveredAddress, ) = ECDSAUpgradeable.tryRecover(digest, signature_);
        require((recoveredAddress != address(0) && _isApprovedOrOwner(recoveredAddress, tokenId_)), "!PERMIT");

        _approve(spender_, tokenId_);
    }

    /// @notice Builds the permit digest to sign
    /// @param spender_ the token spender
    /// @param tokenId_ the tokenId
    /// @param nonce_ the nonce to make a permit for
    /// @param deadline_ the deadline before when the permit can be used
    /// @return the digest (following eip712) to sign
    function _buildDigest(
        address spender_,
        uint256 tokenId_,
        uint256 nonce_,
        uint256 deadline_
    ) private view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, spender_, tokenId_, nonce_, deadline_));
        return _hashTypedDataV4(structHash);
    }

    /// @dev helper to easily increment a nonce for a given tokenId
    /// @param tokenId the tokenId to increment the nonce for
    function _incrementNonce(uint256 tokenId) internal {
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _nonces.slot)
            let key := keccak256(0x00, 0x40)
            sstore(key, add(sload(key), 1))
        }
    }

    /// @dev _transfer override to be able to increment the nonce
    /// @inheritdoc ERC721Upgradeable
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual override {
        // increment the nonce to be sure it can't be reused
        _incrementNonce(tokenId_);

        // do normal transfer
        super._transfer(from_, to_, tokenId_);
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Overridden from ERC721 here in order to include the interface of this EIP
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC4494Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    // Reserved storage space to allow for layout changes in the future.
    // solhint-disable-next-line ordering
    uint256[47] private __gap;
}
