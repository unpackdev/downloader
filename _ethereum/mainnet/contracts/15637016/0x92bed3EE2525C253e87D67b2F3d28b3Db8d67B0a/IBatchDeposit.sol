// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IDepositContract.sol";



interface IBatchDeposit {

    function submit() external payable;

    event Stake(address sender, bytes publicKey);

    /**
      * @notice Add node operator named `name` with staking limit = 0
      * @param name Human-readable name
      * @return id a unique key of the added operator
      */
    function addNodeOperator(string calldata name) external returns (uint256 id);

    /**
      * @notice Change human-readable name of the node operator #`id` to `name`
      */
    function setNodeOperatorName(uint256 id, string calldata name) external;

    /**
      * @notice Set the maximum number of validators to stake for the node operator #`id` to `stakingLimit`
      */
    function setNodeOperatorStakingLimit(uint256 id, uint64 stakingLimit) external;


    event NodeOperatorAdded(uint256 id, string name, uint256 stakingLimit);
    event NodeOperatorActiveSet(uint256 indexed id, bool active);
    event NodeOperatorTotalKeysTrimmed(uint256 indexed id, uint256 totalKeysTrimmed);
    event NodeOperatorNameSet(uint256 indexed id, string name);
    event NodeOperatorStakingLimitSet(uint256 indexed id, uint64 stakingLimit);

     /**
      * @notice `active ? 'Enable' : 'Disable'` the node operator #`id`
      */
    function setNodeOperatorActive(uint256 id, bool active) external;

    /**
      * @notice Add `quantity` validator signing keys of operator #`id` to the set of usable keys. Concatenated keys are: `pubkeys`. Can be done by the DAO in question by using the designated rewards address.
      * @dev Along with each key the DAO has to provide a signatures for the
      *      (pubkey, withdrawal_credentials, 32000000000) message.
      *      Given that information, the contract'll be able to call
      *      deposit_contract.deposit on-chain.
      * @param operatorId Node Operator id
      * @param quantity Number of signing keys provided
      * @param pubkeys Several concatenated validator signing keys
      * @param signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
      */
    function addSigningKeys(uint256 operatorId, uint256 quantity, bytes calldata pubkeys, bytes calldata signatures) external;
    /**
      * @notice Removes a validator signing key #`index` of operator #`id` from the set of usable keys. 
      * @param operatorId Node Operator id
      * @param index Index of the key, starting with 0
      */
    function removeSigningKey(uint256 operatorId, uint256 index) external;
    
    event SigningKeyAdded(uint256 indexed operatorId, bytes pubkey);
    event SigningKeyRemoved(uint256 indexed operatorId, bytes pubkey);
    
    function setWithdrawalCredentials(bytes32  _withdrawalCredentials) external;

    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);

    /**
      * @notice Returns the n-th node operator
      * @param id Node Operator id
      */
    function getNodeOperator(uint256 id) external view returns (
        bool active,
        string calldata name,
        uint256 stakingLimit,
        uint256 stoppedValidators,
        uint256 totalSigningKeys,
        uint256 usedSigningKeys);


     /**
      * @notice Returns total number of signing keys of the node operator #`operatorId`
      */
    function getTotalSigningKeyCount(uint256 operatorId) external view returns (uint256);

    /**
      * @notice Returns number of usable signing keys of the node operator #`operatorId`
      */
    function getUnusedSigningKeyCount(uint256 operatorId) external view returns (uint256);

     /**
      * @notice Returns n-th signing key of the node operator #`operatorId`
      * @param operatorId Node Operator id
      * @param index Index of the key, starting with 0
      * @return key Key
      * @return depositSignature Signature needed for a deposit_contract.deposit call
      * @return used Flag indication if the key was used in the staking
      */
    function getSigningKey(uint256 operatorId, uint256 index) external view returns
            (bytes memory key, bytes memory depositSignature, bool used);

    /**
      * @notice Returns number of active node operators
      */
    function getActiveNodeOperatorsCount() external view returns (uint256);

    /**
      * @notice Returns total number of node operators
      */
    function getNodeOperatorsCount() external view returns (uint256);

    function getWithdrawalCredentials() external view returns (bytes32);

    function getDepositContract() external view returns (IDepositContract);

    function recoverWrongTokens(bool isETH, address to, address tokenAddress, uint256 tokenAmount) external;

}