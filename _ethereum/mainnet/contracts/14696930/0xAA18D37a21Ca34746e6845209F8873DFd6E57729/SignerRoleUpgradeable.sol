// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./LibRoles.sol";

abstract contract SignerRoleUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using LibRoles for LibRoles.Role;
    using ECDSAUpgradeable for bytes32;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    LibRoles.Role private _signers;

    function __SignerRole_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __SignerRole_init_unchained();
    }

    function __SignerRole_init_unchained() internal initializer {
        _addSigner(_msgSender());
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public virtual onlyOwner {
        _addSigner(account);
    }

    function removeSigner(address account) public virtual onlyOwner {
        _removeSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(_msgSender());
    }

    function _verifySignedMessage(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        return isSigner(messageHash.toEthSignedMessageHash().recover(v, r, s));
    }

    function _verifySignedMessage(bytes32 messageHash, bytes memory signature) internal view returns (bool) {
        return isSigner(messageHash.toEthSignedMessageHash().recover(signature));
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }

    uint256[49] private __gap;
}
