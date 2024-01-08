// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./ECDSA.sol";
import "./LibRoles.sol";

abstract contract SignerRole is Context {
    using LibRoles for LibRoles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    LibRoles.Role private _signers;

    constructor() {
        _addSigner(_msgSender());
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public virtual onlySigner {
        _addSigner(account);
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
        address recoveredSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), v, r, s);
        return isSigner(recoveredSigner);
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}
