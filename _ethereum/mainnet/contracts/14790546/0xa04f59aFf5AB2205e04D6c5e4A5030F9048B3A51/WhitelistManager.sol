// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Address.sol";
import "./MerkleProof.sol";

/**
 *
 */
contract WhitelistManager {
    /* Structures **********************************************************************************************************************/

    struct Whitelist {
        bytes32 merkleRoot;    // whitelisted addresses for a given Whitelist
        mapping(address => uint256) tokensBalance; // how many tokens an address has purchased during whitelist for a given Whitelist
    }

    /* Internal variables **************************************************************************************************************/

    uint256 private currentWhitelistIndex;   // index of the currently used whitelist
    mapping(uint256 => Whitelist) private whitelists;

    /************************************************************************************************************************************
     * MINT
     ***********************************************************************************************************************************/

    /**
     * Return the currently used Whitelist
     */
    function _getCurrentWhitelist() private view returns(Whitelist storage) {
        return whitelists[currentWhitelistIndex];
    }

    /**
     * Start an empty new whitelist
     */
    function _startNewWhitelist() internal {
        currentWhitelistIndex++;
    }

    /**
     * Increment by 1 the tokens balance of _address in the current whitelist
     */
    function _incrementTokensBalanceOfCurrentWhitelist(address _address) internal {
        _getCurrentWhitelist().tokensBalance[_address] += 1;
    }

    /**
     * Return tokens balance of _address in the current whitelist
     */
    function _getTokenBalanceInCurrentWhitelist(address _address) internal view returns(uint256) {
        return _getCurrentWhitelist().tokensBalance[_address];
    }

    /**
     * Return true if msg.sender is whitelisted in the current whitelist, false otherwise
     */
    function _isMsgSenderWhitelisted(bytes32[] calldata merkleProof) internal view returns(bool) {
        return _isWhitelisted(merkleProof, msg.sender);
    }

    /**
     * Return true if _address is whitelisted in the current whitelist, false otherwise
     */
    function _isWhitelisted(bytes32[] calldata merkleProof, address _address) internal view returns(bool) {
        return MerkleProof.verify(merkleProof, _getCurrentWhitelist().merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    /**
     * Update the whitelisted addresses
     */
    function _setWhitelist(bytes32 _merkleRoot) internal {
        _getCurrentWhitelist().merkleRoot = _merkleRoot;
    }
}
