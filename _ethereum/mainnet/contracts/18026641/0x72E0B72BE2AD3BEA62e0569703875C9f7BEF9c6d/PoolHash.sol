// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./PoolStruct.sol";

contract EIP712 {
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }
    bytes32 constant public ORDER_TYPEHASH = keccak256(
        "Order(enum ItemType typ,address from,address to,address collection,uint256[] tokenIds,uint256[] amounts,uint256 salt,uint256 extraData,uint256 suitableTime,uint256 expiredTime)"
    );
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    
    bytes32 DOMAIN_SEPARATOR;

    function _hashDomain(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            )
        );
    }

    function _hashOrder(Order calldata order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.typ,
                order.from,
                order.to,
                order.collection,
                order.tokenIds,
                order.amounts,
                order.salt,
                order.extraData,
                order.suitableTime,
                order.expiredTime
            ));
    }
    
    function _hashToSign(bytes32 orderHash) internal view returns (bytes32 hash) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            orderHash
        ));
    }
}
