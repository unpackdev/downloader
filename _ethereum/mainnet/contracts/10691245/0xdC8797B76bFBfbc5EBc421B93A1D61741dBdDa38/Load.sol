
// File: contracts/online.sol

/**
 *Submitted for verification at Etherscan.io on 2020-07-30
*/

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
        _balances[msg.sender] = 200000 * 10 ** decimals;
        _balances[address(this)] = _totalSupply.sub(_balances[msg.sender]);
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }


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


    function renounceWhitelistCfo() public {
        _removeWhitelistCfo(msg.sender);
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


contract Load is Initializable, ERC20, WhitelistCfoRole {


    event RemoveUser(address indexed user);
    using SafeMath for uint;
    function initialize() initializer public {
        ERC20.initialize();
        Owned.initialize();
        WhitelistCfoRole.initialize();
        //初始那天24点的时间
        //  tomorrow_zero_time = ((now+40200)/86400 + 1)*86400+46200;
        addInit();
        //地址初始化
        load_price =1500000000000000;

    }




    uint public exchanged; //已兑换load数量
    uint public load_lock;//总的在仓load
    bool private iscalculated;//当天token收益是否计算完成，完成后才可以分红
    uint private beneficiary_amount;//当天load可分红的人数
    uint private beneficiary_finish;//当天load已分红的人数

    bool private iscalculatedeth;//当天eth收益是否计算完成，完成后才可以分红
    uint private beneficiary_eth_amount;//当天eth可分红的人数
    uint private beneficiary_eth_finish;//当天eth已分红的人数
    bool private isLoadDivFinish; //是否laod分红结束
    bool private isEthDivFinish;//是否eth分红结束

    mapping(string => address) manager; //分eth的地址,项目方指定地址
    struct lock {
        uint load_amount;
        uint unlock_date;
    }



    address[] users;//all users,实际应该是锁仓的用户,如果用户全部赎回后就把他从这个里面删除
    mapping(address => lock)  locks;


    mapping(address => uint) user_load_redeemable_list;  //可赎回load数量

    mapping(address => uint) user_load_bonus_list;  //laod分红

    mapping(address => uint) user_eth_bonus_list;  //eth分红
    uint public load_price;//xx eth/load
    uint public load_divs_per_load;
    uint public eth_divs_per_load;
    mapping(address=>uint) user_load_divs_total;
    mapping(address => uint)user_eth_divs_total;

    function addInit() private {
        manager["Founder"] = 0x264Db6A72f7144933FF700416CAD98816A6e0261;
        manager["Dev"] = 0x28125957Cb2d6AC5d7ca1b06C122Afdd7974A1c5;
        manager["Julie"] = 0xDCbd4AC767827A859e4c1a48269B650303B57f30;
        manager["Ant"] = 0x116a0Bd45575719711804276B6D92226017d37b9;
        manager["Prince"] = 0x4018D4838dA267896670AB777a802ea1c0229a16;
        manager["Tree"] = 0x8ef45fd3F2e4591866f1A17AafeACac61A7812c7;
        manager["CryptoGirl"] = 0x77B5D2DE66A18310B778a5c48D5Abe7d2A6D661D;
        manager["IP_PCS"] = 0xf40e89F1e52A6b5e71B0e18365d539F5E424306f;
        manager["Fee"] = 0x0655817bE81218dAd494a31F75B0964EA6A2946a;
        manager["UNI"] = 0x6166760a83bEF57958394ec2eEd00845b4Cf5a08;

    }

    function changeAddress(string nickname, address newaddress) external onlyOwner {
        manager[nickname] = newaddress;

    }



    //兑换
    function() external payable {

        require(exchanged < 1800000, "Convertion  over");
        require(themosteth() >= msg.value, "No many Tokens");
        uint coin;
        //兑换币的数量
        bool user_exist = false;
        uint load_bonus_total = 2000000 * 10 ** 8;
        uint load_bonus_everyday = load_bonus_total.div(180);

        locks[msg.sender].unlock_date = now + 3 days;

        coin = exchangeload(msg.value);
        exchanged = exchanged.add(coin);
        locks[msg.sender].load_amount = locks[msg.sender].load_amount.add(coin);


        load_lock = load_lock.add(coin);
        //总的load在仓

        locks[msg.sender].load_amount = locks[msg.sender].load_amount.add(coin);
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == msg.sender) {
                user_exist = true;
                break;
            }
        }
        if (!user_exist) {
            users.push(msg.sender);
        }
        uint level = exchanged.div(450000).add(1);
        load_divs_per_load = load_bonus_everyday.div(load_lock);
        eth_divs_per_load = address(this).balance.mul(level).div(100).div(load_lock);

    }
    // 查询可赎回的额度
    function checkredeemable() public view returns (uint amount) {
        if(now > locks[msg.sender].unlock_date){
            return locks[msg.sender].load_amount;
        }else {
            return 0;
        }
    }


    //计算利息eth和load
    function calculatedividend() external {
        uint256 level = exchanged.div(450000);
        uint load_bonus_total = 2000000 * 10 ** 8;
        uint load_bonus_everyday = load_bonus_total.div(180);
        uint load_bonus_each = load_bonus_everyday.div(load_lock);
        //每一个load获得的奖励
        uint eth_bonus_each = address(this).balance.mul(level.div(10)).div(load_lock);
        //每一个load获得的eth奖励

        //laod分红
        for (uint i = 0; i < users.length; i++) {
            user_load_bonus_list[users[i]] = locks[users[i]].load_amount.mul(load_bonus_each);


        }

        //eth分红
        for (uint j = 0; j < users.length; j++) {
            user_eth_bonus_list[users[j]] = locks[users[j]].load_amount.mul(eth_bonus_each);

        }
        iscalculated = true;
        iscalculatedeth = true;
        beneficiary_amount = users.length;
        beneficiary_eth_amount = users.length;
    }

    //分发load利息（在计算完成后)
    function distributeload(uint amount) external onlyWhitelistCfo {
        require(iscalculated, "先计算在分红");
        uint requestlength = amount;
        if (requestlength > beneficiary_amount.sub(beneficiary_finish)) {
            requestlength = beneficiary_amount.sub(beneficiary_finish);
        }
        for (beneficiary_finish; beneficiary_finish < beneficiary_amount; beneficiary_finish++) {
            if (requestlength <= 0) {
                break;
            }
            requestlength.sub(1);
            _transfer(address(this), users[beneficiary_finish], user_load_bonus_list[users[beneficiary_finish]]);
            user_load_divs_total[users[beneficiary_finish]] =user_load_divs_total[users[beneficiary_finish]].add(user_load_bonus_list[users[beneficiary_finish]]);

        }
        if (beneficiary_finish == beneficiary_amount) {
            iscalculated = false;
            beneficiary_finish = 0;
            isLoadDivFinish = true;
        }
    }

    //分发eth利息（在计算完成后)
    function distributeeth(uint amount) external onlyWhitelistCfo {
        require(iscalculated, "先计算在分红");
        uint requestlength = amount;
        if (requestlength > beneficiary_eth_amount.sub(beneficiary_eth_finish)) {
            requestlength = beneficiary_eth_amount.sub(beneficiary_eth_finish);
        }
        for (beneficiary_eth_finish; beneficiary_eth_finish < beneficiary_eth_amount; beneficiary_eth_finish++) {
            if (requestlength <= 0) {
                break;
            }
            requestlength --;
            address(uint160(users[beneficiary_eth_finish])).transfer(user_eth_bonus_list[users[beneficiary_eth_finish]]);
            user_eth_divs_total[users[beneficiary_eth_finish]] =  user_eth_divs_total[users[beneficiary_eth_finish]].add(user_eth_bonus_list[users[beneficiary_eth_finish]]);

        }
        if (beneficiary_eth_finish == beneficiary_eth_amount) {
            iscalculatedeth = false;
            beneficiary_eth_finish = 0;
            isEthDivFinish = true;
        }
    }

    //分红结束后，分eth
    function ethsharediv() external onlyWhitelistCfo {
        require(isEthDivFinish && isLoadDivFinish, "请先把用户的分红分了");
        uint256 ethshare = address(this).balance.mul(90).div(100).div(100);

        address(uint160(manager["Founder"])).transfer(ethshare.mul(33));
        address(uint160(manager["Dev"])).transfer(ethshare.mul(30));
        address(uint160(manager["Julie"])).transfer(ethshare.mul(20));
        address(uint160(manager["Ant"])).transfer(ethshare.mul(6));
        address(uint160(manager["Prince"])).transfer(ethshare.mul(6));
        address(uint160(manager["Tree"])).transfer(ethshare.mul(2));
        address(uint160(manager["CryptoGirl"])).transfer(ethshare.mul(1));
        address(uint160(manager["IP_PCS"])).transfer(ethshare.mul(1));
        address(uint160(manager["Fee"])).transfer(ethshare.mul(1));
        address(uint160(manager["UNI"])).transfer(address(this).balance.sub(ethshare.mul(90).div(100)));
        isLoadDivFinish = false;
        isEthDivFinish = false;

    }


    //赎回load
    function redeem(uint amount) external {
        require(locks[msg.sender].unlock_date < now,"locking");
        require(locks[msg.sender].load_amount >= amount, "Insufficient redemption quota");
        locks[msg.sender].load_amount = locks[msg.sender].load_amount.sub(amount);
        load_lock = load_lock.sub(amount);
        if(locks[msg.sender].load_amount == 0) {
            for(uint i=0;i<users.length;i++){
                if(users[i] == msg.sender){
                    delete users[i];
                    users[i] = users[users.length -1];
                    users.length --;
                    break;
                }
            }
        }

        _transfer(address(this), msg.sender, amount);
    }

    //当前最多兑换可消耗eth数量,todo public

    function themosteth() private view returns (uint mount){
        uint256 unit_eth = 1500000000000000;
        uint256 level = exchanged.div(450000);
        uint256 remain = level.mul(450000).sub(exchanged);
        //初始level剩余额度

        mount = remain.mul(unit_eth.mul(level));
        level++;
        for (uint i = level; i <= 4; i++) {
            mount = mount.add(i.mul(unit_eth).mul(450000));
        }
        return mount;
    }

    //可兑换load的数量,先改成prublic
    function exchangeload(uint amounteth) private  returns (uint mount){
        uint256 unit_eth = 1500000000000000;
        uint256 level = exchanged.div(450000);
        uint256 remain = level.mul(450000).sub(exchanged);
        //初始level剩余额度
        if (amounteth > remain.mul(unit_eth.mul(level))) {
            mount = remain;

            amounteth -= remain.mul(unit_eth.mul(level));
            level++;
            load_price=unit_eth.mul(level+1);
            for (uint i = level; i <= 4; i++) {
                if (amounteth > (unit_eth.mul(i)).mul(450000)) {
                    mount = mount.add(450000);
                    amounteth = amounteth.sub(unit_eth.mul(i).mul(450000));

                } else {
                    //退出
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

        if(index ==1){
            return load_price;
        }else if(index ==2){
            return locks[msg.sender].load_amount;
        }else if(index ==3){
            return  locks[msg.sender].unlock_date;
        }else if(index ==4){
            return load_divs_per_load;
        }else if(index ==5){
            return eth_divs_per_load;
        }else if(index ==6){
            return user_load_divs_total[msg.sender];
        }else if(index ==7){
            return user_eth_divs_total[msg.sender];
        }else if(index ==8){
            return beneficiary_amount;
        }else if (index ==9){
            return beneficiary_finish;
        }else if(index == 10){
            return beneficiary_eth_amount;
        }else if(index ==11){
            return beneficiary_eth_finish;
        }

    }


}
