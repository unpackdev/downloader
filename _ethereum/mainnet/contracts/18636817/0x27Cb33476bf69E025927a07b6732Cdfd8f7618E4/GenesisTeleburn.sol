// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./BTCTeleburn.sol";
import "./SignatureChecker.sol";

contract GenesisTeleburn is BTCTeleburn {
    constructor(address nft, address teleburnSigner_) BTCTeleburn(nft, teleburnSigner_) {}

    function _isValidRequest(
        uint256 tokenId,
        address burnAddress,
        string calldata btcAddress,
        string calldata inscriptionId,
        uint256 sat,
        bytes calldata signature
    ) internal view override returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(nft, tokenId, burnAddress, btcAddress, inscriptionId, sat));
        bytes memory prefixedMessage = abi.encodePacked("\x19Ethereum Signed Message:\n32", message);

        return SignatureChecker.isValidSignatureNow(teleburnSigner, keccak256(prefixedMessage), signature);
    }
}
