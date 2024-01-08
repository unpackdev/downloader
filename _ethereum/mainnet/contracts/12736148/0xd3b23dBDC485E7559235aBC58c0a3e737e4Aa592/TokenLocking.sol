// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ILockedPool.sol";
import "./IlluviumAware.sol";
import "./IlluviumLockedPool.sol";
import "./Ownable.sol";

/**
 * @title Token Locking
 *
 * @notice A token holder contract that can release its token balance gradually like a
 *      typical vesting scheme, with a cliff and vesting period.
 * @notice Supports token staking for the tokens locked; staking is powered by IlluviumLockedPool (locked tokens pool)
 *
 * @notice Smart contract is deployed/initialized in 4 steps. During the initialization period the
 *      deployer is able to set locked token holders' balances and finally set the locked tokens pool
 *      to enable staking. Once final step is complete the deployer no longer can do that.
 *
 * @dev To initialize:
 *      1) deploy this smart contract (prerequisite: ILV token deployed)
 *      2) set the locked token holders and balances with `setBalances`
 *      3) transfer ILV in the amount equal to the sum of all holders' balances to the deployed instance
 *      4) [optional] set the Locked Token Pool with `setPool` (staking won't work until this is done)
 *
 * @dev The purpose of steps 2 and 3 is to have team and pre-seed investors tokens locked immediately,
 *      without giving them an ability not to lock them; in the same time we preserve an ability to stake
 *      these locked tokens
 *
 * @dev TokenLocking contract works with the token amount up to 10^7, which makes it safe
 *      to use uint96 for token amounts in the contract
 *
 * @dev Inspired by OpenZeppelin's TokenVesting.sol draft
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
contract TokenLocking is Ownable, IlluviumAware {
    /**
     * @dev Smart contract unique identifier, a random number
     * @dev Should be regenerated each time smart contact source code is changed
     *      and changes smart contract itself is to be redeployed
     * @dev Generated using https://www.random.org/bytes/
     */
    uint256 public constant LOCKING_UID = 0x76ff776d518e4c1b71ef4a1af2227a94e9868d7c9ecfa08e9255d2360e18f347;

    /// @dev Keeps the essential user data required to return (unlock) locked tokens
    struct UserRecord {
        // @dev Amount of the currently locked ILV tokens
        uint96 ilvBalance;
        // @dev ILV already unlocked (during linear unlocking period for example)
        //      Total amount of holder's tokens is the sum `balance + released`
        uint96 ilvReleased;
        // @dev Flag indicating if holder's balance was staked (sent to  Pool)
        bool hasStaked;
    }

    /// @dev Maps locked token holder address to their user record (see above)
    mapping(address => UserRecord) public userRecords;

    /// @dev Enumeration of all the locked token holders
    address[] public lockedHolders;

    /// @dev When the linear unlocking starts, unix timestamp
    uint64 public immutable cliff;
    /// @dev How long the linear unlocking takes place, seconds
    uint32 public immutable duration;

    /// @dev Link to Locked Pool used to stake locked tokens and receive vault rewards
    IlluviumLockedPool public pool;

    /// @dev Nonces to support EIP-712 based token migrations
    mapping(address => uint256) public migrationNonces;

    /**
     * @notice EIP-712 contract's domain typeHash,
     *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
     */
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /**
     * @notice EIP-712 contract's domain separator,
     *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
     */
    bytes32 public immutable DOMAIN_SEPARATOR;

    /**
     * @notice EIP-712 token migration struct typeHash,
     *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
     */
    bytes32 public constant MIGRATION_TYPEHASH =
        keccak256("Migration(address from,address to,uint256 nonce,uint256 expiry)");

    /// @dev Fired in release(), triggered by regular users (locked token holders)
    event TokensReleased(address indexed holder, uint96 amountIlv);
    /// @dev Fired in stake(), triggered by regular users (locked token holders)
    event TokensStaked(address indexed _by, address indexed pool, uint96 amount);
    /// @dev Fired in _unstakeIlv(), triggered by regular users (locked token holders)
    event TokensUnstaked(address indexed _by, address indexed pool, uint96 amount);
    /// @dev Fired in setPool(), triggered by admins only
    event PoolUpdated(address indexed _by, address indexed poolAddr);
    /// @dev Fired in setBalances(), triggered by admins only
    event LockedBalancesSet(address indexed _by, uint32 recordsNum, uint96 totalAmount);
    /// @dev Fired in migrateTokens(), triggered by admin only
    event TokensMigrated(address indexed _from, address indexed _to);

    /**
     * @dev Creates a token locking contract which integrates with the locked pool for token staking
     *      and implements linear unlocking mechanism starting at `_cliff` and lasting for `_duration`
     *
     * @param _cliff unix timestamp when the unlocking starts
     * @param _duration linear unlocking period (duration)
     * @param _ilv an address of the ILV ERC20 token
     */
    constructor(
        uint64 _cliff,
        uint32 _duration,
        address _ilv
    ) IlluviumAware(_ilv) {
        // verify the input parameters are set
        require(_cliff > 0, "cliff is not set (zero)");
        require(_duration > 0, "duration is not set (zero)");

        // init the variables
        cliff = _cliff;
        duration = _duration;

        // init the EIP-712 contract domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("TokenLocking")), block.chainid, address(this))
        );
    }

    /**
     * @dev Restricted access function to be executed by smart contract owner (admin)
     *      as a part of initialization process (step 4 - last step)
     * @dev Sets the Pool to be used for ILV staking, see `stake()`
     *
     * @dev Can be executed only once, throws if an attempt to set pool again is made
     * @dev Requires to be executed by smart contract owner
     *
     * @param _pool an address of the Pool to set
     */
    function setPool(IlluviumLockedPool _pool) external onlyOwner {
        // verify the input address is set (not zero)
        require(address(_pool) != address(0), "Pool address is not specified (zero)");
        // check that Pool was not already set before
        require(address(pool) == address(0), "Pool is already set");

        // verify the pool is of the expected type
        require(
            _pool.POOL_UID() == 0x620bbda48b8ff3098da2f0033cbf499115c61efdd5dcd2db05346782df6218e7,
            "unexpected POOL_UID"
        );

        // setup the locked tokens pool address
        pool = _pool;

        // emit an event
        emit PoolUpdated(msg.sender, address(_pool));
    }

    /**
     * @dev Restricted access function to be executed by smart contract owner (admin)
     *      as a part of initialization process (step 2)
     * @dev Sets the balances of the token owners, effectively allowing these balances to
     *      be staked and released when time comes, see `stake()`, see `release()`
     *
     * @dev Can be executed only before locked pool is set with `setPool`
     *
     * @dev Each execution overwrites the result of the previous one.
     *      Function cannot be effectively used to set bigger number of locked token holders
     *      that fits into a single block, which, however, is not required since
     *      the number of locked token holders doesn't exceed 100
     *
     * @dev Requires to be executed by smart contract owner
     * @dev Requires `owners` and `amounts` arrays sizes to match
     *
     * @param holders token holders array
     * @param amounts token holders corresponding balances
     */
    function setBalances(
        address[] memory holders,
        uint96[] memory amounts,
        uint96 expectedTotal
    ) external onlyOwner {
        // verify arrays lengths match
        require(holders.length == amounts.length, "input arr lengths mismatch");

        // we're not going to touch balances once the pool is set and staking becomes possible
        require(address(pool) == address(0), "too late: pool is already set");

        // we're not going to touch balances once linear unlocking phase starts
        require(now256() < cliff, "too late: unlocking already begun");

        // erase previously set mappings if any
        for (uint256 i = 0; i < lockedHolders.length; i++) {
            // delete old user record
            delete userRecords[lockedHolders[i]];
        }

        // update the locked holders enumeration
        lockedHolders = holders;

        // total amount set - to be used in LockedBalancesSet event log
        uint96 totalAmount = 0;

        // iterate the data supplied,
        for (uint256 i = 0; i < holders.length; i++) {
            // verify the inputs
            require(holders[i] != address(0), "zero holder address found");
            require(amounts[i] != 0, "zero amount found");

            // ensure input holders array doesn't have non-zero duplicates
            require(userRecords[holders[i]].ilvBalance == 0, "duplicate addresses found");

            // update user record's balance value (locked tokens amount)
            userRecords[holders[i]].ilvBalance = amounts[i];

            // update total amount
            totalAmount += amounts[i];
        }

        // ensure total amount is as expected
        require(totalAmount == expectedTotal, "unexpected total");

        // emit an event
        emit LockedBalancesSet(msg.sender, uint32(holders.length), totalAmount);
    }

    /**
     * @dev Reads the ILV balance of the token holder
     *
     * @param holder locked tokens holder address
     * @return token holder locked balance (ILV)
     */
    function balanceOf(address holder) external view returns (uint96) {
        // read from the storage and return
        return userRecords[holder].ilvBalance;
    }

    /**
     * @notice Checks if an address supplied has staked its tokens

     * @dev A shortcut to userRecords.hasStaked flag
     *
     * @param holder an address to query staked flag for
     * @return whether the token holder has already staked or not
     */
    function hasStaked(address holder) external view returns (bool) {
        // read from the storage and return
        return userRecords[holder].hasStaked;
    }

    /**
     * @notice Transfers vested tokens back to beneficiary, is executed after
     *      locked tokens get unlocked (at least partially)
     *
     * @notice When releasing the staked tokens `useSILV` determines if the reward
     *      is returned back as an sILV token (true) or if an ILV deposit is created (false)
     *
     * @dev Throws if executed before `cliff` timestamp
     * @dev Throws if there are no tokens to release
     */
    function release() external {
        UserRecord storage userRecord = userRecords[msg.sender];
        // calculate how many tokens are available for the sender to withdraw
        uint96 unreleasedIlv = releasableAmount(msg.sender);

        // ensure there are some tokens to withdraw
        require(unreleasedIlv > 0, "no tokens are due");

        // update balance and released user counters
        userRecord.ilvBalance -= unreleasedIlv;
        userRecord.ilvReleased += unreleasedIlv;

        // when the tokens were previously staked
        if (userRecord.hasStaked) {
            // unstake these tokens - delegate to internal `_unstakeIlv`
            _unstakeIlv(unreleasedIlv);
        }
        // transfer the tokens back to the holder
        transferIlv(msg.sender, unreleasedIlv);

        // emit an event
        emit TokensReleased(msg.sender, unreleasedIlv);
    }

    /**
     * @notice Stakes the tokens into the Pool,
     *      effectively transferring them into the pool;
     *      can be called by the locked token holders only once
     *
     * @dev Throws if Pool is not set (see initialization), if holder has already staked
     *      or of holder is not registered within the smart contract and its balance is zero
     */
    function stake() external {
        // verify Pool address has been set
        require(address(pool) != address(0), "pool is not set");

        // get a link to a user record
        UserRecord storage userRecord = userRecords[msg.sender];

        // verify holder hasn't already staked
        require(!userRecord.hasStaked, "tokens already staked");

        // read holder's balance into the stack
        uint96 amount = userRecord.ilvBalance;

        // verify the balance is positive
        require(amount > 0, "nothing to stake");

        // update the staked flag in user records
        userRecord.hasStaked = true;

        // transfer the tokens into the pool, staking them
        pool.stakeLockedTokens(msg.sender, amount);

        // emit an event
        emit TokensStaked(msg.sender, address(pool), amount);
    }

    // @dev Releases staked ilv tokens, called internally
    function _unstakeIlv(uint96 amount) private {
        // unstake from the pool
        // we assume locking deposit is #0 which is by design of pool
        pool.unstakeLockedTokens(msg.sender, amount);
        // and emit an event
        emit TokensUnstaked(msg.sender, address(pool), amount);
    }

    /**
     * @notice Moves locked tokens between two addresses. Designed to be used
     *      in emergency situations when locked token holder suspects their
     *      account credentials ware revealed
     *
     * @dev Executed by contract owner on behalf of the locked tokens holder
     *
     * @dev Compliant with EIP-712: Ethereum typed structured data hashing and signing,
     *      see https://eips.ethereum.org/EIPS/eip-712
     *
     * @dev The procedure of signing the migration with signature request is:
     *      1. Construct the EIP712Domain as per https://eips.ethereum.org/EIPS/eip-712,
     *          version and salt are omitted:
     *          {
     *              name: "TokenLocking",
     *              chainId: await web3.eth.net.getId(),
     *              verifyingContract: <deployed TokenLocking address>
     *          }
     *      2. Construct the EIP712 domainSeparator:
     *          domainSeparator = hashStruct(eip712Domain)
     *      3. Construct the EIP721 TypedData:
     *          primaryType: "Migration",
     *          types: {
     *              Migration: [
     *                  {name: 'from', type: 'address'},
     *                  {name: 'to', type: 'address'},
     *                  {name: 'nonce', type: 'uint256'},
     *                  {name: 'expiry', type: 'uint256'}
     *              ]
     *          }
     *      4. Build the message to sign:
     *          {
     *              from: _from,
     *              to: _to,
     *              nonce: _nonce,
     *              exp: _exp
     *          }
     *       5. Build the structHash as per EIP712 and sign it
     *          (see example https://github.com/ethereum/EIPs/blob/master/assets/eip-712/Example.js)
     *
     * @dev Refer to EIP712 code examples:
     *      https://github.com/ethereum/EIPs/blob/master/assets/eip-712/Example.sol
     *      https://github.com/ethereum/EIPs/blob/master/assets/eip-712/Example.js
     *
     * @dev See TokenLocking-ns.test.js for the exact working examples with TokenLocking.sol
     *
     * @param _from an address to move locked tokens from
     * @param _to an address to move locked tokens to
     * @param _nonce nonce used to construct the signature, and used to validate it;
     *      nonce is increased by one after successful signature validation and vote delegation
     * @param _exp signature expiration time
     * @param v the recovery byte of the signature
     * @param r half of the ECDSA signature pair
     * @param s half of the ECDSA signature pair
     */
    function migrateWithSig(
        address _from,
        address _to,
        uint256 _nonce,
        uint256 _exp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // build the EIP-712 hashStruct of the delegation message
        bytes32 hashStruct = keccak256(abi.encode(MIGRATION_TYPEHASH, _from, _to, _nonce, _exp));

        // calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

        // recover the address who signed the message with v, r, s
        address signer = ecrecover(digest, v, r, s);

        // perform message integrity and security validations
        require(signer != address(0), "invalid signature");
        require(_nonce == migrationNonces[signer], "invalid nonce");
        require(now256() < _exp, "signature expired");

        // verify signature: it should be either token owner or contract owner
        require(
            (signer == _from && msg.sender == owner()) || (signer == owner() && msg.sender == _from),
            "access denied"
        );

        // update the nonce for that particular signer to avoid replay attack
        migrationNonces[signer]++;

        // delegate call to `__migrateTokens` - execute the logic required
        __migrateTokens(_from, _to);
    }

    /**
     * @dev Moves locked tokens from `_from` address to `_to` address
     * @dev Designed to be used in emergency situations when locked token
     *      holder suspects their account credentials ware revealed
     *
     * @param _from an address to move locked tokens from
     * @param _to an address to move locked tokens to
     */
    function __migrateTokens(address _from, address _to) private {
        // verify `_to` is set
        require(_to != address(0), "receiver is not set");

        // following 2 verifications also ensure _to != _from
        // verify `_from` user record exists
        require(userRecords[_from].ilvBalance != 0 || userRecords[_from].ilvReleased != 0, "sender doesn't exist");
        // verify `_to` user record doesn't exist
        require(userRecords[_to].ilvBalance == 0 && userRecords[_to].ilvReleased == 0, "recipient already exists");

        // move user record from `_from` to `_to`
        userRecords[_to] = userRecords[_from];
        // delete old user record
        delete userRecords[_from];

        // if locking pool is defined
        if (address(pool) != address(0)) {
            // register this change within the pool
            pool.changeLockedHolder(_from, _to);
        }

        // push new locked holder into locked holders array
        lockedHolders.push(_to);
        // note: we do not delete old locked holder from the array since by design old account
        // is treated as a compromised one and should not be used, meaning it is always safe to erase it

        // emit an event
        emit TokensMigrated(_from, _to);
    }

    /**
     * @notice Calculates token amount available for holder to be released
     *
     * @param holder an address to query releasable amount for
     * @return ilvAmt amount of ILV tokens available for withdrawal (see release function)
     */
    function releasableAmount(address holder) public view returns (uint96 ilvAmt) {
        // calculate a difference between amount of tokens available for
        // withdrawal currently (vested amount) and amount of tokens already withdrawn (released)
        return vestedAmount(holder) - userRecords[holder].ilvReleased;
    }

    /**
     * @notice Calculates the amount to be unlocked for the given holder at the
     *      current moment in time (vested amount)
     *
     * @dev This function implements the linear unlocking mechanism based on
     *      the `cliff` and `duration` global variables as parameters:
     *      amount is zero before `cliff`, then linearly increases during `duration` period,
     *      and reaches the total holder's locked balance after that
     *
     * @dev See `linearUnlockAmt()` function for linear unlocking internals
     *
     * @param holder an address to query unlocked (vested) amount for
     * @return ilvAmt amount of ILV tokens to be unlocked based on the holder's locked balance and current time,
     *      the value is zero before `cliff`, then linearly increases during `duration` period,
     *      and reaches the total holder's locked balance after that
     */
    function vestedAmount(address holder) public view returns (uint96 ilvAmt) {
        // before `cliff` we don't need to access the storage:
        if (now256() < cliff) {
            // the return values are zeros
            return 0;
        }

        // read user record values into the memory
        UserRecord memory userRecord = userRecords[holder];

        // the value is calculated as a linear function of time
        ilvAmt = linearUnlockAmt(userRecord.ilvBalance + userRecord.ilvReleased);

        // return the result is unnecessary, but we stick to the single code style
        return ilvAmt;
    }

    /**
     * @notice Linear unlocking function of time, expects balance as an input,
     *      uses current time, `cliff` and `duration` set in the smart contract state vars
     *
     * @param balance value to calculate linear unlocking fraction for
     * @return linear unlocking fraction; zero before `cliff`, `balance` after `cliff + duration`
     */
    function linearUnlockAmt(uint96 balance) public view returns (uint96) {
        // read current time value
        uint256 _now256 = now256();

        // and fit it into the safe bounds [cliff, cliff + duration] to be used in linear unlocking function
        if (_now256 < cliff) {
            _now256 = cliff;
        } else if (_now256 - cliff > duration) {
            _now256 = cliff + duration;
        }

        // the value is calculated as a linear function of time
        return uint96((balance * (_now256 - cliff)) / duration);
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }
}
