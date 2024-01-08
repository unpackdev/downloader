// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./CollectionV2.sol";
import "./AccessControl.sol";
import "./IERC1155.sol";

import "./console.sol";

contract EscrowBatch is AccessControl {
    event ClaimedBatch(
        address _wallet,
        address _collection,
        uint256[] _tokenIds,
        uint256[] _quantities
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    bytes32 public immutable MINTER_ROLE = bytes32(keccak256("MINTER_ROLE"));

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

    function makeHash(
        address collectionAddr,
        uint256[] memory tokenIds,
        uint256[] memory quantities,
        address wallet
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(collectionAddr, tokenIds, quantities, wallet));
    }

    function claimBatch(
        address collectionAddr,
        uint256[] memory tokenIds,
        uint256[] memory quantities,
        address wallet,
        bytes calldata signature
    ) public {
        bytes32 hash = makeHash(collectionAddr, tokenIds, quantities, wallet);

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
        // We're just going to assume that these token IDs are in the contract
        // and let the call fail if they're not
        IMintableBatchInterface(collectionAddr).mintBatch(
            wallet,
            tokenIds,
            quantities
        );
        emit ClaimedBatch(wallet, collectionAddr, tokenIds, quantities);
    }
}
