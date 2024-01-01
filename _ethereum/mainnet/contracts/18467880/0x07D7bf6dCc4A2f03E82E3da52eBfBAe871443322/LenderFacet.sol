// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import "./CreditPoolFacet.sol";
import "./VaultFacet.sol";
import "./MetadataFacet.sol";
import "./AccessControlFacet.sol";

error NotLender(address _user, address _lender);
error LenderIdExist(string _id);
error PoolIdsExist(uint256 _length);
error NotVerifiedLender(string _id);
error InvalidLenderId(string _id);

library LenderLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.lender.storage");

    struct LenderState {
        mapping(string => Lender) lenders;
    }

    struct Lender {
        string lenderId;
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

    function diamondStorage() internal pure returns (LenderState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getLender(string calldata _lenderId) internal view returns (Lender memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId];
    }

    function getLenderUserId(string calldata _lenderId) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].userId;
    }

    function getLenderMetaHash(string calldata _lenderId) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].metaHash;
    }

    function getLenderCountry(string calldata _lenderId) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].country;
    }

    function getLenderOnBoardTime(string calldata _lenderId) internal view returns (uint64) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].onBoardTime;
    }

    function getLenderWallet(string calldata _lenderId) internal view returns (address) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].wallet;
    }

    function getLenderKYBStatus(string calldata _lenderId) internal view returns (KYBStatus) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].status;
    }

    function getPoolIdsLength(string memory _lenderId) internal view returns (uint256) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].poolIds.length;
    }

    function getPoolId(string calldata _lenderId, uint256 _index) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].poolIds[_index];
    }

    function getPoolIds(string calldata _lenderId) internal view returns (string[] memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].poolIds;
    }

    function getPaymentIdsLength(string calldata _lenderId) internal view returns (uint256) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].paymentIds.length;
    }

    function getPaymentId(string calldata _lenderId, uint256 _index) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].paymentIds[_index];
    }

    function getMetadataURI(string calldata _lenderId) internal view returns (string memory) {
        enforceIsLenderIdExist(_lenderId);
        string memory _baseURI = MetadataLib.getBaseURI();
        string memory _metaHash = getLenderMetaHash(_lenderId);
        return bytes(_baseURI).length > 0 ? string(string.concat(bytes(_baseURI), bytes(_metaHash))) : "";
    }

    function createLender(
        string calldata _lenderId,
        string calldata _userId,
        string calldata _metaHash,
        string calldata _country,
        uint64 _onBoardTime,
        address _wallet,
        KYBStatus _status
    ) internal returns (Lender memory) {
        AccessControlLib.enforceIsCreateManager();
        LenderState storage lenderState = diamondStorage();
        if(keccak256(bytes(_lenderId)) == keccak256(bytes(lenderState.lenders[_lenderId].lenderId))) {
            revert LenderIdExist(_lenderId);
        }
        lenderState.lenders[_lenderId] = Lender(_lenderId, _userId, _metaHash, _country, _onBoardTime, _wallet, _status, new string[](0), new string[](0));
        return lenderState.lenders[_lenderId];
    }

    function removeLender(string calldata _lenderId) internal {
        AccessControlLib.enforceIsDeleteManager();
        LenderState storage lenderState = diamondStorage();
        if(lenderState.lenders[_lenderId].poolIds.length != 0) {
            revert PoolIdsExist(lenderState.lenders[_lenderId].poolIds.length);
        }
        delete lenderState.lenders[_lenderId];
    }

    function updateLenderHash(string calldata _lenderId, string calldata _hash) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].metaHash = _hash;
    }

    function updateLenderCountry(string calldata _lenderId, string calldata _country) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].country = _country;
    }

    function updateLenderOnBoardTime(string calldata _lenderId, uint64 _onBoardTime) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].onBoardTime = _onBoardTime;
    }

    function updateLenderWallet(string calldata _lenderId, address _wallet) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].wallet = _wallet;
    }

    function updateLenderKYB(string calldata _lenderId, KYBStatus _status) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].status = _status;
    }

    function addPoolId(string memory _lenderId, string memory _poolId) internal {
        CreditPoolLib.enforceIsCreditPool();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        lender.poolIds.push(_poolId);
    }

    function removePoolIdByIndex(string memory _lenderId, uint256 _poolIndex) internal {
        CreditPoolLib.enforceIsCreditPool();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        if(_poolIndex != lender.poolIds.length - 1) {
            lender.poolIds[_poolIndex] = lender.poolIds[lender.poolIds.length - 1];
            string memory _poolId = lender.poolIds[_poolIndex];
            CreditPoolLib.updatePoolIndexInLender(_lenderId, _poolId, _poolIndex);
        }
        lender.poolIds.pop();
    }
    
    function addPaymentId(string memory _lenderId, string memory _paymentId) internal {
        VaultLib.enforceIsVault();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        lender.paymentIds.push(_paymentId);
    }

    function removePaymentId(string calldata _lenderId, string calldata _paymentId) internal {
        AccessControlLib.enforceIsDeleteManager();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        uint256 index;
        for (uint256 i = 0; i < lender.paymentIds.length; i++) {
            if (keccak256(bytes(lender.paymentIds[i])) == keccak256(bytes(_paymentId))) {
                index = i;
                break;
            }
        }
        lender.paymentIds[index] = lender.paymentIds[lender.paymentIds.length - 1];
        lender.paymentIds.pop();
    }

    function removePaymentIdByIndex(string calldata _lenderId, uint256 _paymentIndex) internal {
        AccessControlLib.enforceIsDeleteManager();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        if(_paymentIndex != lender.paymentIds.length - 1) {
            lender.paymentIds[_paymentIndex] = lender.paymentIds[lender.paymentIds.length - 1];
        }
        lender.paymentIds.pop();
    }

    function enforceIsLender(string calldata _lenderId) internal view {
        LenderState storage lenderState = diamondStorage();
        if(msg.sender != lenderState.lenders[_lenderId].wallet) {
            revert NotLender(msg.sender, lenderState.lenders[_lenderId].wallet);
        }
    }

    function enforceIsLenderKYBVerified(string memory _lenderId) internal view {
        LenderState storage lenderState = diamondStorage();
        if(lenderState.lenders[_lenderId].status != KYBStatus.VERIFIED) {
            revert NotVerifiedLender(_lenderId);
        }
    }

    function enforceIsLenderIdExist(string calldata _lenderId) internal view {
        LenderState storage lenderState = diamondStorage();
        if(bytes(lenderState.lenders[_lenderId].lenderId).length == 0) {
            revert InvalidLenderId(_lenderId);
        }
    }

}

contract LenderFacet {
    event DeleteLenderEvent(string indexed lenderId);
    event CreateLenderEvent(LenderLib.Lender lender);
    event UpdateLenderHashEvent(string indexed lenderId, string prevHash, string newHash);
    event UpdateLenderCountryEvent(string indexed lenderId, string prevCountry, string newCountry);
    event UpdateLenderOnBoardTimeEvent(string indexed lenderId, uint64 prevTime, uint64 newTime);
    event UpdateLenderWalletEvent(string indexed lenderId, address prevWallet, address newWallet);
    event UpdateLenderKYBEvent(string indexed lenderId, LenderLib.KYBStatus prevStatus, LenderLib.KYBStatus newStatus);
    
    function getLender(string calldata _lenderId) external view returns (LenderLib.Lender memory) {
        return LenderLib.getLender(_lenderId);
    }

    function getLenderUserId(string calldata _lenderId) external view returns (string memory) {
        return LenderLib.getLenderUserId(_lenderId);
    }

    function getLenderMetaHash(string calldata _lenderId) external view returns (string memory) {
        return LenderLib.getLenderMetaHash(_lenderId);
    }

    function getLenderCountry(string calldata _lenderId) external view returns (string memory) {
        return LenderLib.getLenderCountry(_lenderId);
    }

    function getLenderOnBoardTime(string calldata _lenderId) external view returns (uint64) {
        return LenderLib.getLenderOnBoardTime(_lenderId);
    }

    function getLenderWallet(string calldata _lenderId) external view returns (address) {
        return LenderLib.getLenderWallet(_lenderId);
    }

    function getLenderKYBStatus(string calldata _lenderId) external view returns (LenderLib.KYBStatus) {
        return LenderLib.getLenderKYBStatus(_lenderId);
    }

    function getLenderPoolIdsLength(string calldata _lenderId) external view returns (uint256) {
        return LenderLib.getPoolIdsLength(_lenderId);
    }

    function getLenderPoolId(string calldata _lenderId, uint256 _index) external view returns (string memory) {
        return LenderLib.getPoolId(_lenderId, _index);
    }

    function getLenderPoolIds(string calldata _lenderId) external view returns (string[] memory) {
        return LenderLib.getPoolIds(_lenderId);
    }

    function getLenderPaymentIdsLength(string calldata _lenderId) external view returns (uint256) {
        return LenderLib.getPaymentIdsLength(_lenderId);
    }

    function getLenderPaymentId(string calldata _lenderId, uint256 _index) external view returns (string memory) {
        return LenderLib.getPaymentId(_lenderId, _index);
    }

    function getLenderMetadataURI(string calldata _lenderId) external view returns (string memory) {
        return LenderLib.getMetadataURI(_lenderId);
    }

    function createLender(
        string calldata _lenderId,
        string calldata _userId,
        string calldata _metaHash,
        string calldata _country,
        uint64 _onBoardTime,
        address _wallet,
        LenderLib.KYBStatus _status
    ) external {
        LenderLib.Lender memory lender = LenderLib.createLender(_lenderId, _userId, _metaHash, _country, _onBoardTime, _wallet, _status);
        emit CreateLenderEvent(lender);
    }

    function deleteLender(string calldata _lenderId) external {
        LenderLib.removeLender(_lenderId);
        emit DeleteLenderEvent(_lenderId);
    }

    function updateLenderHash(string calldata _lenderId, string calldata _hash) external {
        string memory _prevHash = LenderLib.getLenderMetaHash(_lenderId);
        LenderLib.updateLenderHash(_lenderId, _hash);
        emit UpdateLenderHashEvent(_lenderId, _prevHash, _hash);
    }

    function updateLenderCountry(string calldata _lenderId, string calldata _country) external {
        string memory _prevCountry = LenderLib.getLenderCountry(_lenderId);
        LenderLib.updateLenderCountry(_lenderId, _country);
        emit UpdateLenderCountryEvent(_lenderId, _prevCountry, _country);
    }

    function updateLenderOnBoardTime(string calldata _lenderId, uint64 _onBoardTime) external {
        uint64 _prevTime = LenderLib.getLenderOnBoardTime(_lenderId);
        LenderLib.updateLenderOnBoardTime(_lenderId, _onBoardTime);
        emit UpdateLenderOnBoardTimeEvent(_lenderId, _prevTime, _onBoardTime);
    }

    function updateLenderWallet(string calldata _lenderId, address _wallet) external {
        address _prevWallet = LenderLib.getLenderWallet(_lenderId);
        LenderLib.updateLenderWallet(_lenderId, _wallet);
        emit UpdateLenderWalletEvent(_lenderId, _prevWallet, _wallet);
    }

    function updateLenderKYB(string calldata _lenderId, LenderLib.KYBStatus _status) external {
        LenderLib.KYBStatus _prevStatus = LenderLib.getLenderKYBStatus(_lenderId);
        LenderLib.updateLenderKYB(_lenderId, _status);
        emit UpdateLenderKYBEvent(_lenderId, _prevStatus, _status);
    }

    function removeLenderPaymentId(string calldata _lenderId, string calldata _paymentId) external {
        LenderLib.removePaymentId(_lenderId, _paymentId);
    }

    function removeLenderPaymentIdByIndex(string calldata _lenderId, uint256 _paymentIndex) external {
        LenderLib.removePaymentIdByIndex(_lenderId, _paymentIndex);
    }
}