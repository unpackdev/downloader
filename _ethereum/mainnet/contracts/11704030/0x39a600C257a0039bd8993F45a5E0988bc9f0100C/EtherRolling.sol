//
// $$$$$$$$\ $$$$$$$$\ $$\   $$\ $$$$$$$$\ $$$$$$$\        $$$$$$$\   $$$$$$\  $$\       $$\       $$$$$$\ $$\   $$\  $$$$$$\  
// $$  _____|\__$$  __|$$ |  $$ |$$  _____|$$  __$$\       $$  __$$\ $$  __$$\ $$ |      $$ |      \_$$  _|$$$\  $$ |$$  __$$\ 
// $$ |         $$ |   $$ |  $$ |$$ |      $$ |  $$ |      $$ |  $$ |$$ /  $$ |$$ |      $$ |        $$ |  $$$$\ $$ |$$ /  \__|
// $$$$$\       $$ |   $$$$$$$$ |$$$$$\    $$$$$$$  |      $$$$$$$  |$$ |  $$ |$$ |      $$ |        $$ |  $$ $$\$$ |$$ |$$$$\ 
// $$  __|      $$ |   $$  __$$ |$$  __|   $$  __$$<       $$  __$$< $$ |  $$ |$$ |      $$ |        $$ |  $$ \$$$$ |$$ |\_$$ |
// $$ |         $$ |   $$ |  $$ |$$ |      $$ |  $$ |      $$ |  $$ |$$ |  $$ |$$ |      $$ |        $$ |  $$ |\$$$ |$$ |  $$ |
// $$$$$$$$\    $$ |   $$ |  $$ |$$$$$$$$\ $$ |  $$ |      $$ |  $$ | $$$$$$  |$$$$$$$$\ $$$$$$$$\ $$$$$$\ $$ | \$$ |\$$$$$$  |
// \________|   \__|   \__|  \__|\________|\__|  \__|      \__|  \__| \______/ \________|\________|\______|\__|  \__| \______/ 
                                                                                                                            
                                                                                                                            
pragma solidity 0.6.8;
// SPDX-License-Identifier: NONE

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 _interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract EtherRolling is Ownable {
    using SafeMath for uint8;
    using SafeMath for uint256;
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        bool isWithdrawActive;
    }
    struct matrixInfo{
        address upperLevel;
        uint256 currentPos;
        address[3] matrixRef;
        uint256 matrix_bonus;
        uint8 level;
        uint256 first_deposit_time;
        address[] totalRefs;
        uint256 total_volume;
        bool isAlreadyInPool;
        uint256 leader_bonus;
        
    }
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC777 private _token;
    event DoneDeposit(address operator, address from, address to, uint256 amount, bytes userData, bytes operatorData);
    mapping(address => User) public users;
    mapping(address => matrixInfo) public matrixUser;

    uint256[] public cycles;
    bool public isEthDepoPaused;
    uint8 public DAILY = 6; //Daily percentage income
    uint256 public minDeposit = 0.5 ether;
    uint8[] public ref_bonuses = [10,10,10,10,10,7,7,7,7,7,3,3,3,3,3];  //referral bonuses        
    uint8[] public matrixBonuses = [7,7,7,7,7,10,10,10,10,10,3,3,3,3,3]; //Matrix bonuses
    uint256[] public pool_bonuses;
    uint40 public last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint256 public leader_pool;
    uint256[] public level_bonuses;
    uint8 public firstPool = 40;
    uint8 public secondPool = 30;
    uint8 public thirdPool = 20;
    uint8 public fourthPool = 10;
    address[] public teamLeaders;
    address payable public admin1 = 0x231c02e6ADADc34c2eFBD74e013e416b31940d15;
    address payable public admin2 = 0xbBe1B325957fD7A33BC02cDF91a29FdE88bA60E3;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event EmergencyWithdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address token) public {
        
        for(uint8 i=0;i<3;i++){
             pool_bonuses.push(firstPool.div(3));
        }
        for(uint8 i=0;i<3;i++){
             pool_bonuses.push(secondPool.div(3));
        }
        for(uint8 i=0;i<3;i++){
             pool_bonuses.push(thirdPool.div(3));
        }
        for(uint8 i=0;i<3;i++){
             pool_bonuses.push(fourthPool.div(3));
        }
        
        level_bonuses.push(0.5 ether);
        level_bonuses.push(1 ether);
        level_bonuses.push(3 ether);
        level_bonuses.push(5 ether);
        level_bonuses.push(10 ether);
        level_bonuses.push(20 ether);
        level_bonuses.push(30 ether);
        level_bonuses.push(50 ether);
        level_bonuses.push(70 ether);
        level_bonuses.push(100 ether);

        cycles.push(100 ether);
        cycles.push(300 ether);
        cycles.push(900 ether);
        cycles.push(2700 ether);
        _token = IERC777(token);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && (users[_upline].deposit_time > 0 || _upline == owner())) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            matrixUser[_upline].totalRefs.push(_addr);
            emit Upline(_addr, _upline);
            addToMatrix(_addr,_upline);
            for(uint8 i = 0; i < 15; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }
    function addToMatrix(address addr, address upline) private {
        address tempadd = upline;
        uint256 temp;
        while(true){
            uint256 pos = matrixUser[tempadd].currentPos;
            if(matrixUser[tempadd].matrixRef[pos] == address(0)){
                matrixUser[tempadd].matrixRef[pos] = addr;
                matrixUser[tempadd].currentPos = (pos + 1).mod(3);
                break;
            }else{
                temp =  matrixUser[tempadd].currentPos;
                matrixUser[tempadd].currentPos = (pos + 1).mod(3);
                tempadd = matrixUser[tempadd].matrixRef[temp];
            }
        }
        matrixUser[addr].upperLevel = tempadd;
    }
    
    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external {
        require(msg.sender == address(_token), "Invalid token");
        require(users[from].upline != address(0),"No referral found. ");
        _deposit(from,amount,1);
    }

    function _deposit(address _addr, uint256 _amount, uint8 method) private {
        require(users[_addr].upline != address(0) || _addr == owner(), "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            if(method == 0){
                require(!isEthDepoPaused,"Depositing Ether is paused");
            }
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > 3 ? 3 : users[_addr].cycle], "Bad amount");
        }
        else {
            if(method == 0){
            require(_amount >= minDeposit && _amount <= cycles[0], "Bad amount");
            require(!isEthDepoPaused,"Depositing Ether is paused");
            matrixUser[_addr].first_deposit_time = block.timestamp;
            }
            else if(method == 1){
                require(_amount >= minDeposit && _amount <= cycles[0], "Bad amount");
            }else{
                revert();
            }
        }
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;
        users[_addr].isWithdrawActive = true;
        for(uint8 i=0;i<10;i++){
            if(users[_addr].total_deposits >= level_bonuses[i]){
                matrixUser[_addr].level = i+6;
            }
        }
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _poolDeposits(_addr, _amount);
        _teamLeaderBonus(_addr,_amount);

        if(last_draw + 7 days < block.timestamp) {
            _drawPool();
        }
        if(method == 0){
            admin1.transfer(_amount.mul(95).div(1000));
            admin2.transfer(_amount.mul(5).div(1000));
        }else if(method == 1){
            _token.send(admin1,_amount.mul(95).div(1000),"Admin 1 commision");
            _token.send(admin2,_amount.mul(5).div(1000),"Admin 2 commision");
        }else{
            revert();
        }
    }
    
    function _poolDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < 12; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < 12; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= 12; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(12 - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }
    
    function _teamLeaderBonus(address addr, uint256 amount) private {
        leader_pool += amount / 50;
        address upline = users[addr].upline;
        if(upline == address(0)) return;
        matrixUser[upline].total_volume += amount;
        if(matrixUser[upline].isAlreadyInPool) return;
        uint256 volume = users[upline].total_deposits;
        uint256 len = matrixUser[upline].totalRefs.length;
        uint8 count = 0;
        for(uint40 i = 0; i < len; i++){
            volume += matrixUser[matrixUser[upline].totalRefs[i]].total_volume;
            if(matrixUser[matrixUser[upline].totalRefs[i]].total_volume >= 200 ether){
                count++;
            }
        }
        if(count >= 3){
            if((volume >= 1000 ether && matrixUser[upline].first_deposit_time + 30 days <= now) || (volume >= 10000 ether)){
                teamLeaders.push(upline);
                matrixUser[upline].isAlreadyInPool = true;
            }
        }
        
    }
    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < 15; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
        last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance;
        uint256 len = teamLeaders.length;
        for(uint8 i = 0; i < 12; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < 12; i++) {
            pool_top[i] = address(0);
        }
        
        for(uint256 i = 0; i < len; i++){
            matrixUser[teamLeaders[i]].leader_bonus += leader_pool/len;
            leader_pool -= leader_pool/len;
        }
    }
    
    function calcMatrixBonus(address addr, uint256 value) private{
        address uplevel = matrixUser[addr].upperLevel;
        uint8 i = 0;
        while(uplevel != address(0) && matrixUser[uplevel].level >= i && i<16){
            matrixUser[uplevel].matrix_bonus += value.mul(matrixBonuses[i]).div(100);
            uplevel = matrixUser[uplevel].upperLevel;
            i++;
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value, 0);
    }

    function withdraw(uint8 coin) external {
        //coin = 1 --> token withdraw
        //coin = 0 --> ether withdraw
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }
        
        // Matrix payout
        if(users[msg.sender].payouts < max_payout && matrixUser[msg.sender].matrix_bonus > 0) {
            if(users[msg.sender].isWithdrawActive){
                uint256 matrix_bonus = matrixUser[msg.sender].matrix_bonus;
                if(users[msg.sender].payouts + matrix_bonus > max_payout) {
                    matrix_bonus = max_payout - users[msg.sender].payouts;
                }
                matrixUser[msg.sender].matrix_bonus -= matrix_bonus;
                users[msg.sender].payouts += matrix_bonus;
                to_payout += matrix_bonus;
            } else{
                matrixUser[msg.sender].matrix_bonus = 0;
            }
        }
        
        // Team leader payout
        if(users[msg.sender].payouts < max_payout && matrixUser[msg.sender].leader_bonus > 0) {
            uint256 leader_bonus = matrixUser[msg.sender].leader_bonus;

            if(users[msg.sender].payouts + leader_bonus > max_payout) {
                leader_bonus = max_payout - users[msg.sender].payouts;
            }

            matrixUser[msg.sender].leader_bonus -= leader_bonus;
            users[msg.sender].payouts += leader_bonus;
            to_payout += leader_bonus;
        }
        
        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        uint256 matrixbonus = to_payout.mul(20).div(100);
        calcMatrixBonus(msg.sender,matrixbonus);
        to_payout -= to_payout.mul(20).div(100);
        if(coin == 0){
           payable(msg.sender).transfer(to_payout); 
        }
        else if(coin == 1){
            _token.send(msg.sender,to_payout,"Token Withdrawed");
        }
        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            users[msg.sender].isWithdrawActive = false;
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function emergencyWithdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }
            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;
            _refPayout(msg.sender, to_payout);
        }
        require(to_payout > 0, "Zero payout");
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        to_payout -= to_payout.mul(20).div(100);// Matrix bonus deduction, but won't be added to matrix
        payable(msg.sender).transfer(to_payout);
        emit EmergencyWithdraw(msg.sender, to_payout);
        if(users[msg.sender].payouts >= max_payout) {
            users[msg.sender].isWithdrawActive = false;
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
        
    }
    function drawPool() external onlyOwner {
        _drawPool();
    }
    function setDaily(uint8 perc) external onlyOwner {
        DAILY = perc;
    }
    function setMinDeposit(uint256 amount) external onlyOwner{
        minDeposit = amount;
    }
    function setEthDeposit(bool value) external onlyOwner{
        isEthDepoPaused = value;
    }
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 3;
    }
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        if(users[_addr].isWithdrawActive){
            
            if(users[_addr].deposit_payouts < max_payout) {
                payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days).mul(DAILY).div(1000)) - users[_addr].deposit_payouts;
            
                if(users[_addr].deposit_payouts + payout > max_payout) {
                    payout = max_payout - users[_addr].deposit_payouts;
                }
            }
        }else{
            payout = 0;
        }
    }

    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }
    
    function matrixBonusInfo(address addr) view external returns(address[3] memory direct_downline, uint256 matrix_bonus, uint256 current_level){
        return(matrixUser[addr].matrixRef,matrixUser[addr].matrix_bonus,matrixUser[addr].level);
    }
    
    function contractInfo() view external returns(uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_withdraw, last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[] memory addrs, uint256[] memory deps) {
        for(uint8 i = 0; i < 12; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
    
    function TeamLeaderInfo() view external returns(address[] memory addr){
        return teamLeaders;
    }
}