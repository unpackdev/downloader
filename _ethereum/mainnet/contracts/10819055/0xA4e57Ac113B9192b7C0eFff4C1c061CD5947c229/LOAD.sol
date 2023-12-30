
// File: contracts/loadv2.sol

pragma solidity >=0.4.23 <0.6.0;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {cs := extcodesize(self)}
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


contract ERC20 is Initializable, IERC20 {
    using SafeMath for uint256;


    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public  name;
    string public  symbol;
    uint256 public decimals;

    function initialize() initializer public {
        name = "LOAD";
        symbol = "LOAD";
        decimals = 8;
        _totalSupply = 10000000 * 10 ** decimals;
        _balances[0x264Db6A72f7144933FF700416CAD98816A6e0261] = 200000 * 10 ** decimals;
        _balances[address(this)] = _totalSupply.sub(_balances[msg.sender]);
        emit Transfer(address(0), 0x264Db6A72f7144933FF700416CAD98816A6e0261, _balances[0x264Db6A72f7144933FF700416CAD98816A6e0261]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }

    function receiveLoad(uint amount) internal ;
    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }



    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        if(recipient == address(this)){
            receiveLoad(amount);
        }

        emit Transfer(sender, recipient, amount);
    }




    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


}

contract Owned is Initializable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);


    function initialize() initializer public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

}


library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract WhitelistCfoRole is Initializable, Owned {
    using Roles for Roles.Role;

    event WhitelistCfoAdded(address indexed account);
    event WhitelistCfoRemoved(address indexed account);

    Roles.Role private _whitelistCfos;


    function initialize() initializer public {
        _addWhitelistCfo(0x264Db6A72f7144933FF700416CAD98816A6e0261);
        _addWhitelistCfo(0x28125957Cb2d6AC5d7ca1b06C122Afdd7974A1c5);
        _addWhitelistCfo(0xDCbd4AC767827A859e4c1a48269B650303B57f30);
        _addWhitelistCfo(0x116a0Bd45575719711804276B6D92226017d37b9);
        _addWhitelistCfo(0x77D1577D9b312D6ff831E95F1D72D92359E5d89c);
    }

    modifier onlyWhitelistCfo() {
        require(isWhitelistCfo(msg.sender), "WhitelistCfoRole: caller does not have the WhitelistCfo role");
        _;
    }

    function isWhitelistCfo(address account) public view returns (bool) {
        return _whitelistCfos.has(account);
    }

    function addWhitelistCfo(address account) public onlyOwner {
        _addWhitelistCfo(account);
    }

    function removeWhitelistCfo(address account) public onlyOwner {
        _removeWhitelistCfo(account);
    }



    function _addWhitelistCfo(address account) internal {
        _whitelistCfos.add(account);
        emit WhitelistCfoAdded(account);
    }

    function _removeWhitelistCfo(address account) internal {
        _whitelistCfos.remove(account);
        emit WhitelistCfoRemoved(account);
    }
}


contract LOAD is Initializable, ERC20, WhitelistCfoRole {

    using SafeMath for uint;


    struct Lock {
        uint load_amount;
        uint unlock_date;
    }
    uint firstDay;

    uint  ethManager;
    ///
    struct LoadChange{
        bool ischange;
        uint amount;
    }
    //    uint users;//all users
    mapping(address=>bool) isLocking;

    uint private floor_amount;
    uint private exchanged;
    uint private load_lock;

    uint private load_price;
    uint private eth_unit;

    uint lockdays;
    uint divdDuration;


    mapping(string => address) manager;


    mapping(address => Lock)  locks;


    mapping(address => uint) user_load_divs_total;
    mapping(address => uint) user_eth_divs_total;


    mapping(uint=>LoadChange) public loadDaily;
    mapping(uint=>uint) public ethDaily;
    mapping(address=>uint) public userDivdDate;
    mapping(address=>mapping(uint=>LoadChange)) loadChanges;


    function initialize() initializer public {
        ERC20.initialize();
        Owned.initialize();
        // WhitelistCfoRole.initialize();
        // addInit();

        load_price = 1500000000000000;
        eth_unit = 1500000000000000;

        floor_amount =45000000000000;// 45000000000000;
        firstDay = now;
        lockdays = 3 days;
        divdDuration = 1 days;

    }


    function addInit() private {
        manager["Founder"] = 0x264Db6A72f7144933FF700416CAD98816A6e0261;
        manager["Dev"] = 0x28125957Cb2d6AC5d7ca1b06C122Afdd7974A1c5;
        manager["Julie"] = 0xDCbd4AC767827A859e4c1a48269B650303B57f30;
        manager["Ant"] = 0x116a0Bd45575719711804276B6D92226017d37b9;
        manager["Prince"] = 0x4018D4838dA267896670AB777a802ea1c0229a16;
        manager["Tree"] = 0x8ef45fd3F2e4591866f1A17AafeACac61A7812c7;
        manager["CryptoGirl"] = 0x77B5D2DE66A18310B778a5c48D5Abe7d2A6D661D;
        manager["IP_PCS"] = 0xf40e89F1e52A6b5e71B0e18365d539F5E424306f;
        manager["Fee"] = 0x77D1577D9b312D6ff831E95F1D72D92359E5d89c;
        manager["UNI"] = 0x6166760a83bEF57958394ec2eEd00845b4Cf5a08;
        manager["A"] =0x4E1FE0409C2845C1Bde8fcbE21ac6889311c8aB5;

    }

    function changeAddress(string nickname, address newaddress) external onlyOwner {
        manager[nickname] = newaddress;

    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

    function receiveEth() public payable{
        require(!isContract(msg.sender), "Should not be contract address");
        require(msg.value > 0, "Can't Zero");
        require(exchanged < 180000000000000, "The exchange is over");
        require(mosteth() >= msg.value, "Not so much");
        uint coin;

        coin = exchangeload(msg.value);
        exchanged = exchanged.add(coin);
        uint level = exchanged.div(floor_amount).add(1);
        load_lock = load_lock.add(coin);

        locks[msg.sender].unlock_date = now + lockdays;
        locks[msg.sender].load_amount = locks[msg.sender].load_amount.add(coin);

        uint today=now.div(divdDuration).add(1);
        uint ethvalue = msg.value.mul(level).div(10);
        loadDaily[today].amount = load_lock;
        loadDaily[today].ischange = true;
        ethDaily[today] = ethDaily[today].add(ethvalue);
        ethManager = ethManager.add(msg.value.sub(ethvalue));
        loadChanges[msg.sender][today].ischange = true;
        loadChanges[msg.sender][today].amount = locks[msg.sender].load_amount;

        if(userDivdDate[msg.sender]==0){
            userDivdDate[msg.sender]=now.div(divdDuration);
        }
    }

    function() external payable {
        receiveEth();
    }



    function checkredeemable() public view returns (uint amount) {
        if (now > locks[msg.sender].unlock_date) {
            return locks[msg.sender].load_amount;
        } else {
            return 0;
        }
    }



    function ethsharediv() external onlyWhitelistCfo {

        uint ethpercentten = ethManager.div(10);
        //10 percent
        uint256 ethshare = (ethManager.sub(ethpercentten)).div(100);

        address(uint160(manager["UNI"])).transfer(ethpercentten);

        address(uint160(manager["Founder"])).transfer(ethshare.mul(31));
        address(uint160(manager["Dev"])).transfer(ethshare.mul(30));
        address(uint160(manager["Julie"])).transfer(ethshare.mul(20));
        address(uint160(manager["Ant"])).transfer(ethshare.mul(6));
        address(uint160(manager["Prince"])).transfer(ethshare.mul(6));
        address(uint160(manager["Tree"])).transfer(ethshare.mul(2));
        address(uint160(manager["CryptoGirl"])).transfer(ethshare.mul(1));
        address(uint160(manager["IP_PCS"])).transfer(ethshare.mul(1));
        address(uint160(manager["Fee"])).transfer(ethshare.mul(1));
        address(uint160(manager["A"])).transfer(ethshare.mul(2));
        ethManager =0;

    }

    function receiveLoad(uint amount) internal   {
        lockload(amount);
    }

    function lockload(uint amount) internal {
        uint today=now.div(divdDuration).add(1);
        locks[msg.sender].load_amount = locks[msg.sender].load_amount.add(amount);
        locks[msg.sender].unlock_date = now + lockdays;
        load_lock = load_lock.add(amount);


        loadDaily[today].amount = load_lock;
        loadDaily[today].ischange = true;
        loadChanges[msg.sender][today].ischange = true;
        loadChanges[msg.sender][today].amount = locks[msg.sender].load_amount;


        if(userDivdDate[msg.sender]==0){
            userDivdDate[msg.sender]= now.div(divdDuration);
        }

    }


    function redeem() external {
        require(locks[msg.sender].unlock_date < now, "locking");
        uint today=now.div(divdDuration).add(1);
        uint total = locks[msg.sender].load_amount;
        load_lock = load_lock.sub(total);
        locks[msg.sender].load_amount = 0;
        loadDaily[today].amount = load_lock;
        loadDaily[today].ischange = true;
        loadChanges[msg.sender][today].ischange = true;
        loadChanges[msg.sender][today].amount = 0;
        isLocking[msg.sender]=false;
        _transfer(address(this), msg.sender, total);
    }


    function mosteth() internal view returns (uint mount){
        uint256 unit_eth = 15000000;
        uint256 level = exchanged.div(floor_amount).add(1);
        uint256 remain = level.mul(floor_amount).sub(exchanged);
        mount = remain.mul(unit_eth.mul(level));
        level++;
        for (uint i = level; i <= 4; i++) {
            mount = mount.add(i.mul(unit_eth).mul(floor_amount));
        }
        return mount;
    }


    function exchangeload(uint amounteth) internal returns (uint mount){
        uint256 unit_eth = 15000000;
        uint256 level = exchanged.div(floor_amount).add(1);
        uint256 remain = level.mul(floor_amount).sub(exchanged);
        if (amounteth > remain.mul(unit_eth.mul(level))) {
            mount = remain;
            amounteth = amounteth.sub(remain.mul(unit_eth.mul(level)));
            level++;
            load_price = eth_unit.mul(level);
            for (uint i = level; i <= 4; i++) {
                if (amounteth > (unit_eth.mul(i)).mul(floor_amount)) {
                    mount = mount.add(floor_amount);
                    amounteth = amounteth.sub(unit_eth.mul(i).mul(floor_amount));
                } else {
                    mount = mount.add(amounteth.div(unit_eth.mul(i)));
                    break;
                }
            }
        } else {
            mount = amounteth.div(unit_eth.mul(level));
        }
        return mount;

    }

    function get(uint index) public view returns (uint) {

        if (index == 1) {
            return load_price;
        } else if (index == 2) {
            return locks[msg.sender].load_amount;
        } else if (index == 3) {
            return locks[msg.sender].unlock_date;
        }  else if (index == 6) {
            return user_load_divs_total[msg.sender];
        } else if (index == 7) {
            return user_eth_divs_total[msg.sender];
        }  else if (index == 26) {
            return exchanged;
        }  else if (index == 29) {
            return load_price.add(eth_unit);
        }
    }


    function getDivdLoad()public view  returns (uint) {
        uint bonus;
        uint divAmount;
        uint userLockTemp;
        uint allLockTemp;
        if(userDivdDate[msg.sender]==0){
            return 0;
        }
        for(uint j=userDivdDate[msg.sender]+1;j<=now.div(divdDuration);j++){
            if(loadDaily[j].ischange){
                if(loadChanges[msg.sender][j].ischange ){
                    userLockTemp = loadChanges[msg.sender][j].amount;
                    if(userLockTemp ==0){
                        continue;
                    }
                }
                allLockTemp = loadDaily[j].amount;
            }
            bonus = getBonus(j);
            divAmount = divAmount.add(bonus.mul(userLockTemp).div(allLockTemp));
        }
        return divAmount;

    }


    function getBonus(uint day)private view returns (uint){
        uint bonus;
        uint begin = 200000000000000;
        uint sang = day.sub(firstDay.div(divdDuration)).div(180);
        if(sang>5){
            sang =5;
        }
        bonus =begin.div(2**sang).div(180);
        return bonus;
    }


    function getDivdEth() public view returns (uint){
        uint divAmount;
        if(userDivdDate[msg.sender]==0){
            return 0;
        }
        uint userLockTemp;
        uint allLockTemp;
        for(uint j=userDivdDate[msg.sender]+1;j<=now.div(divdDuration);j++){
            if(loadDaily[j].ischange){
                if(loadChanges[msg.sender][j].ischange){
                    userLockTemp = loadChanges[msg.sender][j].amount;
                    if(userLockTemp ==0 ){
                        continue;
                    }
                }
                allLockTemp = loadDaily[j].amount;
            }

            if(ethDaily[j]==0){
                continue;
            }
            divAmount = divAmount.add(ethDaily[j].mul(userLockTemp).div(allLockTemp));
        }
        return divAmount;
    }


    function withdraw() external {
        uint load = getDivdLoad();
        uint eth = getDivdEth();
        require(load>0 || eth >0,"no award ");
        uint today=now.div(divdDuration).add(1);
        loadDaily[today].amount = load_lock;
        loadDaily[today].ischange = true;
        loadChanges[msg.sender][today].ischange = true;
        loadChanges[msg.sender][today].amount = locks[msg.sender].load_amount;
        userDivdDate[msg.sender] = now.div(divdDuration);
        user_load_divs_total[msg.sender] =user_load_divs_total[msg.sender].add(load);
        user_eth_divs_total[msg.sender] =  user_eth_divs_total[msg.sender].add(eth);
        _transfer(address(this), msg.sender, load);
        address(uint160(msg.sender)).transfer(eth);
    }
}
