// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import "./PoolManagerFacet.sol";
import "./LenderFacet.sol";
import "./VaultFacet.sol";
import "./MetadataFacet.sol";
import "./AccessControlFacet.sol";

error CreditPoolIdExist(string _id);
error NotCreditPoolCall();
error PoolIsNotActive(string _id);
error PoolIsExpired(string _id);
error LenderIdsExist(uint256 _length);
error InvalidRoleOrPoolId(string roleId, string poolId);
error InvalidLenderOrPoolId(string roleId, string poolId);
error LenderBoundWithPool(string roleId, string poolId);
error InvalidPoolId(string poolId);
error InvalidAmount(uint256 amount);

library CreditPoolLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.creditpool.storage");

    struct CreditPoolState {
        mapping(string => CreditPool) creditPools;
        mapping(string => mapping(string => Binding)) lenderBinding;
        bool isCreditPoolCall;
    }

    struct CreditPool {
        string creditPoolId;
        string poolManagerId;
        string metaHash;
        uint256 borrowingAmount;
        uint64 inceptionTime;
        uint64 expiryTime;
        uint32 curingPeriod;
        CreditRatings ratings;
        uint16 bindingIndex;
        CreditPoolStatus status;
        string[] lenderIds;
        string[] paymentIds;
    }

    struct Binding {
        bool isBound;
        uint16 lenderIndexInPool;
        uint16 poolIndexInLender;
    }

    enum CreditRatings {PENDING, AAA, AA, A, BBB, BB, B, CCC, CC, C}

    enum CreditPoolStatus {PENDING, ACTIVE, INACTIVE}

    function diamondStorage() internal pure returns (CreditPoolState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getCreditPool(string calldata _poolId) internal view returns (CreditPool memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId];
    }

    function getCreditPoolManagerId(string calldata _poolId) internal view returns (string memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].poolManagerId;
    }

    function getCreditPoolMetaHash(string calldata _poolId) internal view returns (string memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].metaHash;
    }

    function getCreditPoolBorrowingAmount(string memory _poolId) internal view returns (uint256) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].borrowingAmount;
    }

    function getCreditPoolInceptionTime(string calldata _poolId) internal view returns (uint64) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].inceptionTime;
    }

    function getCreditPoolExpiryTime(string calldata _poolId) internal view returns (uint64) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].expiryTime;
    }

    function getCreditPoolCuringPeriod(string calldata _poolId) internal view returns (uint32) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].curingPeriod;
    }

    function getCreditPoolRatings(string calldata _poolId) internal view returns (CreditRatings) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].ratings;
    }

    function getCreditPoolBindingIndex(string calldata _poolId) internal view returns (uint16) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].bindingIndex;
    }

    function getCreditPoolStatus(string calldata _poolId) internal view returns (CreditPoolStatus) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].status;
    }

    function getLenderIdsLength(string calldata _poolId) internal view returns (uint256) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].lenderIds.length;
    }

    function getLenderId(string calldata _poolId, uint256 _index) internal view returns (string memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].lenderIds[_index];
    }

    function getPaymentIdsLength(string calldata _poolId) internal view returns (uint256) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].paymentIds.length;
    }

    function getPaymentId(string calldata _poolId, uint256 _index) internal view returns (string memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].paymentIds[_index];
    }

    function getLenderBinding(string calldata _lenderId, string calldata _poolId) internal view returns (Binding memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.lenderBinding[_lenderId][_poolId];
    }

    function getMetadataURI(string calldata _poolId) internal view returns (string memory) {
        enforceIsCreditPoolIdExist(_poolId);
        string memory _baseURI = MetadataLib.getBaseURI();
        string memory _metaHash = getCreditPoolMetaHash(_poolId);
        return bytes(_baseURI).length > 0 ? string(string.concat(bytes(_baseURI), bytes(_metaHash))) : "";
    }

    function createCreditPool(
        string calldata _creditPoolId,
        string calldata _poolManagerId,
        string calldata _metaHash,
        uint256 _borrowingAmount,
        uint64 _inceptionTime,
        uint64 _expiryTime,
        uint32 _curingPeriod,
        CreditPoolStatus _status
    ) internal returns (CreditPool memory) {
        AccessControlLib.enforceIsCreateManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(keccak256(bytes(_creditPoolId)) == keccak256(bytes(creditPoolState.creditPools[_creditPoolId].creditPoolId))) {
            revert CreditPoolIdExist(_creditPoolId);
        }
        PoolManagerLib.enforceIsPoolManagerKYBVerified(_poolManagerId);
        creditPoolState.creditPools[_creditPoolId] = CreditPool(
            _creditPoolId,
            _poolManagerId,
            _metaHash,
            _borrowingAmount,
            _inceptionTime,
            _expiryTime,
            _curingPeriod,
            CreditRatings.PENDING,
            uint16(PoolManagerLib.getPoolIdsLength(_poolManagerId)),
            _status,
            new string[](0),
            new string[](0)
        );
        creditPoolState.isCreditPoolCall = true;
        PoolManagerLib.addPoolId(_poolManagerId, _creditPoolId);
        creditPoolState.isCreditPoolCall = false;
        return creditPoolState.creditPools[_creditPoolId];
    }

    function removeCreditPool(string calldata _creditPoolId) internal {
        AccessControlLib.enforceIsDeleteManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.creditPools[_creditPoolId].lenderIds.length != 0) {
            revert LenderIdsExist(creditPoolState.creditPools[_creditPoolId].lenderIds.length);
        }
        string memory _poolManagerId = creditPoolState.creditPools[_creditPoolId].poolManagerId;
        uint16 _index = creditPoolState.creditPools[_creditPoolId].bindingIndex;
        creditPoolState.isCreditPoolCall = true;
        PoolManagerLib.removePoolIdByIndex(_poolManagerId, _index);
        creditPoolState.isCreditPoolCall = false;
        delete creditPoolState.creditPools[_creditPoolId];
    }

    function updateCreditPoolHash(string calldata _creditPoolId, string calldata _hash) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].metaHash = _hash;
    }

    function updateCreditPoolBorrowingAmount(string calldata _creditPoolId, uint256 _borrowingAmount) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        if(_borrowingAmount < VaultLib.getBorrowedAmount(_creditPoolId)) {
            revert InvalidAmount(_borrowingAmount);
        }
        creditPoolState.creditPools[_creditPoolId].borrowingAmount = _borrowingAmount;
    }

    function updateCreditPoolInceptionTime(string calldata _creditPoolId, uint64 _inceptionTime) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].inceptionTime = _inceptionTime;
    }

    function updateCreditPoolExpiryTime(string calldata _creditPoolId, uint64 _expiryTime) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].expiryTime = _expiryTime;
    }

    function updateCreditPoolCuringPeriod(string calldata _creditPoolId, uint32 _curingPeriod) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].curingPeriod = _curingPeriod;
    }

    function updateBindingIndexOfPool(string memory _creditPoolId, uint256 _bindingIndex) internal {
        enforceIsCreditPool();
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].bindingIndex = uint16(_bindingIndex);
    }

    function updateCreditRatings(string calldata _creditPoolId, CreditRatings _ratings) internal {
        AccessControlLib.enforceIsEditManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.creditPools[_creditPoolId].status != CreditPoolStatus.ACTIVE) {
            revert PoolIsNotActive(_creditPoolId);
        }
        creditPoolState.creditPools[_creditPoolId].ratings = _ratings;
    }

    function updateCreditPoolStatus(string calldata _creditPoolId, CreditPoolStatus _status) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].status = _status;
    }

    function updatePoolIndexInLender(
        string memory _lenderId,
        string memory _creditPoolId,
        uint256 _poolIndexInLender
    ) internal {
        enforceIsCreditPool();
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.lenderBinding[_lenderId][_creditPoolId].poolIndexInLender = uint16(_poolIndexInLender);
    }

    function addLenderId(string memory _creditPoolId, string memory _lenderId) internal {
        VaultLib.enforceIsVault();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.creditPools[_creditPoolId].status != CreditPoolStatus.ACTIVE) {
            revert PoolIsNotActive(_creditPoolId);
        }
        if(!creditPoolState.lenderBinding[_lenderId][_creditPoolId].isBound) {
            uint16 _lenderIndexInPool = uint16(creditPoolState.creditPools[_creditPoolId].lenderIds.length);
            uint16 _poolIndexInLender = uint16(LenderLib.getPoolIdsLength(_lenderId));
            creditPoolState.isCreditPoolCall = true;
            LenderLib.addPoolId(_lenderId, _creditPoolId);
            creditPoolState.isCreditPoolCall = false;
            creditPoolState.creditPools[_creditPoolId].lenderIds.push(_lenderId);
            creditPoolState.lenderBinding[_lenderId][_creditPoolId] = Binding(true, _lenderIndexInPool, _poolIndexInLender);
        }
    }

    function removeLenderId(string memory _creditPoolId, string memory _lenderId) internal {
        VaultLib.enforceIsVault();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.lenderBinding[_lenderId][_creditPoolId].isBound) {
            uint16 _lastLenderIndexInPool = uint16(creditPoolState.creditPools[_creditPoolId].lenderIds.length - 1);
            uint16 _lenderIndexInPool = creditPoolState.lenderBinding[_lenderId][_creditPoolId].lenderIndexInPool;
            uint16 _poolIndexInLender = creditPoolState.lenderBinding[_lenderId][_creditPoolId].poolIndexInLender;
            creditPoolState.isCreditPoolCall = true;
            LenderLib.removePoolIdByIndex(_lenderId, _poolIndexInLender);
            creditPoolState.isCreditPoolCall = false;
            if(_lenderIndexInPool != _lastLenderIndexInPool) {
                creditPoolState.creditPools[_creditPoolId].lenderIds[_lenderIndexInPool] = creditPoolState.creditPools[_creditPoolId].lenderIds[_lastLenderIndexInPool];
                string memory _lastLenderId = creditPoolState.creditPools[_creditPoolId].lenderIds[_lenderIndexInPool];
                creditPoolState.lenderBinding[_lastLenderId][_creditPoolId].lenderIndexInPool = uint16(_lenderIndexInPool);
            }
            creditPoolState.creditPools[_creditPoolId].lenderIds.pop();
            delete creditPoolState.lenderBinding[_lenderId][_creditPoolId];
        }
    }

    function addPaymentId(string memory _creditPoolId, string memory _paymentId) internal {
        VaultLib.enforceIsVault();
        CreditPoolState storage creditPoolState = diamondStorage();
        CreditPool storage creditPool = creditPoolState.creditPools[_creditPoolId];
        creditPool.paymentIds.push(_paymentId);
    }

    function removePaymentId(string calldata _creditPoolId, string calldata _paymentId) internal {
        AccessControlLib.enforceIsDeleteManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        CreditPool storage creditPool = creditPoolState.creditPools[_creditPoolId];
        uint256 index;
        for (uint256 i = 0; i < creditPool.paymentIds.length; i++) {
            if (keccak256(bytes(creditPool.paymentIds[i])) == keccak256(bytes(_paymentId))) {
                index = i;
                break;
            }
        }
        creditPool.paymentIds[index] = creditPool.paymentIds[creditPool.paymentIds.length - 1];
        creditPool.paymentIds.pop();
    }

    function removePaymentIdByIndex(string calldata _creditPoolId, uint256 _paymentIndex) internal {
        AccessControlLib.enforceIsDeleteManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        CreditPool storage creditPool = creditPoolState.creditPools[_creditPoolId];
        if(_paymentIndex != creditPool.paymentIds.length - 1) {
            creditPool.paymentIds[_paymentIndex] = creditPool.paymentIds[creditPool.paymentIds.length - 1];
        }
        creditPool.paymentIds.pop();
    }

    function enforceIsCreditPool() internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(!creditPoolState.isCreditPoolCall) {
            revert NotCreditPoolCall();
        }
    }

    function enforceIsActivePool(string memory _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.creditPools[_creditPoolId].status != CreditPoolStatus.ACTIVE) {
            revert PoolIsNotActive(_creditPoolId);
        }
    }

    function enforcePoolIsNotExpired(string memory _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(block.timestamp > creditPoolState.creditPools[_creditPoolId].expiryTime) {
            revert PoolIsExpired(_creditPoolId);
        }
    }

    function enforceIsLenderBoundWithPool(string calldata _lenderId, string calldata _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(!creditPoolState.lenderBinding[_lenderId][_creditPoolId].isBound) {
            revert InvalidLenderOrPoolId(_lenderId, _creditPoolId);
        }
    }

    function enforceLenderIsNotBoundWithPool(string calldata _lenderId, string calldata _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.lenderBinding[_lenderId][_creditPoolId].isBound) {
            revert LenderBoundWithPool(_lenderId, _creditPoolId);
        }
    }

    function enforceIsPoolManagerBoundWithPool(string calldata _poolManagerId, string calldata _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(keccak256(bytes(_poolManagerId)) != keccak256(bytes(creditPoolState.creditPools[_creditPoolId].poolManagerId))) {
            revert InvalidRoleOrPoolId(_poolManagerId, _creditPoolId);
        }
    }

    function enforceIsCreditPoolIdExist(string calldata _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(bytes(creditPoolState.creditPools[_creditPoolId].creditPoolId).length == 0) {
            revert InvalidPoolId(_creditPoolId);
        }
    }
}

contract CreditPoolFacet {
    event CreateCreditPoolEvent(CreditPoolLib.CreditPool creditPool);
    event DeleteCreditPoolEvent(string indexed poolId);
    event UpdateCreditPoolHashEvent(string indexed poolId, string prevHash, string newHash);
    event UpdateCreditPoolBorrowingAmountEvent(string indexed poolId, uint256 prevAmount, uint256 newAmount);
    event UpdateCreditPoolInceptionTimeEvent(string indexed poolId, uint64 prevTime, uint64 newTime);
    event UpdateCreditPoolExpiryTimeEvent(string indexed poolId, uint64 prevTime, uint64 newTime);
    event UpdateCreditPoolCuringPeriodEvent(string indexed poolId, uint32 prevPeriod, uint32 newPeriod);
    event UpdateCreditRatingsEvent(
        string indexed poolId,
        CreditPoolLib.CreditRatings prevRatings,
        CreditPoolLib.CreditRatings newRatings
    );
    event UpdateCreditPoolStatusEvent(
        string indexed poolId,
        CreditPoolLib.CreditPoolStatus prevStatus,
        CreditPoolLib.CreditPoolStatus newStatus
    );
    
    function getCreditPool(string calldata _poolId) external view returns (CreditPoolLib.CreditPool memory) {
        return CreditPoolLib.getCreditPool(_poolId);
    }

    function getCreditPoolManagerId(string calldata _poolId) external view returns (string memory) {
        return CreditPoolLib.getCreditPoolManagerId(_poolId);
    }

    function getCreditPoolMetaHash(string calldata _poolId) external view returns (string memory) {
        return CreditPoolLib.getCreditPoolMetaHash(_poolId);
    }

    function getCreditPoolBorrowingAmount(string calldata _poolId) external view returns (uint256) {
        return CreditPoolLib.getCreditPoolBorrowingAmount(_poolId);
    }

    function getCreditPoolInceptionTime(string calldata _poolId) external view returns (uint64) {
        return CreditPoolLib.getCreditPoolInceptionTime(_poolId);
    }

    function getCreditPoolExpiryTime(string calldata _poolId) external view returns (uint64) {
        return CreditPoolLib.getCreditPoolExpiryTime(_poolId);
    }

    function getCreditPoolCuringPeriod(string calldata _poolId) external view returns (uint32) {
        return CreditPoolLib.getCreditPoolCuringPeriod(_poolId);
    }

    function getCreditPoolRatings(string calldata _poolId) external view returns (CreditPoolLib.CreditRatings) {
        return CreditPoolLib.getCreditPoolRatings(_poolId);
    }

    function getCreditPoolBindingIndex(string calldata _poolId) external view returns (uint16) {
        return CreditPoolLib.getCreditPoolBindingIndex(_poolId);
    }

    function getCreditPoolStatus(string calldata _poolId) external view returns (CreditPoolLib.CreditPoolStatus) {
        return CreditPoolLib.getCreditPoolStatus(_poolId);
    }

    function getCreditPoolLenderIdsLength(string calldata _poolId) external view returns (uint256) {
        return CreditPoolLib.getLenderIdsLength(_poolId);
    }

    function getCreditPoolLenderId(string calldata _poolId, uint256 _index) external view returns (string memory) {
        return CreditPoolLib.getLenderId(_poolId, _index);
    }

    function getCreditPoolPaymentIdsLength(string calldata _poolId) external view returns (uint256) {
        return CreditPoolLib.getPaymentIdsLength(_poolId);
    }

    function getCreditPoolPaymentId(string calldata _poolId, uint256 _index) external view returns (string memory) {
        return CreditPoolLib.getPaymentId(_poolId, _index);
    }

    function getLenderBinding(string calldata _lenderId, string calldata _poolId) external view returns (CreditPoolLib.Binding memory) {
        return CreditPoolLib.getLenderBinding(_lenderId, _poolId);
    }

    function getCreditPoolMetadataURI(string calldata _poolId) external view returns (string memory) {
        return CreditPoolLib.getMetadataURI(_poolId);
    }

    function createCreditPool(
        string calldata _creditPoolId,
        string calldata _poolManagerId,
        string calldata _metaHash,
        uint256 _borrowingAmount,
        uint64 _inceptionTime,
        uint64 _expiryTime,
        uint32 _curingPeriod,
        CreditPoolLib.CreditPoolStatus _status
    ) external {
        CreditPoolLib.CreditPool memory creditPool = CreditPoolLib.createCreditPool(_creditPoolId, _poolManagerId, _metaHash, _borrowingAmount, _inceptionTime, _expiryTime, _curingPeriod, _status);
        emit CreateCreditPoolEvent(creditPool);
    }

    function deleteCreditPool(string calldata _creditPoolId) external {
        CreditPoolLib.removeCreditPool(_creditPoolId);
        emit DeleteCreditPoolEvent(_creditPoolId);
    }

    function updateCreditPoolHash(string calldata _creditPoolId, string calldata _hash) external {
        string memory _prevHash = CreditPoolLib.getCreditPoolMetaHash(_creditPoolId);
        CreditPoolLib.updateCreditPoolHash(_creditPoolId, _hash);
        emit UpdateCreditPoolHashEvent(_creditPoolId, _prevHash, _hash);
    }

    function updateCreditPoolBorrowingAmount(string calldata _creditPoolId, uint256 _amount) external {
        uint256 _prevAmount = CreditPoolLib.getCreditPoolBorrowingAmount(_creditPoolId);
        CreditPoolLib.updateCreditPoolBorrowingAmount(_creditPoolId, _amount);
        emit UpdateCreditPoolBorrowingAmountEvent(_creditPoolId, _prevAmount, _amount);
    }

    function updateCreditPoolInceptionTime(string calldata _creditPoolId, uint64 _time) external {
        uint64 _prevTime = CreditPoolLib.getCreditPoolInceptionTime(_creditPoolId);
        CreditPoolLib.updateCreditPoolInceptionTime(_creditPoolId, _time);
        emit UpdateCreditPoolInceptionTimeEvent(_creditPoolId, _prevTime, _time);
    }

    function updateCreditPoolExpiryTime(string calldata _creditPoolId, uint64 _time) external {
        uint64 _prevTime = CreditPoolLib.getCreditPoolExpiryTime(_creditPoolId);
        CreditPoolLib.updateCreditPoolExpiryTime(_creditPoolId, _time);
        emit UpdateCreditPoolExpiryTimeEvent(_creditPoolId, _prevTime, _time);
    }

    function updateCreditPoolCuringPeriod(string calldata _creditPoolId, uint32 _curingPeriod) external {
        uint32 _prevPeriod = CreditPoolLib.getCreditPoolCuringPeriod(_creditPoolId);
        CreditPoolLib.updateCreditPoolCuringPeriod(_creditPoolId, _curingPeriod);
        emit UpdateCreditPoolCuringPeriodEvent(_creditPoolId, _prevPeriod, _curingPeriod);
    }

    function updateCreditRatings(string calldata _creditPoolId, CreditPoolLib.CreditRatings _ratings) external {
        CreditPoolLib.CreditRatings _prevRatings = CreditPoolLib.getCreditPoolRatings(_creditPoolId);
        CreditPoolLib.updateCreditRatings(_creditPoolId, _ratings);
        emit UpdateCreditRatingsEvent(_creditPoolId, _prevRatings, _ratings);
    }

    function updateCreditPoolStatus(string calldata _creditPoolId, CreditPoolLib.CreditPoolStatus _status) external {
        CreditPoolLib.CreditPoolStatus _prevStatus = CreditPoolLib.getCreditPoolStatus(_creditPoolId);
        CreditPoolLib.updateCreditPoolStatus(_creditPoolId, _status);
        emit UpdateCreditPoolStatusEvent(_creditPoolId, _prevStatus, _status);
    }

    function removeCreditPoolPaymentId(string calldata _creditPoolId, string calldata _paymentId) external {
        CreditPoolLib.removePaymentId(_creditPoolId, _paymentId);
    }

    function removeCreditPoolPaymentIdByIndex(string calldata _creditPoolId, uint256 _paymentIndex) external {
        CreditPoolLib.removePaymentIdByIndex(_creditPoolId, _paymentIndex);
    }
}