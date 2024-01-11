// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./FEWLootStorage.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./Strings.sol";

contract FEWLoot is FEWLootStorage {
    using Strings for uint256;
    using ECDSA for bytes32;

    /**
     * @dev Hash of an ethereum signed message encoding the author, the price, and a nonce
     */
    function hashMessage(uint256 _nonce) internal view returns(bytes32 _hash) {
        _hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(msg.sender, _nonce))));
    }

    /**
     * @dev Public Minting function
     *      Each signature is valid for 1 item
     *      The signature combines is a keccak256 of msg.sender, and a nonce
     */
    function mint(bytes calldata _signature, uint256 _nonce) external payable {
        require(hashMessage(_nonce).recover(_signature) == _signer, "Loot: Weird Hash");
        require(!usedNonces[_nonce], "Loot: Reused Hash");

        usedNonces[_nonce] = true;

        _mint(msg.sender, totalSupply());
    }

    /**
     * @dev Airdrops loot to selected addresses
     */
    function airdropLoot(address[] calldata _recipients) external onlyOwner {
        uint256 _totalSupply = totalSupply();

        for (uint i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _totalSupply + i);
        }
    }
}