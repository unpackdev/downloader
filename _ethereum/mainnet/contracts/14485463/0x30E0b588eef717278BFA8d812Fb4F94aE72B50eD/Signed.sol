// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./AdminManager.sol";

contract SignedUpgradable is AdminManagerUpgradable {
    using ECDSA for bytes32;

    address internal _signer;

    function __Signed_init() internal initializer {
        __AdminManager_init();
        _signer = 0xEA122932a41d465aaBcc54888b747fA0df51432F;
    }

    function setSigner(address signer) external onlyAdmin {
        _signer = signer;
    }

    function getSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function isAuthorizedSigner(address extracted)
        internal
        view
        virtual
        returns (bool)
    {
        return extracted == _signer;
    }

    function createHash(bytes calldata breedRequestData)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(address(this), msg.sender, breedRequestData)
            );
    }

    function verifySignature(
        bytes calldata breedRequestData,
        bytes calldata signature
    ) internal view {
        address extracted = getSigner(createHash(breedRequestData), signature);
        require(isAuthorizedSigner(extracted), "Signature verification failed");
    }
}
