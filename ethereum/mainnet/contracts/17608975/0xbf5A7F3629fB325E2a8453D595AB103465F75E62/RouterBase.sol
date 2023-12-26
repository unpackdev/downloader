/// SPDX-License-Identifier: GPL-3.0

/// Copyright (C) 2023 Portals.fi

/// @author Portals.fi
/// @notice Base contract inherited by the Portals Router

pragma solidity 0.8.19;

import "./IRouterBase.sol";
import "./IPortalsRouter.sol";
import { IPortalsMulticall } from
    "../multicall/interface/IPortalsMulticall.sol";
import "./IPermit.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./Owned.sol";
import { SignatureChecker } from
    "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import { Pausable } from
    "openzeppelin-contracts/security/Pausable.sol";
import { EIP712 } from
    "openzeppelin-contracts/utils/cryptography/EIP712.sol";

abstract contract RouterBase is
    IRouterBase,
    Owned,
    Pausable,
    EIP712
{
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IPortalsMulticall immutable PORTALS_MULTICALL;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        )
    );

    bytes32 private constant ORDER_TYPEHASH = keccak256(
        abi.encodePacked(
            "Order(address inputToken,uint256 inputAmount,address outputToken,uint256 minOutputAmount,address recipient)"
        )
    );

    bytes32 private constant SIGNED_ORDER_TYPEHASH = keccak256(
        abi.encodePacked(
            "SignedOrder(Order order,bytes32 routeHash,address sender,uint64 deadline,uint64 nonce)Order(address inputToken,uint256 inputAmount,address outputToken,uint256 minOutputAmount,address recipient)"
        )
    );

    //Order nonces
    mapping(address => uint64) public nonces;

    constructor(address _admin, IPortalsMulticall _multicall)
        Owned(_admin)
        EIP712("PortalsRouter", "1")
    {
        PORTALS_MULTICALL = _multicall;
    }

    /// @notice Transfers tokens or the network token from the sender to the Portals multicall contract
    /// @param sender The address of the owner of the tokens
    /// @param token The address of the token to transfer (address(0) if network token)
    /// @param quantity The quantity of tokens to transfer from the caller
    /// @return value The quantity of network tokens to be transferred to the Portals Multicall contract
    function _transferFromSender(
        address sender,
        address token,
        uint256 quantity
    ) internal returns (uint256) {
        if (token == address(0)) {
            require(
                msg.value != 0, "PortalsRouter: Invalid msg.value"
            );
            return msg.value;
        }

        require(
            msg.value == 0 && quantity != 0,
            "PortalsRouter: Invalid quantity or msg.value"
        );
        ERC20(token).safeTransferFrom(
            sender, address(PORTALS_MULTICALL), quantity
        );
        return 0;
    }

    /// @notice Get the ERC20 or network token balance of an account
    /// @param account The owner of the tokens or network tokens whose balance is being queried
    /// @param token The address of the token (address(0) if network token)
    /// @return The accounts's token or network token balance
    function _getBalance(address account, address token)
        internal
        view
        returns (uint256)
    {
        if (token == address(0)) {
            return account.balance;
        } else {
            return ERC20(token).balanceOf(account);
        }
    }

    /// @notice Signature verification function to verify Portals signed orders. Supports both ECDSA
    /// signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets
    /// @dev Returns nothing if the order is valid but reverts if the signature is invalid
    /// @param signedOrderPayload The signed order payload to verify
    function _verify(
        IPortalsRouter.SignedOrderPayload calldata signedOrderPayload
    ) internal {
        require(
            signedOrderPayload.signedOrder.deadline >= block.timestamp,
            "PortalsRouter: Order expired"
        );

        bytes32 orderHash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                signedOrderPayload.signedOrder.order.inputToken,
                signedOrderPayload.signedOrder.order.inputAmount,
                signedOrderPayload.signedOrder.order.outputToken,
                signedOrderPayload.signedOrder.order.minOutputAmount,
                signedOrderPayload.signedOrder.order.recipient
            )
        );
        bytes32 signedOrderHash = keccak256(
            abi.encode(
                SIGNED_ORDER_TYPEHASH,
                orderHash,
                keccak256(abi.encode(signedOrderPayload.calls)),
                signedOrderPayload.signedOrder.sender,
                signedOrderPayload.signedOrder.deadline,
                nonces[signedOrderPayload.signedOrder.sender]++
            )
        );

        bytes32 digest = _hashTypedDataV4(signedOrderHash);

        require(
            SignatureChecker.isValidSignatureNow(
                signedOrderPayload.signedOrder.sender,
                digest,
                signedOrderPayload.signature
            ),
            "PortalsRouter: Invalid signature"
        );
    }

    /// @notice Permit function for gasless approvals. Supports both EIP-2612 and DAI style permits with
    /// split signatures, as well as Yearn like permits with combined signatures
    /// @param owner The address which is a source of funds and has signed the Permit
    /// @param token The address of the token to permit
    /// @param permitPayload The permit payload containing the permit parameters
    /// @dev See IPermit.sol for more details
    function _permit(
        address owner,
        address token,
        IPortalsRouter.PermitPayload calldata permitPayload
    ) internal {
        if (permitPayload.splitSignature) {
            bytes memory signature = permitPayload.signature;
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            if (permitPayload.daiPermit) {
                IPermit(token).permit(
                    owner,
                    address(this),
                    ERC20(token).nonces(owner),
                    permitPayload.deadline,
                    true,
                    v,
                    r,
                    s
                );
            } else {
                IPermit(token).permit(
                    owner,
                    address(this),
                    permitPayload.amount,
                    permitPayload.deadline,
                    v,
                    r,
                    s
                );
            }
        } else {
            IPermit(token).permit(
                owner,
                address(this),
                permitPayload.amount,
                permitPayload.deadline,
                permitPayload.signature
            );
        }
    }

    /// @notice The EIP712 domain separator of this contract
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @notice Invalidates the next order of msg.sender
    /// @notice Orders that have already been confirmed are not invalidated
    function invalidateNextOrder() external {
        ++nonces[msg.sender];
    }

    /// @dev Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Recovers stuck tokens
    /// @param tokenAddress The address of the token to recover (address(0) if ETH)
    /// @param tokenAmount The quantity of tokens to recover
    /// @param to The address to send the recovered tokens to
    function recoverToken(
        address tokenAddress,
        uint256 tokenAmount,
        address to
    ) external onlyOwner {
        if (tokenAddress == address(0)) {
            to.safeTransferETH(tokenAmount);
        } else {
            ERC20(tokenAddress).safeTransfer(to, tokenAmount);
        }
    }
}
