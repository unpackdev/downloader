// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint value) external ;
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}


contract BatchTransferV3 {

    mapping (address => bool) _isOperator;

    event NewOperator(address oldOperator, address newOperator);

    modifier onlyOperator() {
        require(_isOperator[msg.sender], "Only Operator Can Do This.");
        _;
    }
    
    constructor(address[] memory operators) {
        for (uint256 i = 0; i < operators.length; i++) {
            _isOperator[operators[i]] = true;
        }
    }
    
    function isOperator(address testAddress) public view returns (bool) {
        return _isOperator[testAddress];
    }
    
    function changeOperator(address newOperator) external onlyOperator {
        require(!_isOperator[newOperator], "Already Is Operator.");
        _isOperator[msg.sender] = false;
        _isOperator[newOperator] = true;
        emit NewOperator(msg.sender, newOperator);
    }

    function multiOwnersTransfer(
        address[] calldata owners,
        address contractAddress,
        address receiver,
        uint256[] calldata amounts,
        bytes[] calldata signatures
    ) external onlyOperator {
        require(owners.length <= 20, "Too many owners.");
        require(owners.length == amounts.length, "Parameter length wrong.");
        require(owners.length == signatures.length, "Parameter length wrong.");
        for (uint256 i = 0; i < owners.length; i++) {
            require(verifySig(receiver, signatures[i], owners[i]), "Signature Wrong.");
            IERC20 token = IERC20(contractAddress);
            require(token.balanceOf(owners[i]) >= amounts[i], "Not Enough Balance.");
            require(token.allowance(owners[i], address(this)) >= amounts[i], "Not Enough Permit.");
            token.transferFrom(owners[i], receiver, amounts[i]);
        }
    }

    function getMessageHash(address receiver) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(receiver));
    }

    function getEthSignedMessageHash(bytes32 hashMessage) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashMessage));
    }

    function verifySig(address receiver, bytes memory signature, address signer) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(receiver);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function getSigAddress(address receiver, bytes memory signature) internal pure returns (address) {
        bytes32 messageHash = getMessageHash(receiver);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature);
    }
    
    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid Signature Length.");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }


}