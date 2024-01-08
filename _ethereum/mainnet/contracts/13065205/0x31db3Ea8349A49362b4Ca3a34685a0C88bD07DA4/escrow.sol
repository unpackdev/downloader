// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./CollectionV2.sol";
import "./AccessControl.sol";
import "./IERC1155.sol";

contract Escrow is AccessControl {
    event Claimed(
        string profileId,
        address wallet,
        address collection,
        uint256 tokenId
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    bytes32 immutable MINTER_ROLE = bytes32(keccak256("MINTER_ROLE"));
    bytes32 immutable MATIC_MINTER_ROLE =
        bytes32(keccak256("MATIC_MINTER_ROLE"));

    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

    function grantMinter(address _minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, _minter);
    }

    function revokeMinter(address _minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MINTER_ROLE, _minter);
    }

    function grantMaticMinter(address _minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MATIC_MINTER_ROLE, _minter);
    }

    function revokeMaticMinter(address _minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MATIC_MINTER_ROLE, _minter);
    }

    function mintToEscrow(address collectionAddr, uint256 tokenId)
        external
        onlyRole(MATIC_MINTER_ROLE)
    {
        IMintableInterface(collectionAddr).mint(address(this), tokenId);
    }

    function claim(
        address collectionAddr,
        uint256 tokenId,
        address wallet,
        string calldata profileId,
        bytes calldata signature
    ) public {
        bytes32 hash = keccak256(
            abi.encode(collectionAddr, tokenId, wallet, profileId)
        );
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            signature,
            (uint8, bytes32, bytes32)
        );
        address recovered = ecrecover(
            keccak256(abi.encodePacked(personalSignPrefix, "32", hash)),
            v,
            r,
            s
        );

        require(hasRole(MINTER_ROLE, recovered), "Invalid signature");
        if (IERC1155(collectionAddr).balanceOf(address(this), tokenId) > 0) {
            IERC1155(collectionAddr).safeTransferFrom(
                address(this),
                wallet,
                tokenId,
                1,
                ""
            );
        } else {
            IMintableInterface(collectionAddr).mint(wallet, tokenId);
        }
        emit Claimed(profileId, wallet, collectionAddr, tokenId);
    }
}
