//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMathUpgradeable.sol";
import "./EIP712BaseUpgradeable.sol";

contract EIP712MetaTxUpgradeable is EIP712BaseUpgradeable {
    using SafeMathUpgradeable for uint256;

    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    mapping(address => uint256) internal _nonces;

    event MetaTransactionExecuted(address indexed userAddress, address indexed relayerAddress, bytes functionSignature);

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function __EIP712MetaTx_init_unchained(string memory name, string memory version) internal initializer {
        __EIP712Base_init_unchained(name, version);
    }

    function convertBytesToBytes4(bytes memory inBytes) pure internal returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV
    ) public payable returns(bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(destinationFunctionSig != msg.sig, "EIP712MetaTx: functionSignature can not be of executeMetaTransaction method");

        MetaTransaction memory metaTx = MetaTransaction({
            nonce: _nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "EIP712MetaTx: Signer and signature do not match");

        _nonces[userAddress] = _nonces[userAddress].add(1);
        emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));
        require(success, "EIP712MetaTx: Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
    }

    function getNonce(address user) external view returns(uint256) {
        return _nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "EIP712MetaTx: Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns(address payable sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    uint256[49] private __gap;
}
