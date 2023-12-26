// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721Receiver.sol";
import "./IPointsVaultExtension.sol";
import "./IVaultFactory.sol";
import "./IUniversalVault.sol";
import "./IGeyser.sol";
import "./IPartyVaultRouter.sol";

contract PartyVaultRouter is IPartyVaultRouter, IERC721Receiver {
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    uint256 private chainId;

    constructor() {
        uint256 chainId_;
        assembly {
            chainId_ := chainid()
        }
        chainId = chainId_;
    }

    /**
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(address, /*operator*/ address from, uint256 tokenId, bytes calldata data)
        external
        view
        returns (bytes4)
    {
        return bytes4(
            abi.encodeWithSelector(
                IERC721Receiver(address(this)).onERC721Received.selector, msg.sender, from, tokenId, data
            )
        );
    }

    /**
     * @inheritdoc IPartyVaultRouter
     */
    function createAndDeposit(
        address vaultFactory,
        bytes32 salt,
        address token,
        uint128 amount,
        LockRequest[] calldata requests
    ) external returns (address vault) {
        vault = IVaultFactory(vaultFactory).create2(salt);
        IVaultFactory(vaultFactory).safeTransferFrom(
            address(this), msg.sender, IVaultFactory(vaultFactory).addressToUint(vault)
        );
        deposit(vault, token, amount, requests);
    }

    /**
     * @inheritdoc IPartyVaultRouter
     */
    function deposit(address vault, address token, uint128 amount, LockRequest[] calldata requests) public {
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, vault, amount);
        for (uint256 index = 0; index < requests.length; index++) {
            LockRequest calldata request = requests[index];
            if (request.rewardProgramType == RewardProgram.Points) {
                IPointsVaultExtension(request.rewardProgram).stakeToken(
                    vault, token, request.amount, request.permission
                );
            } else {
                IGeyser(request.rewardProgram).stake(vault, request.amount, request.permission);
            }
        }
    }

    /**
     * @inheritdoc IPartyVaultRouter
     */
    function unlock(address vault, address token, UnlockRequest[] calldata requests) external {
        for (uint256 index = 0; index < requests.length; index++) {
            UnlockRequest calldata request = requests[index];
            if (request.rewardProgramType == RewardProgram.Points) {
                IPointsVaultExtension(request.rewardProgram).unstakeToken(
                    vault, token, request.amount, request.permission
                );
            } else {
                IGeyser(request.rewardProgram).unstakeAndClaim(vault, request.amount, request.permission);
            }
        }
    }

    function generateNewVaultLockPermissionDigest(
        address delegate,
        address vaultFactory,
        address token,
        uint256 amount,
        bytes32 salt
    ) external view returns (bytes32 digest) {
        address vaultAddress = IVaultFactory(vaultFactory).predictCreate2Address(salt);
        return generateLockPermissionDigest(vaultAddress, delegate, token, amount, 0);
    }

    function generateExistingVaultLockPermissionDigest(
        address vaultAddress,
        address delegate,
        address token,
        uint256 amount
    ) external view returns (bytes32 digest) {
        return generateLockPermissionDigest(
            vaultAddress, delegate, token, amount, IUniversalVault(vaultAddress).getNonce()
        );
    }

    function generateLockPermissionDigest(
        address vaultAddress,
        address delegate,
        address token,
        uint256 amount,
        uint256 nonce
    ) public view returns (bytes32 digest) {
        return generatePermissionDigest(
            keccak256("Lock(address delegate,address token,uint256 amount,uint256 nonce)"),
            token,
            amount,
            nonce,
            vaultAddress,
            delegate
        );
    }

    function generateUnlockPermissionDigest(
        address vaultAddress,
        address delegate,
        address token,
        uint256 amount,
        uint256 nonce
    ) public view returns (bytes32 digest) {
        return generatePermissionDigest(
            keccak256("Unlock(address delegate,address token,uint256 amount,uint256 nonce)"),
            token,
            amount,
            nonce,
            vaultAddress,
            delegate
        );
    }

    function generatePermissionDigest(
        bytes32 eip712TypeHash,
        address token,
        uint256 amount,
        uint256 nonce,
        address vaultAddress,
        address delegate
    ) public view returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                keccak256(
                    abi.encode(
                        _TYPE_HASH, keccak256(bytes("UniversalVault")), keccak256(bytes("1.0.0")), chainId, vaultAddress
                    )
                ),
                keccak256(abi.encode(eip712TypeHash, delegate, token, amount, nonce))
            )
        );
    }
}
