// SPDX-License-Identifier: Unlicense

//  __   ___    _____  __      __  _____      ____      _____   ________    _____   ______
// () ) / __)  / ___/  ) \    / ( (  __ \    / __ \    / ____\ (___  ___)  / ___/  (   __ \
// ( (_/ /    ( (__     \ \  / /   ) )_) )  / /  \ \  ( (___       ) )    ( (__     ) (__) )
// ()   (      ) __)     \ \/ /   (  ___/  ( ()  () )  \___ \     ( (      ) __)   (    __/
// () /\ \    ( (         \  /     ) )     ( ()  () )      ) )     ) )    ( (       ) \ \  _
// ( (  \ \    \ \___      )(     ( (       \ \__/ /   ___/ /     ( (      \ \___  ( ( \ \_))
// ()_)  \_\    \____\    /__\    /__\       \____/   /____/      /__\      \____\  )_) \__/

pragma solidity ^0.8.21;

import "./Ownable.sol";

/**************************************************************************
 * @dev KeyPoster is a simple contract that stores an array of addresses. *
 * @dev The contract uses the term "Key" in place of Address in order to  *
 * @dev avoid confusion from solidity functions. Keys can only be added   *
 * @dev or removed by the contract owner. The contract has a function to  *
 * @dev transfer ownership. Anybody can check if an address (key) is in   *
 * @dev the list (returns bool) or may call a complete list of keys       *
 * @dev stored. A key is also stored with the block number the key was    *
 * @dev added. License is Unlicense, open source and free to use.         *
 *************************************************************************/

contract KeyPoster is Ownable {
    // Mapping to keep track of keys
    mapping(address => bool) private _keys;
    mapping(address => uint256) private _keyBlockNumbers;

    // Array to store all keys for efficient retrieval
    address[] private _allKeys;

    // Events
    event KeyAdded(address indexed key, uint256 blockNumber);
    event KeyRemoved(address indexed key);

    struct KeyData {
        address key;
        uint256 blockNumber;
    }

    /**
     * @dev Constructor that sets the initial owner.
     * @param initialOwner The initial owner's address.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Internal function to determine if an address is a contract.
     * @param addr The address to check.
     * @return bool True if the address is a contract, otherwise false.
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev Add a Key.
     * Only callable by the owner.
     * Validates that the key is not a contract address.
     * @param key The Key to add.
     */
    function addKey(address key) external onlyOwner {
        require(!_keys[key], "Key already exists");
        require(!_isContract(key), "Key cannot be a contract address");
        _keys[key] = true;
        _keyBlockNumbers[key] = block.number;
        _allKeys.push(key);
        emit KeyAdded(key, block.number);
    }

    /**
     * @dev Remove a Key.
     * Only callable by the owner.
     * @param key The Key to remove.
     */
    function removeKey(address key) external onlyOwner {
        require(_keys[key], "Key does not exist");
        _keys[key] = false;

        // Remove the key from _allKeys array
        for (uint256 i = 0; i < _allKeys.length; i++) {
            if (_allKeys[i] == key) {
                _allKeys[i] = _allKeys[_allKeys.length - 1];
                _allKeys.pop();
                break;
            }
        }
        emit KeyRemoved(key);
    }

    /**
     * @dev Check if a Key exists.
     * @param key The Key to check.
     * @return bool True if the Key exists, otherwise false.
     */
    function isKey(address key) external view returns (bool) {
        return _keys[key];
    }

    /**
     * @dev Retrieve all Keys along with the block numbers they were added.
     * @return KeyData[] The list of all Keys and their block numbers.
     */
    function getAllKeys() external view returns (KeyData[] memory) {
        KeyData[] memory keysWithBlockNumbers = new KeyData[](_allKeys.length);
        for (uint256 i = 0; i < _allKeys.length; i++) {
            keysWithBlockNumbers[i] = KeyData(
                _allKeys[i],
                _keyBlockNumbers[_allKeys[i]]
            );
        }
        return keysWithBlockNumbers;
    }
}
