// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;

import "./ERC1271.sol";
import "./LibOrder.sol";
import "./AddressUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

abstract contract OrderValidator is
    Initializable,
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable
{
    using ECDSAUpgradeable for bytes32;
    using AddressUpgradeable for address;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    function __OrderValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("Exchange", "2");
    }

    function getChainId() external view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    function validate(LibOrder.Order memory order, bytes memory signature)
        internal
        view
    {
        if (_msgSender() != order.maker) {
            bytes32 hash = LibOrder.hash(order);
            if (order.maker.isContract()) {
                require(
                    ERC1271(order.maker).isValidSignature(
                        _hashTypedDataV4(hash),
                        signature
                    ) == MAGICVALUE,
                    "signature verification error"
                );
            } else {
                require(
                    _hashTypedDataV4(hash).recover(signature) == order.maker,
                    "signature verification error"
                );
            }
        }
    }

    uint256[50] private __gap;
}
