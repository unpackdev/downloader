//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract mainnetSigner{

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns(address){
        return owner;
    }

    function setOwner(address _owner) public{
        require(msg.sender == owner,"can only be called by owner");
        owner = _owner;
    }

    /**
   * @notice Verifies that the signer is the owner of the signing contract.
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature
  ) external view returns (bytes4) {
    // Validate signatures
    if (recoverSigner(_hash, _signature) == owner) {
      return 0x1626ba7e;
    } else {
      return 0xffffffff;
    }
  }

 /**
   * @notice Recover the signer of hash, assuming it's an EOA account
   * @dev Only for EthSign signatures
   * @param _ethSignedMessageHash       Hash of message that was signed
   * @param _signature  Signature encoded as (bytes32 r, bytes32 s, uint8 v)
   */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}