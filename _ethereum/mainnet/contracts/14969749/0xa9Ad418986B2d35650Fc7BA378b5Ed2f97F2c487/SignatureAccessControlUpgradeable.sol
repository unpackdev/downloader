// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./EnumerableSetUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title Allow List contract.
 */
abstract contract SignatureAccessControlUpgradeable is Initializable {
    using ECDSAUpgradeable for bytes32;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    event SigningAddressChanged(address indexed oldAddres, address indexed newAddress);

    address public signingAddress;

    function _SignatureAccessControlUpgradeable_init(address _signingAddress) internal onlyInitializing {
        require(_signingAddress != address(0), 'Cannot set address(0) as signer');
        signingAddress = _signingAddress;
    }

    function _hasAccess(address caller, bytes calldata _signature) internal view returns (bool) {
        return
            signingAddress ==
            keccak256(
                abi.encodePacked(
                    '\x19Ethereum Signed Message:\n32',
                    bytes32(uint256(uint160(caller)))
                )
            ).recover(_signature);
    }
}
