pragma solidity >= 0.5.11;

/**
 * @title  ChainValidator interface
 * @author Jakub Fornadel
 * @notice External chain validator contract, can be used for more sophisticated validation of new validators and transactors, e.g. custom min. required conditions,
 *         concrete users whitelisting, etc...
 **/
interface ChainValidator {
    /**
     * @notice Validation function for new validators
     * 
     * @param vesting               How many tokens new validator wants to vest
     * @param acc                   Account address of the validator
     * @param mining                Flag if validator is going to mine. 
     *                               mining == false in case validateNewValidator is called during vestInChain method
     *                               mining == true in case validateNewValidator is called during startMining method
     * @param actNumOfValidators    How many active validators is currently in chain
     **/
    function validateNewValidator(uint256 vesting, address acc, bool mining, uint256 actNumOfValidators) external returns (bool);
    
    /**
     * @notice Validation function for new transactors
     * 
     * @param deposit               How many tokens new transactor wants to deposit
     * @param acc                   Account address of the transactor
     * @param actNumOfTransactors   How many whitelisted transactors (their deposit balance >= min. required balance) is currently in chain
     **/
    function validateNewTransactor(uint256 deposit, address acc, uint256 actNumOfTransactors) external returns (bool);
}

/**
 * @title  EnergyChainValidator for Lition energy chain
 * @author Jakub Fornadel
 * @notice External chain validator contract with specific conditions tailored for Lition Energy chain
 **/
contract EnergyChainValidator is ChainValidator {
    
    /**************************************************************************************************************************/
    /************************************************** Constants *************************************************************/
    /**************************************************************************************************************************/
    
    // Token precision. 1 LIT token = 1*10^18
    uint256 constant LIT_PRECISION               = 10**18;
    
    // Min deposit value
    uint256 constant MIN_DEPOSIT                 = 1000*LIT_PRECISION;
    
    // Min vesting value
    uint256 constant MIN_VESTING                 = 1000*LIT_PRECISION;
    
    // Min vesting value
    uint256 constant MAX_VESTING                 = 500000*LIT_PRECISION;
    
    bool requireWhitelistedValidators            = true;

    bool requireWhitelistedTransactors           = true;
    
    
    /**************************************************************************************************************************/
    /*********************************** Structs and functions related to the list of users ***********************************/
    /**************************************************************************************************************************/
    
    
    // Iterable map that is used only together with the Users mapping as data holder
    struct IterableMap {
        // map of indexes to the list array
        // indexes are shifted +1 compared to the real indexes of this list, because 0 means non-existing element
        mapping(address => uint256) listIndex;
        // list of addresses 
        address[]                   list;        
    }    
    
    // Adds acc from the map
    function insertAcc(IterableMap storage map, address acc) internal {
        map.list.push(acc);
        // indexes are stored + 1   
        map.listIndex[acc] = map.list.length;
    }
    
    // Removes acc from the map
    function removeAcc(IterableMap storage map, address acc) internal {
        uint256 index = map.listIndex[acc];
        require(index > 0 && index <= map.list.length, "RemoveAcc invalid index");
        
        // Move an last element of array into the vacated key slot.
        uint256 foundIndex = index - 1;
        uint256 lastIndex  = map.list.length - 1;
    
        map.listIndex[map.list[lastIndex]] = foundIndex + 1;
        map.list[foundIndex] = map.list[lastIndex];
        map.list.length--;
    
        // Deletes element
        map.listIndex[acc] = 0;
    }
    
    // Returns true, if acc exists in the iterable map, otherwise false
    function existAcc(IterableMap storage map, address acc) internal view returns (bool) {
        return map.listIndex[acc] != 0;
    }
    
    
    /**************************************************************************************************************************/
    /******************************************** Other structs and functions *************************************************/
    /**************************************************************************************************************************/


    // List of admins - they can add/remove whitelisted validators and users
    IterableMap private admins;
    
    // List of whitelisted users who can deposit
    IterableMap private whitelistedValidators;
    
    // List of whitelisted users who can deposit
    IterableMap private whitelistedTransactors;

    // Max allowed number of active validators at the same time 
    uint256     public  maxNumOfValidators;
    
    constructor() public {
        insertAcc(admins, msg.sender);
    }


    /**************************************************************************************************************************/
    /*********************************************** Contract Interface *******************************************************/
    /**************************************************************************************************************************/

    
    /**
     * @notice Validation function for new validators. All validators with vesting in range <1000, 50000> LIT tokens are allowed 
     * 
     * @param vesting               How many tokens new validator wants to vest
     * @param acc                   Account address of the validator
     * @param mining                Flag if validator is going to mine. 
     *                               mining == false in case validateNewValidator is called during vestInChain method
     *                               mining == true in case validateNewValidator is called during startMining method
     * @param actNumOfValidators    How many active validators is currently in chain
     **/
    function validateNewValidator(uint256 vesting, address acc, bool mining, uint256 actNumOfValidators) external returns (bool) {
        if (vesting < MIN_VESTING || vesting > MAX_VESTING) {
            return false;
        }
        if (maxNumOfValidators != 0 && mining == true && actNumOfValidators >= maxNumOfValidators) {
            return false;
        }
        return !requireWhitelistedValidators || existAcc(whitelistedValidators, acc);
    }
    
    /**
     * @notice Validation function for new transactors. Only whitelisted accounts are allowed
     * 
     * @param deposit               How many tokens new transactor wants to deposit
     * @param acc                   Account address of the transactor
     * @param actNumOfTransactors   How many whitelisted transactors (their deposit balance >= min. required balance) is currently in chain
     **/
    function validateNewTransactor(uint256 deposit, address acc, uint256 actNumOfTransactors) external returns (bool) {
        if (deposit < MIN_DEPOSIT) {
            return false;
        }
        
        return !requireWhitelistedTransactors || existAcc(whitelistedTransactors, acc);
    }
    
    /**
     * @notice Sets allowed max num of active validators at the same time  
     * 
     * @param num
     **/
    function setMaxNumOfValidators(uint256 num) external {
        require(existAcc(admins, msg.sender) == true, "Only admins can do internal changes");
        maxNumOfValidators = num;
    }
    
    /**
     * @notice Adds new whitelisted accounts that are allowed to deposit on Lition energy chain
     *         Provided existing accounts are ignored
     * 
     * @param accounts List of accounts
     **/
    function addWhitelistedValidator(address[] calldata accounts) external {
        addUsers(whitelistedValidators, accounts);
    }
    
    /**
     * @notice Adds new whitelisted accounts that are allowed to transact on Lition energy chain
     *         Provided existing accounts are ignored
     * 
     * @param accounts List of accounts
     **/
    function addWhitelistedTransactor(address[] calldata accounts) external {
        addUsers(whitelistedTransactors, accounts);
    }
    
    /**
     * @notice Removes existing whitelisted accounts that are allowed to deposit on Lition energy chain.
     *         Provided non-existing accounts are ignored
     * 
     * @param accounts List of accounts
     **/
    function removeWhitelistedValidators(address[] calldata accounts) external {
        require(whitelistedValidators.list.length > 0, "There are no whitelisted validators to be removed");
        
        removeUsers(whitelistedValidators, accounts);
    }
    
    /**
     * @notice Removes existing whitelisted accounts that are allowed to transact on Lition energy chain.
     *         Provided non-existing accounts are ignored
     * 
     * @param accounts List of accounts
     **/
    function removeWhitelistedTransactors(address[] calldata accounts) external {
        require(whitelistedTransactors.list.length > 0, "There are no whitelisted transactors to be removed");
        
        removeUsers(whitelistedTransactors, accounts);
    }

    /**
     * @notice Adds new admins that are allowed to add/remove whitelisted users
     *         Provided existing accounts are ignored*
     * @param accounts List of accounts
     **/
    function addAdmins(address[] calldata accounts) external {
        addUsers(admins, accounts);
    }
    
    /**
     * @notice Sets if new validators are required to be whitelisted or not
     * @param _requireWhitelistedValidators Boolean flag
     **/
    function setRequireWhitelistedValidators(bool _requireWhitelistedValidators) external {
        require(existAcc(admins, msg.sender) == true, "Only admins can do internal changes");
        requireWhitelistedValidators = _requireWhitelistedValidators;
    }

    /**
     * @notice Sets if new transactors are required to be whitelisted or not
     * @param _requireWhitelistedTransactors Boolean flag
     **/
    function setRequireWhitelistedTransactors(bool _requireWhitelistedTransactors) external {
        require(existAcc(admins, msg.sender) == true, "Only admins can do internal changes");
        requireWhitelistedTransactors = _requireWhitelistedTransactors;
    }
    
    /**
     * @notice Removes existing admin that is allowed to add/remove whitelisted users. 
     *         Provided account must exist as registered admin
     * 
     * @param account List of accounts
     **/
    function removeAdmin(address account) external {
        require(admins.list.length > 1, "Cannot remove all admins, at least one must be always present");
        require(existAcc(admins, account) == true, "Trying to remove non-existing admin");
        
        removeAcc(admins, account);
    }
    
    /**
     * @notice Returns list of admins (their accounts)
     *
     * @param batch        Batch number to be fetched. If the list is too big it cannot return all admins in one call. Instead, users are fetching batches of 100 account at a time 
     * 
     * @return accounts    List(batch of 100) of account
     * @return count       How many accounts are returned in specified batch
     * @return end         Flag if there are no more accounts left. To get all accounts, caller should fetch all batches until he sees end == true
     **/
    function getAdmins(uint256 batch) external view returns (address[100] memory accounts, uint256 count, bool end) {
        return getUsers(admins, batch);
    }
    
    /**
     * @notice Returns list of whitelisted validators (their accounts)
     *
     * @param batch        Batch number to be fetched. If the list is too big it cannot return all admins in one call. Instead, users are fetching batches of 100 account at a time 
     * 
     * @return accounts    List(batch of 100) of account
     * @return count       How many accounts are returned in specified batch
     * @return end         Flag if there are no more accounts left. To get all accounts, caller should fetch all batches until he sees end == true
     **/
    function getWhitelistedValidators(uint256 batch) external view returns (address[100] memory accounts, uint256 count, bool end) {
        return getUsers(whitelistedValidators, batch);
    }
    
    /**
     * @notice Returns list of whitelisted transactors (their accounts)
     *
     * @param batch        Batch number to be fetched. If the list is too big it cannot return all admins in one call. Instead, users are fetching batches of 100 account at a time 
     * 
     * @return accounts    List(batch of 100) of account
     * @return count       How many accounts are returned in specified batch
     * @return end         Flag if there are no more accounts left. To get all accounts, caller should fetch all batches until he sees end == true
     **/
    function getWhitelistedTransactors(uint256 batch) external view returns (address[100] memory accounts, uint256 count, bool end) {
        return getUsers(whitelistedTransactors, batch);
    }
    
    
    /*************************************************************************************************************************/
    /******************************************** Contract internal functions ************************************************/
    /*************************************************************************************************************************/

    
    // Returns list of suers users
    function getUsers(IterableMap storage internalUsersGroup, uint256 batch) internal view returns (address[100] memory users, uint256 count, bool end) {
        count = 0;
        uint256 usersTotalCount = internalUsersGroup.list.length;
        
        uint256 i;
        for(i = batch * 100; i < (batch + 1)*100 && i < usersTotalCount; i++) {
            users[count] = internalUsersGroup.list[i];
            count++;
        }
        
        if (i >= usersTotalCount) {
            end = true;
        }
        else {
            end = false;
        }
    }
    
    function addUsers(IterableMap storage internalUsersGroup, address[] memory users) internal {
        require(existAcc(admins, msg.sender) == true, "Only admins can do internal changes");
        require(users.length <= 100, "Max number of processed users is 100");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (existAcc(internalUsersGroup, users[i]) == false) {
                insertAcc(internalUsersGroup, users[i]);
            }    
        }
    }
    
    function removeUsers(IterableMap storage internalUsersGroup, address[] memory users) internal {
        require(existAcc(admins, msg.sender) == true, "Only admins can remove whitelisted users");
        require(users.length <= 100, "Max number of processed users is 100");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (existAcc(internalUsersGroup, users[i]) == true) {
                removeAcc(internalUsersGroup, users[i]);
            }    
        }
    }
}