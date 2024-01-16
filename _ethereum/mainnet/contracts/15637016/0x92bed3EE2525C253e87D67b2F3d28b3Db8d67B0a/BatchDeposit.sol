// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./BytesLib.sol";
import "./StorageSlot.sol";
import "./IBatchDeposit.sol";
import "./MemUtils.sol";


contract BatchDeposit is IBatchDeposit, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 internal constant SIGNING_KEYS_MAPPING_NAME = keccak256("kiki.BatchDeposit.signingKeysMappingName");
    // @dev Total number of operators
    bytes32 internal constant TOTAL_OPERATORS_COUNT_POSITION = keccak256("kiki.BatchDeposit.totalOperatorsCount");
    // @dev Cached number of active operators
    bytes32 internal constant ACTIVE_OPERATORS_COUNT_POSITION = keccak256("kiki.BatchDeposit.activeOperatorsCount");
    bytes32 internal constant WITHDRAWAL_CREDENTIALS_POSITION = keccak256("kiki.BatchDeposit.withdrawalCredentials");    
    bytes32 internal constant DEPOSIT_CONTRACT_POSITION = keccak256("kiki.BatchDeposit.depositContract");

    uint256 constant public PUBKEY_LENGTH = 48;
    uint256 constant public WITHDRAWAL_CREDENTIALS_LENGTH = 32;
    uint256 constant public SIGNATURE_LENGTH = 96;
    uint256 constant public DEPOSIT_SIZE = 32 ether;
    uint256 internal constant DEPOSIT_AMOUNT_UNIT = 1e9 wei;
    uint256 internal constant UINT64_MAX = uint256(type(uint64).max);
    uint256 constant public MAX_NODE_OPERATORS_COUNT = 2000;
    uint256 constant public DEFAULT_MAX_DEPOSITS_PER_CALL = 300;


    /// @dev Node Operator parameters and internal state
    struct NodeOperator {
        bool active;    // a flag indicating if the operator can participate in further staking and reward distribution
        string name;    // human-readable name
        uint256 stakingLimit;    // the maximum number of validators to stake for this operator
        uint256 stoppedValidators;   // number of signing keys which stopped validation (e.g. were slashed)

        uint256 totalSigningKeys;    // total amount of signing keys of this operator
        uint256 usedSigningKeys;     // number of signing keys of this operator which were used in deposits to the Ethereum 2
    }

    /// @dev Memory cache entry used in the assignNextKeys function
    struct DepositLookupCacheEntry {
        // Makes no sense to pack types since reading memory is as fast as any op
        uint256 id;
        uint256 stakingLimit;
        uint256 stoppedValidators;
        uint256 totalSigningKeys;
        uint256 usedSigningKeys;
        uint256 initialUsedSigningKeys;
    }

    /// @dev Mapping of all node operators. Mapping is used to be able to extend the struct.
    mapping(uint256 => NodeOperator) internal operators;

    modifier operatorExists(uint256 _id) {
        require(_id < getNodeOperatorsCount(), "NODE_OPERATOR_NOT_FOUND");
        _;
    }

    function initialize(address _depositContract) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        StorageSlot.getUint256Slot(TOTAL_OPERATORS_COUNT_POSITION).value = 0;
        StorageSlot.getUint256Slot(ACTIVE_OPERATORS_COUNT_POSITION).value = 0;
        _setDepositContract(_depositContract);
    }

     /**
      * @notice Add node operator named `_name` with reward address `_rewardAddress` and staking limit = 0
      * @param _name Human-readable name
      * @return id a unique key of the added operator
      */
    function addNodeOperator(string calldata _name) external onlyOwner returns (uint256 id)
    {
        id = getNodeOperatorsCount();
        require(id < MAX_NODE_OPERATORS_COUNT, "MAX_NODE_OPERATORS_COUNT_EXCEEDED");

        // TOTAL_OPERATORS_COUNT_POSITION.setStorageUint256(id.add(1));
        StorageSlot.getUint256Slot(TOTAL_OPERATORS_COUNT_POSITION).value = id.add(1);

        NodeOperator storage operator = operators[id];

        uint256 activeOperatorsCount = getActiveNodeOperatorsCount();
        // ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperatorsCount.add(1));
        StorageSlot.getUint256Slot(ACTIVE_OPERATORS_COUNT_POSITION).value = activeOperatorsCount.add(1);

        operator.active = true;
        operator.name = _name;
        operator.stakingLimit = 0;

        emit NodeOperatorAdded(id, _name, 0);

        return id;
    }

    /**
      * @notice Returns n-th signing key of the node operator #`_operatorId`
      * @param _operatorId Node Operator id
      * @param _index Index of the key, starting with 0
      * @return key Key
      * @return depositSignature Signature needed for a deposit_contract.deposit call
      * @return used Flag indication if the key was used in the staking
      */
    function getSigningKey(uint256 _operatorId, uint256 _index) external view
        operatorExists(_operatorId)
        returns (bytes memory key, bytes memory depositSignature, bool used)
    {
        require(_index < operators[_operatorId].totalSigningKeys, "KEY_NOT_FOUND");

        (bytes memory key_, bytes memory signature) = _loadSigningKey(_operatorId, _index);

        return (key_, signature, _index < operators[_operatorId].usedSigningKeys);
    }

    /**
      * @notice Add `_quantity` validator signing keys of operator #`_id` to the set of usable keys. Concatenated keys are: `_pubkeys`. Can be done by the DAO in question by using the designated rewards address.
      * @dev Along with each key the DAO has to provide a signatures for the
      *      (pubkey, withdrawal_credentials, 32000000000) message.
      *      Given that information, the contract'll be able to call
      *      deposit_contract.deposit on-chain.
      * @param _operatorId Node Operator id
      * @param _quantity Number of signing keys provided
      * @param _pubkeys Several concatenated validator signing keys
      * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
      */
    function addSigningKeys(uint256 _operatorId, uint256 _quantity, bytes calldata _pubkeys, bytes calldata _signatures) external onlyOwner
    {
        _addSigningKeys(_operatorId, _quantity, _pubkeys, _signatures);
    }

    function _addSigningKeys(uint256 _operatorId, uint256 _quantity, bytes calldata _pubkeys, bytes calldata _signatures) internal
    {
        require(_quantity != 0, "NO_KEYS");
        require(_pubkeys.length == _quantity.mul(PUBKEY_LENGTH), "INVALID_LENGTH");
        require(_signatures.length == _quantity.mul(SIGNATURE_LENGTH), "INVALID_LENGTH");

        for (uint256 i = 0; i < _quantity; ++i) {
            bytes memory key = BytesLib.slice(_pubkeys, i * PUBKEY_LENGTH, PUBKEY_LENGTH);
            require(!_isEmptySigningKey(key), "EMPTY_KEY");
            bytes memory sig = BytesLib.slice(_signatures, i * SIGNATURE_LENGTH, SIGNATURE_LENGTH);

            _storeSigningKey(_operatorId, operators[_operatorId].totalSigningKeys + i, key, sig);
            emit SigningKeyAdded(_operatorId, key);
        }

        operators[_operatorId].totalSigningKeys = operators[_operatorId].totalSigningKeys.add(to64(_quantity));
    }

    /**
      * @notice Removes a validator signing key #`index` of operator #`id` from the set of usable keys. 
      * @param operatorId Node Operator id
      * @param index Index of the key, starting with 0
      */
    function removeSigningKey(uint256 operatorId, uint256 index)
        external
        onlyOwner
    {
        _removeSigningKey(operatorId, index);
    }

    /**
      * @notice `_active ? 'Enable' : 'Disable'` the node operator #`_id`
      */
    function setNodeOperatorActive(uint256 _id, bool _active) external onlyOwner
        operatorExists(_id)
    {
        if (operators[_id].active != _active) {
            uint256 activeOperatorsCount = getActiveNodeOperatorsCount();
            if (_active) {
                // ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperatorsCount.add(1));
                StorageSlot.getUint256Slot(ACTIVE_OPERATORS_COUNT_POSITION).value = activeOperatorsCount.add(1);
            } else {
                // ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperatorsCount.sub(1));
                StorageSlot.getUint256Slot(ACTIVE_OPERATORS_COUNT_POSITION).value = activeOperatorsCount.sub(1);
            }      
        }

        operators[_id].active = _active;

        emit NodeOperatorActiveSet(_id, _active);
    }

    /**
      * @notice Change human-readable name of the node operator #`_id` to `_name`
      */
    function setNodeOperatorName(uint256 _id, string calldata _name) external onlyOwner
    {
        operators[_id].name = _name;
        emit NodeOperatorNameSet(_id, _name);
    }

     /**
      * @notice Set the maximum number of validators to stake for the node operator #`_id` to `_stakingLimit`
      */
    function setNodeOperatorStakingLimit(uint256 _id, uint64 _stakingLimit) external onlyOwner
    {
        operators[_id].stakingLimit = _stakingLimit;
        emit NodeOperatorStakingLimitSet(_id, _stakingLimit);
    }

     function _storeSigningKey(uint256 _operatorId, uint256 _keyIndex, bytes memory _key, bytes memory _signature) internal {
        assert(_key.length == PUBKEY_LENGTH);
        assert(_signature.length == SIGNATURE_LENGTH);
        // algorithm applicability constraints
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);
        assert(0 == SIGNATURE_LENGTH % 32);

        // key
        uint256 offset = _signingKeyOffset(_operatorId, _keyIndex);
        uint256 keyExcessBits = (2 * 32 - PUBKEY_LENGTH) * 8;
        assembly {
            sstore(offset, mload(add(_key, 0x20)))
            sstore(add(offset, 1), shl(keyExcessBits, shr(keyExcessBits, mload(add(_key, 0x40)))))
        }
        offset += 2;

        // signature
        for (uint256 i = 0; i < SIGNATURE_LENGTH; i += 32) {
            assembly {
                sstore(offset, mload(add(_signature, add(0x20, i))))
            }
            offset++;
        }
    }

    function _isEmptySigningKey(bytes memory _key) internal pure returns (bool) {
        assert(_key.length == PUBKEY_LENGTH);
        // algorithm applicability constraint
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);

        uint256 k1;
        uint256 k2;
        assembly {
            k1 := mload(add(_key, 0x20))
            k2 := mload(add(_key, 0x40))
        }

        return 0 == k1 && 0 == (k2 >> ((2 * 32 - PUBKEY_LENGTH) * 8));
    }

    function _removeSigningKey(uint256 _operatorId, uint256 _index) internal
    {
        require(_index < operators[_operatorId].totalSigningKeys, "KEY_NOT_FOUND");
        require(_index >= operators[_operatorId].usedSigningKeys, "KEY_WAS_USED");

        (bytes memory removedKey, ) = _loadSigningKey(_operatorId, _index);

        uint256 lastIndex = operators[_operatorId].totalSigningKeys.sub(1);
        if (_index < lastIndex) {
            (bytes memory key, bytes memory signature) = _loadSigningKey(_operatorId, lastIndex);
            _storeSigningKey(_operatorId, _index, key, signature);
        }

        _deleteSigningKey(_operatorId, lastIndex);
        operators[_operatorId].totalSigningKeys = operators[_operatorId].totalSigningKeys.sub(1);

        if (_index < operators[_operatorId].stakingLimit) {
            // decreasing the staking limit so the key at _index can't be used anymore
            operators[_operatorId].stakingLimit = uint64(_index);
        }

        emit SigningKeyRemoved(_operatorId, removedKey);
    }

    function _deleteSigningKey(uint256 _operatorId, uint256 _keyIndex) internal {
        uint256 offset = _signingKeyOffset(_operatorId, _keyIndex);
        for (uint256 i = 0; i < (PUBKEY_LENGTH + SIGNATURE_LENGTH) / 32 + 1; ++i) {
            assembly {
                sstore(add(offset, i), 0)
            }
        }
    }
    
    function submit() external payable {
        uint256 deposit = msg.value;
        require (deposit >= DEPOSIT_SIZE, "deposit ether amount less than 32 ether");
        require(deposit.mod(DEPOSIT_SIZE) == 0, "depsoit ether amount is illegal"); 
        uint256 _numDeposits = deposit.div(DEPOSIT_SIZE);
        _eth2Deposit(_numDeposits < DEFAULT_MAX_DEPOSITS_PER_CALL ? _numDeposits : DEFAULT_MAX_DEPOSITS_PER_CALL);
        
    }

     /**
    * @dev Performs deposits to the ETH 2.0 side
    * @param _numDeposits Number of deposits to perform
    */
    function _eth2Deposit(uint256 _numDeposits) internal {
        (bytes memory pubkeys, bytes memory signatures) = assignNextSigningKeys(_numDeposits);
        require (pubkeys.length != 0, "no pubkeys assigned");

        require(pubkeys.length.mod(PUBKEY_LENGTH) == 0, "REGISTRY_INCONSISTENT_PUBKEYS_LEN");
        require(signatures.length.mod(SIGNATURE_LENGTH) == 0, "REGISTRY_INCONSISTENT_SIG_LEN");

        uint256 numKeys = pubkeys.length.div(PUBKEY_LENGTH);
        require(numKeys == signatures.length.div(SIGNATURE_LENGTH), "REGISTRY_INCONSISTENT_SIG_COUNT");

        for (uint256 i = 0; i < numKeys; ++i) {
            bytes memory pubkey = BytesLib.slice(pubkeys, i * PUBKEY_LENGTH, PUBKEY_LENGTH);
            bytes memory signature = BytesLib.slice(signatures, i * SIGNATURE_LENGTH, SIGNATURE_LENGTH);
            _stake(pubkey, signature);
        }
    }

     /**
    * @dev Invokes a deposit call to the official Deposit contract
    * @param _pubkey Validator to stake for
    * @param _signature Signature of the deposit call
    */
    function _stake(bytes memory _pubkey, bytes memory _signature) internal {
        bytes32 withdrawalCredentials = getWithdrawalCredentials();
        require(withdrawalCredentials != 0, "EMPTY_WITHDRAWAL_CREDENTIALS");

        uint256 value = DEPOSIT_SIZE;

        // The following computations and Merkle tree-ization will make official Deposit contract happy
        uint256 depositAmount = value.div(DEPOSIT_AMOUNT_UNIT);
        assert(depositAmount.mul(DEPOSIT_AMOUNT_UNIT) == value);    // properly rounded

        // Compute deposit data root (`DepositData` hash tree root) according to deposit_contract.sol
        bytes32 pubkeyRoot = sha256(_pad64(_pubkey));
        bytes32 signatureRoot = sha256(
            abi.encodePacked(
                sha256(BytesLib.slice(_signature, 0, 64)),
                sha256(_pad64(BytesLib.slice(_signature, 64, SIGNATURE_LENGTH.sub(64))))
            )
        );

        bytes32 depositDataRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkeyRoot, withdrawalCredentials)),
                sha256(abi.encodePacked(_toLittleEndian64(depositAmount), signatureRoot))
            )
        );

        uint256 targetBalance = address(this).balance.sub(value);

        emit Stake(msg.sender, _pubkey);

        getDepositContract().deposit{value: value}(
            _pubkey, abi.encodePacked(withdrawalCredentials), _signature, depositDataRoot);
        // avoid dangerous strict equality
        require(address(this).balance >= targetBalance, "EXPECTING_DEPOSIT_TO_HAPPEN");
    }

    /**
     * @notice Selects and returns at most `_numKeys` signing keys (as well as the corresponding
     *         signatures) from the set of active keys and marks the selected keys as used.
     *         May only be called by the KiKiStaking contract.
     *
     * @param _numKeys The number of keys to select. The actual number of selected keys may be less
     *        due to the lack of active keys.
     */
    function assignNextSigningKeys(uint256 _numKeys) internal returns (bytes memory pubkeys, bytes memory signatures) {
        // Memory is very cheap, although you don't want to grow it too much
        DepositLookupCacheEntry[] memory cache = _loadOperatorCache();
        if (0 == cache.length)
            return (new bytes(0), new bytes(0));

        uint256 numAssignedKeys = 0;
        DepositLookupCacheEntry memory entry;

        while (numAssignedKeys < _numKeys) {
            // Finding the best suitable operator
            uint256 bestOperatorIdx = cache.length;   // 'not found' flag
            uint256 smallestStake = 0;
            // The loop is ligthweight comparing to an ether transfer and .deposit invocation
            for (uint256 idx = 0; idx < cache.length; ++idx) {
                entry = cache[idx];

                assert(entry.usedSigningKeys <= entry.totalSigningKeys);
                if (entry.usedSigningKeys == entry.totalSigningKeys)
                    continue;

                uint256 stake = entry.usedSigningKeys.sub(entry.stoppedValidators);
                if (stake + 1 > entry.stakingLimit)
                    continue;

                if (bestOperatorIdx == cache.length || stake < smallestStake) {
                    bestOperatorIdx = idx;
                    smallestStake = stake;
                }
            }

            if (bestOperatorIdx == cache.length)  // not found
                break;

            entry = cache[bestOperatorIdx];
            assert(entry.usedSigningKeys < UINT64_MAX);

            ++entry.usedSigningKeys;
            ++numAssignedKeys;
        }

        if (numAssignedKeys == 0) {
            return (new bytes(0), new bytes(0));
        }

        if (numAssignedKeys > 1) {
            // we can allocate without zeroing out since we're going to rewrite the whole array
            pubkeys = MemUtils.unsafeAllocateBytes(numAssignedKeys * PUBKEY_LENGTH);
            signatures = MemUtils.unsafeAllocateBytes(numAssignedKeys * SIGNATURE_LENGTH);
        }

        uint256 numLoadedKeys = 0;

        for (uint256 i = 0; i < cache.length; ++i) {
            entry = cache[i];

            if (entry.usedSigningKeys == entry.initialUsedSigningKeys) {
                continue;
            }

            operators[entry.id].usedSigningKeys = uint64(entry.usedSigningKeys);

            for (uint256 keyIndex = entry.initialUsedSigningKeys; keyIndex < entry.usedSigningKeys; ++keyIndex) {
                (bytes memory pubkey, bytes memory signature) = _loadSigningKey(entry.id, keyIndex);
                if (numAssignedKeys == 1) {
                    return (pubkey, signature);
                } else {
                    MemUtils.copyBytes(pubkey, pubkeys, numLoadedKeys * PUBKEY_LENGTH);
                    MemUtils.copyBytes(signature, signatures, numLoadedKeys * SIGNATURE_LENGTH);
                    ++numLoadedKeys;
                }
            }

            if (numLoadedKeys == numAssignedKeys) {
                break;
            }
        }
        assert(numLoadedKeys == numAssignedKeys);
        return (pubkeys, signatures);
    }

    function _loadSigningKey(uint256 _operatorId, uint256 _keyIndex) internal view returns (bytes memory key, bytes memory signature) {
        // algorithm applicability constraints
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);
        assert(0 == SIGNATURE_LENGTH % 32);

        uint256 offset = _signingKeyOffset(_operatorId, _keyIndex);

        // key
        bytes memory tmpKey = new bytes(64);
        assembly {
            mstore(add(tmpKey, 0x20), sload(offset))
            mstore(add(tmpKey, 0x40), sload(add(offset, 1)))
        }
        offset += 2;
        key = BytesLib.slice(tmpKey, 0, PUBKEY_LENGTH);

        // signature
        signature = new bytes(SIGNATURE_LENGTH);
        for (uint256 i = 0; i < SIGNATURE_LENGTH; i += 32) {
            assembly {
                mstore(add(signature, add(0x20, i)), sload(offset))
            }
            offset++;
        }

        return (key, signature);
    }

    function _loadOperatorCache() internal view returns (DepositLookupCacheEntry[] memory cache) {
        cache = new DepositLookupCacheEntry[](getActiveNodeOperatorsCount());
        if (0 == cache.length)
            return cache;

        uint256 totalOperators = getNodeOperatorsCount();
        uint256 idx = 0;
        for (uint256 _operatorId = 0; _operatorId < totalOperators; ++_operatorId) {
            NodeOperator storage operator = operators[_operatorId];

            if (!operator.active)
                continue;

            DepositLookupCacheEntry memory entry = cache[idx++];
            entry.id = _operatorId;
            entry.stakingLimit = operator.stakingLimit;
            entry.stoppedValidators = operator.stoppedValidators;
            entry.totalSigningKeys = operator.totalSigningKeys;
            entry.usedSigningKeys = operator.usedSigningKeys;
            entry.initialUsedSigningKeys = entry.usedSigningKeys;
        }
        require(idx == cache.length, "INCOSISTENT_ACTIVE_COUNT");

        return cache;
    }

    function _signingKeyOffset(uint256 _operatorId, uint256 _keyIndex) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(SIGNING_KEYS_MAPPING_NAME, _operatorId, _keyIndex)));
    }

     /**
      * @notice Returns number of active node operators
      */
    function getActiveNodeOperatorsCount() public view returns (uint256) {
        // return ACTIVE_OPERATORS_COUNT_POSITION.getStorageUint256();
        return StorageSlot.getUint256Slot(ACTIVE_OPERATORS_COUNT_POSITION).value;
        
    }

    /**
      * @notice Returns the n-th node operator
      * @param _id Node Operator id
      */
    function getNodeOperator(uint256 _id) external view
        returns
        (
            bool active,
            string memory name,
            uint256 stakingLimit,
            uint256 stoppedValidators,
            uint256 totalSigningKeys,
            uint256 usedSigningKeys
        )
    {
        NodeOperator storage operator = operators[_id];

        active = operator.active;
        name = operator.name; 
        stakingLimit = operator.stakingLimit;
        stoppedValidators = operator.stoppedValidators;
        totalSigningKeys = operator.totalSigningKeys;
        usedSigningKeys = operator.usedSigningKeys;
    }

    /**
      * @notice Returns total number of signing keys of the node operator #`_operatorId`
      */
    function getTotalSigningKeyCount(uint256 _operatorId) external view operatorExists(_operatorId) returns (uint256) {
        return operators[_operatorId].totalSigningKeys;
    }

    /**
      * @notice Returns number of usable signing keys of the node operator #`_operatorId`
      */
    function getUnusedSigningKeyCount(uint256 _operatorId) external view operatorExists(_operatorId) returns (uint256) {
        return operators[_operatorId].totalSigningKeys.sub(operators[_operatorId].usedSigningKeys);
    }

    /**
      * @notice Returns total number of node operators
      */
    function getNodeOperatorsCount() public view returns (uint256) {
        // return TOTAL_OPERATORS_COUNT_POSITION.getStorageUint256();
        return StorageSlot.getUint256Slot(TOTAL_OPERATORS_COUNT_POSITION).value;
    }

    function getWithdrawalCredentials() public view returns (bytes32) {
        // return WITHDRAWAL_CREDENTIALS_POSITION.getStorageBytes32();
        return StorageSlot.getBytes32Slot(WITHDRAWAL_CREDENTIALS_POSITION).value;
    }

    function setWithdrawalCredentials(bytes32 withdrawalCredentials) external onlyOwner {
        // WITHDRAWAL_CREDENTIALS_POSITION.setStorageBytes32(_withdrawalCredentials);
        StorageSlot.getBytes32Slot(WITHDRAWAL_CREDENTIALS_POSITION).value = withdrawalCredentials;
        trimUnusedKeys();

        emit WithdrawalCredentialsSet(withdrawalCredentials);
    }

     /**
      * @notice Gets deposit contract handle
      */
    function getDepositContract() public view returns (IDepositContract) {
        // return IDepositContract(DEPOSIT_CONTRACT_POSITION.getStorageAddress());
        return IDepositContract(StorageSlot.getAddressSlot(DEPOSIT_CONTRACT_POSITION).value);
    }

    /**
    * @dev Sets the address of Deposit contract
    * @param contractAddress the address of Deposit contract
    */
    function _setDepositContract(address contractAddress) internal {
        require(isContract(address(contractAddress)), "D_NOT_A_CONTRACT");
        // DEPOSIT_CONTRACT_POSITION.setStorageAddress(address(_contract));
        StorageSlot.getAddressSlot(DEPOSIT_CONTRACT_POSITION).value = contractAddress;
    }

     /**
      * @notice Remove unused signing keys
      * @dev Function is used by the KiKiStaking contract
      */
    function trimUnusedKeys() internal  {
        uint256 length = getNodeOperatorsCount();
        for (uint256 _operatorId = 0; _operatorId < length; ++_operatorId) {
            uint256 totalSigningKeys = operators[_operatorId].totalSigningKeys;
            uint256 usedSigningKeys = operators[_operatorId].usedSigningKeys;
            if (totalSigningKeys != usedSigningKeys) { // write only if update is needed
                operators[_operatorId].totalSigningKeys = usedSigningKeys;  // discard unused keys
                emit NodeOperatorTotalKeysTrimmed(_operatorId, totalSigningKeys - usedSigningKeys);
            }
        }
    }


    /**
      * @dev Padding memory array with zeroes up to 64 bytes on the right
      * @param _b Memory array of size 32 .. 64
      */
    function _pad64(bytes memory _b) internal pure returns (bytes memory) {
        assert(_b.length >= 32 && _b.length <= 64);
        if (64 == _b.length)
            return _b;

        bytes memory zero32 = new bytes(32);
        assembly { mstore(add(zero32, 0x20), 0) }

        if (32 == _b.length)
            return BytesLib.concat(_b, zero32);
        else
            return BytesLib.concat(_b, BytesLib.slice(zero32, 0, uint256(64).sub(_b.length)));
    }

    /**
      * @dev Converting value to little endian bytes and padding up to 32 bytes on the right
      * @param _value Number less than `2**64` for compatibility reasons
      */
    function _toLittleEndian64(uint256 _value) internal pure returns (uint256 result) {
        result = 0;
        uint256 tempValue = _value;
        for (uint256 i = 0; i < 8; ++i) {
            result = (result << 8) | (tempValue & 0xFF);
            tempValue >>= 8;
        }

        assert(0 == tempValue);    // fully converted
        result <<= (24 * 8);
    }

    function to64(uint256 v) internal pure returns (uint64) {
        assert(v <= uint256(type(uint64).max));
        return uint64(v);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function recoverWrongTokens(bool isETH, address to, address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(to != address(0x0), "address to is empty");
        if (isETH) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, )  = to.call{value: tokenAmount}("");
            require(success, "recover ETH falied");
        } else {
            IERC20(tokenAddress).safeTransfer(to, tokenAmount);
        }
    }
}

