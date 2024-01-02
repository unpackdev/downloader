// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EIP712.sol";
import "./ECDSA.sol";

import "./IERC20MintBurnable.sol";
import "./IOpenWithdrawing.sol";

contract OpenWithdrawing is Ownable, EIP712, IOpenWithdrawing {
    IERC20MintBurnable private immutable token;
    mapping(address => uint256) private withdrawNonce;

    bytes32 private constant WITHDRAW_TYPEHASH =
        keccak256("Withdraw(address withdrawer,uint256 nonce,uint256 amount)");

    constructor(
        IERC20MintBurnable _token,
        address _admin
    ) Ownable(_admin) EIP712("OpenStaking", "1") {
        token = _token;
    }

    /// @inheritdoc IOpenWithdrawing
    function withdraw(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address _withdrawer,
        uint256 _amount
    ) external {
        address signer = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        WITHDRAW_TYPEHASH,
                        _withdrawer,
                        withdrawNonce[_withdrawer],
                        _amount
                    )
                )
            ),
            _v,
            _r,
            _s
        );
        if (signer != owner()) {
            revert InvalidProof();
        }

        token.mint(_withdrawer, _amount);
        emit TokensWithdrawn(_withdrawer, _amount);
        withdrawNonce[_withdrawer]++;
    }

    function getNonce(address _account) external view returns (uint256 nonce) {
        nonce = withdrawNonce[_account];
    }
}
