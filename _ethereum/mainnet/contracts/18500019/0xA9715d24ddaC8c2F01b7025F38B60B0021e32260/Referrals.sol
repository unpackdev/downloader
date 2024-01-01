pragma solidity ^0.8.17;

library Referrals {

    function _generateReferralCode(uint256 _referralsNonce) internal view returns (string memory) {
        uint rand = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, _referralsNonce)));
        string memory hash = _toAlphabetString(rand);
        return _substring(hash, 0, 5);
    }

	 function _toAlphabetString(uint value) internal pure returns (string memory) {
        bytes memory alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        bytes memory result = new bytes(32);
        for(uint i = 0; i < 32; i++) {
            result[i] = alphabet[value % 62];
            value /= 62;
        }
        return string(result);
    }

    function _substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = 0; i<endIndex-startIndex; i++) {
            result[i] = strBytes[i+startIndex];
        }
        return string(result);
    }
}