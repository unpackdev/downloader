

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";


contract Allowlist is Ownable, EIP712 {

    bytes32 public constant METAMISS_TYPEHASH =
        keccak256("Metamiss(address buyer,uint256 quantity)");
    // signer to compare with
    address public ownerSigner;

    modifier isSenderAllowlisted(
        uint256 _quantity,
        bytes memory _signature
    ) {
        require(
            check(_quantity, msg.sender, _signature) ==
                ownerSigner,
            "Signature not equal to ownerSigner"
        );
        _;
    }

    constructor(string memory name, string memory version, address _ownerSigner)
    EIP712(name, version)
    {
        ownerSigner = _ownerSigner;
    }

    /**
     * Set the owner signer
     */
    function setOwnerSigner(address _ownerSigner) public onlyOwner {
        ownerSigner = _ownerSigner;
    }

    /**
     * Check signature, return the public address of the signer
     */
    function check(uint256 _quantity, address _buyer, bytes memory _signature) public view returns (address){
        return _verify(_quantity,_buyer,_signature);
    }

    function _verify(uint256 _quantity,address _buyer, bytes memory _signature) internal view returns (address){
        bytes32 digest = _hash(_quantity,_buyer);
        return ECDSA.recover(digest,_signature);
    }

    function _hash(uint256 _quantity, address _buyer) internal view returns (bytes32){
        return _hashTypedDataV4(keccak256(abi.encode(METAMISS_TYPEHASH,_buyer,_quantity)));
    }
}