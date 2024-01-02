// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./BTCTeleburn.sol";
import "./SignatureChecker.sol";

contract GenesisTeleburn is BTCTeleburn {
    address public constant originalContract = 0x27Cb33476bf69E025927a07b6732Cdfd8f7618E4;

    constructor(address nft, address teleburnSigner_) BTCTeleburn(nft, teleburnSigner_) {
        teleburnedCount = 3;
        isTokenTeleburned[1003] = true;
        isTokenTeleburned[1543] = true;
        isTokenTeleburned[1589] = true;
    }

    function _isValidRequest(
        uint256 tokenId,
        address burnAddress,
        string calldata btcAddress,
        string calldata inscriptionId,
        bytes calldata signature
    ) internal view override returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(nft, tokenId, burnAddress, btcAddress, inscriptionId));
        bytes memory prefixedMessage = abi.encodePacked("\x19Ethereum Signed Message:\n32", message);

        return SignatureChecker.isValidSignatureNow(teleburnSigner, keccak256(prefixedMessage), signature);
    }
}
