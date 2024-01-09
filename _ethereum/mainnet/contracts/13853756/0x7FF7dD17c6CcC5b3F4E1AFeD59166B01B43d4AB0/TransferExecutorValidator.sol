// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./OperatorRole.sol";
import "./IERC1271.sol";
import "./SignatureLib.sol";
import "./TransferExecutorLib.sol";

abstract contract TransferExecutorValidator is Initializable, ContextUpgradeable, EIP712Upgradeable, OperatorRole {
    using SignatureLib for bytes32;
    using AddressUpgradeable for address;
    
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    function __TransferExecutorValidator_init_unchained() internal initializer {
        __OperatorRole_init_unchained();
        __EIP712_init_unchained("TransferExecutor", "1");
    }

    function validate(TransferExecutorLib.TransferExecutorData memory transfer) internal view {
        if (!operators[_msgSender()]) {
            bytes32 hash = TransferExecutorLib.hash(transfer);
            address signer;
            if (transfer.signature.length == 65) {
                signer = _hashTypedDataV4(hash).recover(transfer.signature);
            }
            if  (!operators[signer]) {
                if (transfer.to.isContract()) {
                    require(
                        IERC1271(transfer.to).isValidSignature(_hashTypedDataV4(hash), transfer.signature) == MAGICVALUE,
                        "contract transfer signature verification error"
                    );
                } else {
                    revert("transfer signature verification error");
                }
            }
        }
    }

    uint256[50] private __gap;
}