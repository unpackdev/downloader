pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

// For test suite

contract IAccountStorage {
    function getOperationKeyCount(address _account) external view returns(uint256);
    function getKeyData(address _account, uint256 _index) public view returns(address);
    function getKeyStatus(address _account, uint256 _index) external view returns(uint256);

    function getBackupAddress(address _account, uint256 _index) external view returns(address);
    function getBackupEffectiveDate(address _account, uint256 _index) external view returns(uint256);
    function getBackupExpiryDate(address _account, uint256 _index) external view returns(uint256);

}

contract ILogic {
    function getKeyNonce(address _key) external view returns(uint256);
}

contract ILogicManager {
    function getAuthorizedLogics() external view returns (address[] memory);
}

contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @dev Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}


contract MKStorageHelper is Owned {

    address public mkStorage = 0xADc92d1fD878580579716d944eF3460E241604b7;
    address public mkLogicManager = 0xDF8aC96BC9198c610285b3d1B29de09621B04528;

    uint256 public maxBackup = 1;


    struct KeyDataItem {
        uint256 index;
        address pubKey;
        uint256 status;
        uint256 maxNonce;
    }

    struct BackupDataItem {
        uint256 index;
        address backup;
        uint256 effectiveDate;
        uint256 expiryDate;
    }

    function getStorage() public view returns(address) {
        return mkStorage;
    }

    function setStorage(address a) public onlyOwner {
        mkStorage = a;
    }

    function setLogicManager(address a) public onlyOwner {
        mkLogicManager = a;
    }

    function setMaxBackup(uint256 a) public onlyOwner {
        maxBackup = a;
    }



    /* 
     * 
     */
    function getAccountData(address account) public view returns(KeyDataItem[] memory, BackupDataItem[] memory){

        uint256 len = IAccountStorage(mkStorage).getOperationKeyCount(account) + 1; // admin


        address[] memory logics = ILogicManager(mkLogicManager).getAuthorizedLogics();

        KeyDataItem[] memory kd = new KeyDataItem[](len);
        
        for (uint256 i = 0; i < len; i++) {
            KeyDataItem memory item;
            item.index = i;
            item.pubKey = IAccountStorage(mkStorage).getKeyData(account, i);
            item.status = IAccountStorage(mkStorage).getKeyStatus(account, i);
            item.maxNonce = 0;

            // loop logics
            for (uint256 j = 0; j < logics.length; j++) {
                uint256 nonce = ILogic(logics[j]).getKeyNonce(item.pubKey);
                if (nonce > item.maxNonce) {
                    item.maxNonce = nonce;
                }
            }

            kd[i] = item;
        }


        BackupDataItem[] memory bd = new BackupDataItem[](maxBackup);

        for (uint256 i = 0; i < maxBackup; i++) {

            BackupDataItem memory item;
            item.index = i;
            item.backup = IAccountStorage(mkStorage).getBackupAddress(account, i);
            item.effectiveDate = IAccountStorage(mkStorage).getBackupEffectiveDate(account, i);
            item.expiryDate = IAccountStorage(mkStorage).getBackupExpiryDate(account, i);
            
            bd[i] = item;
        }


        return (kd, bd);


    }
}