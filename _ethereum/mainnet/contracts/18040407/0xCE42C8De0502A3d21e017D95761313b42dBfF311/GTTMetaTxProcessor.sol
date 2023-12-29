// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";
import "./SigUtil.sol";
import "./BytesUtil.sol";
import "./gtt.sol";

contract GTTMetaTxProcessor {
    //EIP712协议的类型描述
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,address verifyingContract)"
    );
    //分割词,与前端签名匹配,名字和版本,然后地址
    bytes32 DOMAIN_SEPARATOR;

    bytes32 constant ERC20METATRANSACTION_TYPEHASH = keccak256(
        "ERC20MetaTransaction(address from,address to,address tokenContract,uint256 amount,uint256 nonce)"
    );

    // 协议需要的Event对象
    event MetaTx(
        address indexed from,
        uint256 indexed nonce,
        bool success
    );

    // 状态对象
    mapping(address => uint256) batches;
    bool lock = false;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256("GTT Meta Transaction"),
                keccak256("1"),
                address(this)
            )
        );
    }

    function executeMetaTransaction(
        address from,
        address to,
        bytes memory signature,
        address tokenContract,
        uint256 amount,
        uint256 nonce
    ) public returns (bool success) {
        require(!lock, "IN_PROGRESS");
        lock = true;
        _ensureParametersValidity(from, nonce);
        _ensureCorrectSigner(from, to,  signature, tokenContract, amount, nonce);
        success = _performERC20MetaTx(from, to, tokenContract, amount, nonce);
        lock = false;
    }

    function _ensureParametersValidity(
        address from,
        uint256 nonce
    ) internal view {
        require(batches[from] + 1 == nonce, "nonce out of order");
    }

    function _encodeMessage(
        address from,
        address to,
        address tokenContract,
        uint256 amount,
        uint256 nonce
    ) internal view returns (bytes memory) {
        return abi.encodePacked(
            "\x19\x01"
            ,DOMAIN_SEPARATOR
            ,keccak256(messageBytes(from, to, tokenContract, amount, nonce))
        );
    }

    function messageBytes(
        address from,
        address to,
        address tokenContract,
        uint256 amount,
        uint256 nonce
    ) internal pure returns(bytes memory) {
        return abi.encode(
            ERC20METATRANSACTION_TYPEHASH,
            from,
            to,
            tokenContract,
            amount,
            nonce
        );
    }

    function _ensureCorrectSigner(
        address from,
        address to,
        bytes memory signature,
        address tokenContract,
        uint256 amount,
        uint256 nonce
    ) internal view {
        bytes memory dataToHash = _encodeMessage(from, to, tokenContract, amount, nonce);

        address signer = SigUtil.recover(keccak256(dataToHash), signature);
        require(signer == from, "signer != from");
    }

    function _performERC20MetaTx(
        address from,
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 nonce
    ) internal returns (bool success) {
        batches[from] = nonce;

        ERC20 tokenContract = ERC20(tokenAddress);
        require(tokenContract.transferFrom(from, to, amount), "ERC20_TRANSFER_FAILED");

        success = true;

        emit MetaTx(from, nonce, success);
    }

    function get_nonce(address from) external view returns(uint256) {
        return batches[from];
    }
}