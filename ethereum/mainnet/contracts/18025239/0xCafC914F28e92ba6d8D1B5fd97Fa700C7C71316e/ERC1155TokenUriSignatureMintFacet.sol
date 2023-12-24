// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ERC1155TokenUriSignatureMintBaseInternal.sol";
import "./OwnableInternal.sol";

contract ERC1155TokenUriSignatureMintFacet is
    ERC1155TokenUriSignatureMintBaseInternal,
    OwnableInternal
{
    function mintBatchWithTokenUrisViaSignature(
        address to,
        string[] calldata tokenUris,
        uint256[] calldata amounts,
        uint256 expiry,
        bytes calldata signature
    ) external {
        _mintBatchWithTokenUriViaSignature(
            to,
            tokenUris,
            amounts,
            expiry,
            signature
        );
    }

    function setMintSigner(address signer) external onlyOwner {
        _setMintSigner(signer);
    }

    function mintSigner() external view returns (address) {
        return _mintSigner();
    }

    function nonceForUser(address account) external view returns (uint256) {
        return _nonceForUser(account);
    }
}
