// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";

abstract contract SignerRoleUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    event LogSetSigner(address indexed account);

    address private signer;

    function __SignerRole_init(address _signer) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __SignerRole_init_unchained(_signer);
    }

    function __SignerRole_init_unchained(address _signer) internal initializer {
        _setSigner(_signer);
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return signer == account;
    }

    function setSigner(address account) public virtual onlyOwner {
        _setSigner(account);
    }

    function _setSigner(address account) internal {
        signer = account;
        emit LogSetSigner(account);
    }

    function _verifySignedMessage(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        return isSigner(messageHash.toEthSignedMessageHash().recover(v, r, s));
    }

    function _verifySignedMessage(bytes32 messageHash, bytes memory signature) internal view returns (bool) {
        return isSigner(messageHash.toEthSignedMessageHash().recover(signature));
    }

    uint256[49] private __gap;
}
