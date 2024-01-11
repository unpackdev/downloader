//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20Rebase.sol";
import "./ITransferReceiver.sol";

contract ERC20RebasePermit is ERC20Rebase {
    string public name;

    mapping(address => uint256) public nonces;

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256(
            "Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)"
        );

    constructor(string memory _name, uint256 chainId) {
        name = _name;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) public virtual returns (bool) {
        require(
            to != address(0) || to != address(this),
            "ARTH.usd: bad `to` address"
        );

        uint256 balance = balanceOf(msg.sender);
        require(balance >= value, "ARTH.usd: transfer exceeds balance");

        _transfer(msg.sender, to, value);
        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (bool) {
        require(block.timestamp <= deadline, "ARTH.usd: Expired permit");

        bytes32 hashStruct = keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                target,
                to,
                value,
                nonces[target]++,
                deadline
            )
        );

        require(
            _verifyEIP712(target, hashStruct, v, r, s) ||
                _verifyPersonalSign(target, hashStruct, v, r, s),
            "ARTH.usd: bad signature"
        );

        // NOTE: is this check needed, was there in the refered contract.
        require(
            to != address(0) || to != address(this),
            "ARTH.usd: bad `to` address"
        );
        require(
            balanceOf(target) >= value,
            "ARTH.usd: transfer exceeds balance"
        );

        _transfer(target, to, value);
        return true;
    }

    function _verifyEIP712(
        address target,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);

        return (signer != address(0) && signer == target);
    }

    /// @dev Builds a _prefixed hash to mimic the behavior of eth_sign.
    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function _verifyPersonalSign(
        address target,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        bytes32 hash = _prefixed(hashStruct);
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }
}
