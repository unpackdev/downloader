//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

error SignatureMismatch();
error NonceAlreadyUsed();

contract BullyverseAvatarClaim is Ownable {
    IERC721A public avatar;
    address internal signer;
    address public treasury;

    mapping (uint256 => bool) public nonceUsed;

    constructor(address _avatar, address _signer, address _treasury) {
        avatar = IERC721A(_avatar);
        signer = _signer;
        treasury = _treasury;
    }

    function claim(
        uint256 tokenId,
        uint256 nonce,
        bytes calldata signature
    ) external {
        if (nonceUsed[nonce]) revert NonceAlreadyUsed();

        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    tokenId,
                    nonce
                )
            )
        );
        if (ECDSA.recover(hash, signature) != signer) revert SignatureMismatch();

        nonceUsed[nonce] = true;
        avatar.safeTransferFrom(treasury, msg.sender, tokenId);
    }

    function updateClaimInfo(address _avatar, address _signer, address _treasury) external onlyOwner {
        avatar = IERC721A(_avatar);
        signer = _signer;
        treasury = _treasury;
    }
}
