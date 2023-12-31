// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BaseModule.sol";
/**
 * @title KresusRelayer
 * @notice Abstract Module to execute transactions signed by ETH-less accounts and sent by a relayer.
 */
abstract contract KresusRelayer is BaseModule {

    struct RelayerConfig {
        uint256 nonce;
        mapping(bytes32 => uint256) queuedTransactions;
        mapping(bytes32 => uint256) arrayIndex;
        bytes32[] queue;
    }

    // Used to avoid stack too deep error
    struct StackExtension {
        Signature signatureRequirement;
        bytes32 signHash;
        bool success;
        bytes returnData;
    }

    uint256 internal constant BLOCKBOUND = 10000;

    mapping (address => RelayerConfig) internal relayer;


    event TransactionExecuted(address indexed vault, bool indexed success, bytes returnData, bytes32 signedHash);
    event TransactionQueued(address indexed vault, uint256 executionTime, bytes32 signedHash);
    event Refund(address indexed vault, uint256 refundAmount);
    event ActionCancelled(address indexed vault, bytes32 signedHash);
    event AllActionsCancelled(address indexed vault);
    
    /**
    * @notice Executes a relayed transaction.
    * @param _vault The target vault.
    * @param _data The data for the relayed transaction
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _signatures The signatures as a concatenated byte array.
    * @return true if executed or queued successfully, else returns false.
    */
    function execute(
        address _vault,
        bytes calldata _data,
        uint256 _nonce,
        bytes calldata _signatures
    )
        external
        returns (bool)
    {
        require(verifyData(_vault, _data), "KR: Target of _data != _vault");

        StackExtension memory stack;
        uint256 td;
        (td, stack.signatureRequirement) = getRequiredSignatures(_vault, _data);

        stack.signHash = getSignHash(
            _vault,
            0,
            _data,
            _nonce
        );

        // Execute a queued tx
        if (isActionQueued(_vault, stack.signHash)){
            require(
                relayer[_vault].queuedTransactions[stack.signHash] < block.timestamp,
                "KR: Time not expired"
            );
            (stack.success, stack.returnData) = address(this).call(_data);
            require(stack.success, "KR: Internal call failed");
            if(relayer[_vault].queue.length > 0) {
                removeQueue(_vault, stack.signHash);
            }
            emit TransactionExecuted(_vault, stack.success, stack.returnData, stack.signHash);
            return stack.success;
        }
        
        
        require(validateSignatures(
                _vault, 
                stack.signHash,
                _signatures, 
                stack.signatureRequirement
            ),
            "KR: Invalid Signatures"
        );

        require(checkAndUpdateUniqueness(_vault, _nonce), "KR: Duplicate request");
        

        // Queue the Tx
        if(td > 0) {
            uint256 executionTime = block.timestamp + td;
            relayer[_vault].queuedTransactions[stack.signHash] = executionTime;
            relayer[_vault].queue.push(stack.signHash);
            relayer[_vault].arrayIndex[stack.signHash] = relayer[_vault].queue.length-1;
            emit TransactionQueued(_vault, executionTime, stack.signHash);
            return true;
        }
        // Execute the tx directly without queuing
        else {
            (stack.success, stack.returnData) = address(this).call(_data);
            require(stack.success, "KR: Internal call failed");
            emit TransactionExecuted(_vault, stack.success, stack.returnData, stack.signHash);
            return stack.success;
        }
    }  

    /**
     * @notice cancels a transaction which was queued.
     * @param _vault The target vault.
     * @param _data The data for the relayed transaction.
     * @param _nonce The nonce used to prevent replay attacks.
     * @param _signature The signature needed to validate cancel.
     */
    function cancel(
        address _vault,
        bytes calldata _data,
        uint256 _nonce,
        bytes memory _signature
    ) 
        external 
    {
        bytes32 _actionHash = getSignHash(_vault, 0, _data, _nonce);
        bytes32 _cancelHash = getSignHash(_vault, 0, "0x", _nonce);
        require(isActionQueued(_vault, _actionHash), "KR: Invalid hash");
        Signature _sig = getCancelRequiredSignatures(_data);
        require(
            validateSignatures(
                _vault,
                _cancelHash,
                _signature,
                _sig
            ), "KR: Invalid Signatures"
        );
        removeQueue(_vault, _actionHash);
        emit ActionCancelled(_vault, _actionHash);
    }

    /**
     * @notice to cancel all the queued operations for a `_vault` address.
     * @param _vault The target vault.
     */
    function cancelAll(
        address _vault
    ) external onlySelf {
        uint256 len = relayer[_vault].queue.length; 
        for(uint256 i=0;i<len;i++) {
            bytes32 _actionHash = relayer[_vault].queue[i];
            relayer[_vault].queuedTransactions[_actionHash] = 0;
            relayer[_vault].arrayIndex[_actionHash] = 0;
        }
        delete relayer[_vault].queue;
        emit AllActionsCancelled(_vault);
    }

    /**
    * @notice Gets the current nonce for a vault.
    * @param _vault The target vault.
    * @return nonce gets the last used nonce of the vault.
    */
    function getNonce(address _vault) external view returns (uint256 nonce) {
        return relayer[_vault].nonce;
    }

    /**
    * @notice Gets the number of valid signatures that must be provided to execute a
    * specific relayed transaction.
    * @param _vault The target vault.
    * @param _data The data of the relayed transaction.
    * @return The number of required signatures and the vault owner signature requirement.
    */
    function getRequiredSignatures(
        address _vault,
        bytes calldata _data
    ) public view virtual returns (uint256, Signature);

    /**
    * @notice checks validity of a signature depending on status of the vault.
    * @param _vault The target vault.
    * @param _actionHash signed hash of the request.
    * @param _data The data of the relayed transaction.
    * @param _option Type of signature.
    * @return true if it is a valid signature.
    */
    function validateSignatures(
        address _vault,
        bytes32 _actionHash,
        bytes memory _data,
        Signature _option
    ) public view virtual returns(bool);

    /**
    * @notice Gets the required signature from {Signature} enum to cancel the request.
    * @param _data The data of the relayed transaction.
    * @return The required signature from {Signature} enum .
    */ 
    function getCancelRequiredSignatures(
        bytes calldata _data
    ) public pure virtual returns(Signature);

    /**
    * @notice Generates the signed hash of a relayed transaction according to ERC 1077.
    * @param _from The starting address for the relayed transaction (should be the relayer module)
    * @param _value The value for the relayed transaction.
    * @param _data The data for the relayed transaction which includes the vault address.
    * @param _nonce The nonce used to prevent replay attacks.
    */
    function getSignHash(
        address _from,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    _from,
                    _value,
                    _data,
                    block.chainid,
                    _nonce
                ))
            )
        );
    }

    /**
    * @notice Checks if the relayed transaction is unique. If yes the state is updated.
    * @param _vault The target vault.
    * @param _nonce The nonce.
    * @return true if the transaction is unique.
    */
    function checkAndUpdateUniqueness(
        address _vault,
        uint256 _nonce
    )
        internal
        returns (bool)
    {
        // use the incremental nonce
        if (_nonce <= relayer[_vault].nonce) {
            return false;
        }
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if (nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[_vault].nonce = _nonce;
        return true;
    }

    /**
    * @notice Checks that the vault address provided as the first parameter of _data matches _vault
    * @return false if the addresses are different.
    */
    function verifyData(address _vault, bytes calldata _data) internal pure returns (bool) {
        require(_data.length >= 36, "KR: Invalid dataVault");
        require(_vault != ZERO_ADDRESS, "KR: Invalid vault");
        address dataVault = abi.decode(_data[4:], (address));
        return dataVault == _vault;
    }

    /**
    * @notice Check whether a given action is queued.
    * @param _vault The target vault.
    * @param  actionHash  Hash of the action to be checked. 
    * @return Boolean `true` if the underlying action of `actionHash` is queued, otherwise `false`.
    */
    function isActionQueued(
        address _vault,
        bytes32 actionHash
    )
        public
        view
        returns (bool)
    {
        return (relayer[_vault].queuedTransactions[actionHash] > 0);
    }

    /**
    * @notice Return execution time for a given queued action.
    * @param _vault The target vault.
    * @param  actionHash  Hash of the action to be checked.
    * @return uint256   execution time for a given queued action.
    */
    function queuedActionExecutionTime(
        address _vault,
        bytes32 actionHash
    )
        external
        view
        returns (uint256)
    {
        return relayer[_vault].queuedTransactions[actionHash];
    }
    
    /**
    * @notice Removes an element at index from the array queue of a user
    * @param _vault The target vault.
    * @param  _actionHash  Hash of the action to be checked.
    * @return false if the index is invalid.
    */
    function removeQueue(address _vault, bytes32 _actionHash) internal returns(bool) {
        RelayerConfig storage _relayer = relayer[_vault];
        _relayer.queuedTransactions[_actionHash] = 0;

        uint256 index = _relayer.arrayIndex[_actionHash];
        uint256 len = _relayer.queue.length;
        if(index != len - 1) {
            bytes32 lastHash = _relayer.queue[len - 1];
            _relayer.arrayIndex[lastHash] = index;
            _relayer.arrayIndex[_actionHash] = 0;
            _relayer.queue[index] = lastHash;
        }
        _relayer.queue.pop();
        
        return true;
    }
}