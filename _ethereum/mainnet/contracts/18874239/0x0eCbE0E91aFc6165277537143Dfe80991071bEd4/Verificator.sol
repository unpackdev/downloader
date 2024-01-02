// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./EIP712.sol";

contract Verificator is Ownable, EIP712 {
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address user,uint256 nonce)");
    address public wallSigner;
    

    modifier isSigned(uint256 _nonce, bytes memory _signature) {
        require(
            getSigner(msg.sender, _nonce, _signature) == wallSigner,
            "Whitelist: Invalid signature"
        );
        _;
    }

    constructor(
        string memory name,
        string memory version,
        address signer
    ) EIP712(name, version) {
        wallSigner = signer;
    }

    function setwallSigner(address _address) external onlyOwner {
        wallSigner = _address;
    }

    function getSigner(
        address _user,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, _user, _nonce))
        );
        return ECDSA.recover(digest, _signature);
    }
}
