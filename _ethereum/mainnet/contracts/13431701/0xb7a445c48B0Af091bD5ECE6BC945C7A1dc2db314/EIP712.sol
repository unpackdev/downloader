// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

library EIP712 {
    /**
     * @dev Check if milestone release was pre-approved.
     *
     * @param _validator Address of opposite party which approval is needed.
     * @param _success bytes4 hash of called function, returned as success result.
     * @param _encodedChallenge abi encoded string of variables to proof.
     * @param _signature Digest of challenge.
     * @return _success for success 0x00000000 for failure.
     */
    function _isValidEIP712Signature(
        address _validator,
        bytes4 _success,
        bytes memory _encodedChallenge,
        bytes calldata _signature
    ) internal pure returns (bytes4) {
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
        (_v, _r, _s) = abi.decode(_signature, (uint8, bytes32, bytes32));
        bytes32 _hash = keccak256(_encodedChallenge);
        address _signer =
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ),
                _v,
                _r,
                _s
            );

        if (_validator == _signer) {
            return _success;
        } else {
            return bytes4(0);
        }
    }
}