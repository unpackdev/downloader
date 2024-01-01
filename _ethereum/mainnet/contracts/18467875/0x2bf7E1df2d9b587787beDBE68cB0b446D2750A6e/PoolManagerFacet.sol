// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import "./CreditPoolFacet.sol";
import "./VaultFacet.sol";
import "./MetadataFacet.sol";
import "./AccessControlFacet.sol";

error NotPoolManager(address _user, address _poolManager);
error PoolManagerIdExist(string _id);
error PoolIdsExist(uint256 _length);
error NotVerifiedPoolManager(string _id);
error InvalidPoolManagerId(string _id);

library PoolManagerLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.poolmanager.storage");

    struct PoolManagerState {
        mapping(string => PoolManager) poolManagers;
    }

    struct PoolManager {
        string poolManagerId;
        string userId;
        string metaHash;
        string country;
        uint64 onBoardTime;
        address wallet;
        KYBStatus status;
        string[] poolIds;
        string[] paymentIds;
    }

    enum KYBStatus {PENDING, VERIFIED, REJECTED}

    function diamondStorage() internal pure returns (PoolManagerState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getPoolManager(string calldata _poolManagerId) internal view returns (PoolManager memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId];
    }

    function getPoolManagerUserId(string calldata _poolManagerId) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].userId;
    }

    function getPoolManagerMetaHash(string calldata _poolManagerId) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].metaHash;
    }

    function getPoolManagerCountry(string calldata _poolManagerId) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].country;
    }

    function getPoolManagerOnBoardTime(string calldata _poolManagerId) internal view returns (uint64) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].onBoardTime;
    }

    function getPoolManagerWallet(string calldata _poolManagerId) internal view returns (address) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].wallet;
    }

    function getPoolManagerKYBStatus(string calldata _poolManagerId) internal view returns (KYBStatus) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].status;
    }

    function getPoolIdsLength(string calldata _poolManagerId) internal view returns (uint256) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].poolIds.length;
    }

    function getPoolId(string calldata _poolManagerId, uint256 _index) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].poolIds[_index];
    }

    function getPoolIds(string calldata _poolManagerId) internal view returns (string[] memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].poolIds;
    }

    function getPaymentIdsLength(string calldata _poolManagerId) internal view returns (uint256) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].paymentIds.length;
    }

    function getPaymentId(string calldata _poolManagerId, uint256 _index) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].paymentIds[_index];
    }

    function getMetadataURI(string calldata _poolManagerId) internal view returns (string memory) {
        enforceIsPoolManagerIdExist(_poolManagerId);
        string memory _baseURI = MetadataLib.getBaseURI();
        string memory _metaHash = getPoolManagerMetaHash(_poolManagerId);
        return bytes(_baseURI).length > 0 ? string(string.concat(bytes(_baseURI), bytes(_metaHash))) : "";
    }

    function createPoolManager(
        string calldata _poolManagerId,
        string calldata _userId,
        string calldata _metaHash,
        string calldata _country,
        uint64 _onBoardTime,
        address _wallet,
        KYBStatus _status
    ) internal returns (PoolManager memory) {
        AccessControlLib.enforceIsCreateManager();
        PoolManagerState storage poolManagerState = diamondStorage();
        if(keccak256(bytes(_poolManagerId)) == keccak256(bytes(poolManagerState.poolManagers[_poolManagerId].poolManagerId))) {
            revert PoolManagerIdExist(_poolManagerId);
        }
        poolManagerState.poolManagers[_poolManagerId] = PoolManager(_poolManagerId, _userId, _metaHash, _country, _onBoardTime, _wallet, _status, new string[](0), new string[](0));
        return poolManagerState.poolManagers[_poolManagerId];
    }

    function removePoolManager(string calldata _poolManagerId) internal {
        AccessControlLib.enforceIsDeleteManager();
        PoolManagerState storage poolManagerState = diamondStorage();
        if(poolManagerState.poolManagers[_poolManagerId].poolIds.length != 0) {
            revert PoolIdsExist(poolManagerState.poolManagers[_poolManagerId].poolIds.length);
        }
        delete poolManagerState.poolManagers[_poolManagerId];
    }

    function updatePoolManagerHash(string calldata _poolManagerId, string calldata _hash) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].metaHash = _hash;
    }

    function updatePoolManagerCountry(string calldata _poolManagerId, string calldata _country) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].country = _country;
    }

    function updatePoolManagerOnBoardTime(string calldata _poolManagerId, uint64 _onBoardTime) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].onBoardTime = _onBoardTime;
    }
    
    function updatePoolManagerWallet(string calldata _poolManagerId, address _wallet) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].wallet = _wallet;
    }

    function updatePoolManagerKYB(string calldata _poolManagerId, KYBStatus _status) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].status = _status;
    }

    function addPoolId(string calldata _poolManagerId, string calldata _poolId) internal {
        CreditPoolLib.enforceIsCreditPool();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        poolManager.poolIds.push(_poolId);
    }

    function removePoolIdByIndex(string memory _poolManagerId, uint256 _poolIndex) internal {
        CreditPoolLib.enforceIsCreditPool();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        if(_poolIndex != poolManager.poolIds.length - 1) {
            poolManager.poolIds[_poolIndex] = poolManager.poolIds[poolManager.poolIds.length - 1];
            string memory _poolId = poolManager.poolIds[_poolIndex];
            CreditPoolLib.updateBindingIndexOfPool(_poolId, _poolIndex);
        }
        poolManager.poolIds.pop();
    }
    
    function addPaymentId(string memory _poolManagerId, string memory _paymentId) internal {
        VaultLib.enforceIsVault();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        poolManager.paymentIds.push(_paymentId);
    }

    function removePaymentId(string calldata _poolManagerId, string calldata _paymentId) internal {
        AccessControlLib.enforceIsDeleteManager();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        uint256 index;
        for (uint256 i = 0; i < poolManager.paymentIds.length; i++) {
            if (keccak256(bytes(poolManager.paymentIds[i])) == keccak256(bytes(_paymentId))) {
                index = i;
                break;
            }
        }
        poolManager.paymentIds[index] = poolManager.paymentIds[poolManager.paymentIds.length - 1];
        poolManager.paymentIds.pop();
    }

    function removePaymentIdByIndex(string calldata _poolManagerId, uint256 _paymentIndex) internal {
        AccessControlLib.enforceIsDeleteManager();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        if(_paymentIndex != poolManager.paymentIds.length - 1) {
            poolManager.paymentIds[_paymentIndex] = poolManager.paymentIds[poolManager.paymentIds.length - 1];
        }
        poolManager.paymentIds.pop();
    }

    function enforceIsPoolManager(string calldata _poolManagerId) internal view {
        PoolManagerState storage poolManagerState = diamondStorage();
        if(msg.sender != poolManagerState.poolManagers[_poolManagerId].wallet) {
            revert NotPoolManager(msg.sender, poolManagerState.poolManagers[_poolManagerId].wallet);
        }
    }

    function enforceIsPoolManagerKYBVerified(string memory _poolManagerId) internal view {
        PoolManagerState storage poolManagerState = diamondStorage();
        if(poolManagerState.poolManagers[_poolManagerId].status != KYBStatus.VERIFIED) {
            revert NotVerifiedPoolManager(_poolManagerId);
        }
    }

    function enforceIsPoolManagerIdExist(string calldata _poolManagerId) internal view {
        PoolManagerState storage poolManagerState = diamondStorage();
        if(bytes(poolManagerState.poolManagers[_poolManagerId].poolManagerId).length == 0) {
            revert InvalidPoolManagerId(_poolManagerId);
        }
    }

}

contract PoolManagerFacet {
    event DeletePoolManagerEvent(string indexed poolManagerId);
    event CreatePoolManagerEvent(PoolManagerLib.PoolManager poolManager);
    event UpdatePoolManagerHashEvent(string indexed poolManagerId, string prevHash, string newHash);
    event UpdatePoolManagerCountryEvent(string indexed poolManagerId, string prevCountry, string newCountry);
    event UpdatePoolManagerOnBoardTimeEvent(string indexed poolManagerId, uint64 prevTime, uint64 newTime);
    event UpdatePoolManagerWalletEvent(string indexed poolManagerId, address prevWallet, address newWallet);
    event UpdatePoolManagerKYBEvent(string indexed poolManagerId, PoolManagerLib.KYBStatus prevStatus, PoolManagerLib.KYBStatus newStatus);
    
    function getPoolManager(string calldata _poolManagerId) external view returns (PoolManagerLib.PoolManager memory) {
        return PoolManagerLib.getPoolManager(_poolManagerId);
    }

    function getPoolManagerUserId(string calldata _poolManagerId) external view returns (string memory) {
        return PoolManagerLib.getPoolManagerUserId(_poolManagerId);
    }

    function getPoolManagerMetaHash(string calldata _poolManagerId) external view returns (string memory) {
        return PoolManagerLib.getPoolManagerMetaHash(_poolManagerId);
    }

    function getPoolManagerCountry(string calldata _poolManagerId) external view returns (string memory) {
        return PoolManagerLib.getPoolManagerCountry(_poolManagerId);
    }

    function getPoolManagerOnBoardTime(string calldata _poolManagerId) external view returns (uint64) {
        return PoolManagerLib.getPoolManagerOnBoardTime(_poolManagerId);
    }

    function getPoolManagerWallet(string calldata _poolManagerId) external view returns (address) {
        return PoolManagerLib.getPoolManagerWallet(_poolManagerId);
    }

    function getPoolManagerKYBStatus(string calldata _poolManagerId) external view returns (PoolManagerLib.KYBStatus) {
        return PoolManagerLib.getPoolManagerKYBStatus(_poolManagerId);
    }

    function getPoolManagerPoolIdsLength(string calldata _poolManagerId) external view returns (uint256) {
        return PoolManagerLib.getPoolIdsLength(_poolManagerId);
    }

    function getPoolManagerPoolId(string calldata _poolManagerId, uint256 _index) external view returns (string memory) {
        return PoolManagerLib.getPoolId(_poolManagerId, _index);
    }

    function getPoolManagerPoolIds(string calldata _poolManagerId) external view returns (string[] memory) {
        return PoolManagerLib.getPoolIds(_poolManagerId);
    }

    function getPoolManagerPaymentIdsLength(string calldata _poolManagerId) external view returns (uint256) {
        return PoolManagerLib.getPaymentIdsLength(_poolManagerId);
    }

    function getPoolManagerPaymentId(string calldata _poolManagerId, uint256 _index) external view returns (string memory) {
        return PoolManagerLib.getPaymentId(_poolManagerId, _index);
    }

    function getPoolManagerMetadataURI(string calldata _poolManagerId) external view returns (string memory) {
        return PoolManagerLib.getMetadataURI(_poolManagerId);
    }

    function createPoolManager(
        string calldata _poolManagerId,
        string calldata _userId,
        string calldata _metaHash,
        string calldata _country,
        uint64 _onBoardTime,
        address _wallet,
        PoolManagerLib.KYBStatus _status
    ) external {
        PoolManagerLib.PoolManager memory poolManager = PoolManagerLib.createPoolManager(_poolManagerId, _userId, _metaHash, _country, _onBoardTime, _wallet, _status);
        emit CreatePoolManagerEvent(poolManager);
    }

    function deletePoolManager(string calldata _poolManagerId) external {
        PoolManagerLib.removePoolManager(_poolManagerId);
        emit DeletePoolManagerEvent(_poolManagerId);
    }

    function updatePoolManagerHash(string calldata _poolManagerId, string calldata _hash) external {
        string memory _prevHash = PoolManagerLib.getPoolManagerMetaHash(_poolManagerId);
        PoolManagerLib.updatePoolManagerHash(_poolManagerId, _hash);
        emit UpdatePoolManagerHashEvent(_poolManagerId, _prevHash, _hash);
    }

    function updatePoolManagerCountry(string calldata _poolManagerId, string calldata _country) external {
        string memory _prevCountry = PoolManagerLib.getPoolManagerCountry(_poolManagerId);
        PoolManagerLib.updatePoolManagerCountry(_poolManagerId, _country);
        emit UpdatePoolManagerCountryEvent(_poolManagerId, _prevCountry, _country);
    }

    function updatePoolManagerOnBoardTime(string calldata _poolManagerId, uint64 _onBoardTime) external {
        uint64 _prevTime = PoolManagerLib.getPoolManagerOnBoardTime(_poolManagerId);
        PoolManagerLib.updatePoolManagerOnBoardTime(_poolManagerId, _onBoardTime);
        emit UpdatePoolManagerOnBoardTimeEvent(_poolManagerId, _prevTime, _onBoardTime);
    }

    function updatePoolManagerWallet(string calldata _poolManagerId, address _wallet) external {
        address _prevWallet = PoolManagerLib.getPoolManagerWallet(_poolManagerId);
        PoolManagerLib.updatePoolManagerWallet(_poolManagerId, _wallet);
        emit UpdatePoolManagerWalletEvent(_poolManagerId, _prevWallet, _wallet);
    }

    function updatePoolManagerKYB(string calldata _poolManagerId, PoolManagerLib.KYBStatus _status) external {
        PoolManagerLib.KYBStatus _prevStatus = PoolManagerLib.getPoolManagerKYBStatus(_poolManagerId);
        PoolManagerLib.updatePoolManagerKYB(_poolManagerId, _status);
        emit UpdatePoolManagerKYBEvent(_poolManagerId, _prevStatus, _status);
    }

    function removePoolManagerPaymentId(string calldata _poolManagerId, string calldata _paymentId) external {
        PoolManagerLib.removePaymentId(_poolManagerId, _paymentId);
    }

    function removePoolManagerPaymentIdByIndex(string calldata _poolManagerId, uint256 _paymentIndex) external {
        PoolManagerLib.removePaymentIdByIndex(_poolManagerId, _paymentIndex);
    }
}