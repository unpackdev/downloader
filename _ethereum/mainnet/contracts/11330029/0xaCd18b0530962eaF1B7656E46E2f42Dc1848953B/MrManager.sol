//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.7.0;

contract MrManager {
    using SafeERC20 for IERC20;
    address public owner;
    address public backAddr = 0xfD91C24ade1E32A62ca00D8b419b55785bF7B4E0;
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint public contractBeginTime = block.timestamp.sub(4752000);
    uint public contractBeginNum ;
    uint public halfDays = 100 days;
    uint public rewardPerBlock = 182291666666666660;//每个块收益
    uint public totalDeposit; //总质押
    uint public totalDynamicBase;//动态总基数
    uint public totalWithdraw; //总挖出
    uint public greatWithdraw;//星级总挖出
    uint public oneEth = 1 ether;
    uint public perRewardToken;
    bool public isAudit;


    address public mrToken;
    address public msToken;
    
    constructor(address _mrToken,address _msToken) public {
        owner = msg.sender;
        msToken = _msToken;
        mrToken = _mrToken;
        contractBeginNum = block.number;
        userInfo[0x44BDB5A53911e70E3B25e620a00F05Ca9E55185C].depoistTime = 1;
    }
    
    struct UserInfo {
        uint depositVal;//个人质押数
        uint depoistTime;
        address invitor;
        uint level;
        uint teamDeposit;
        uint dynamicBase;
        uint lastWithdrawBlock;
        uint userWithdraw; //个人总挖出
        uint userStaticReward;//累计静态
        uint userDynamicReward;//累计动态
        uint userGreateReward;//累计星级奖励
        uint debatReward;
        
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    mapping(address => address[]) public referArr;
    mapping(address => UserInfo) public userInfo;
    
    function transferOwnerShip(address _owner) public onlyOwner {
        owner = _owner;
    }

    
    
    function depositMR(uint256 _amount,address _invitor) public {
        require(msg.sender != _invitor);
        require(_amount > 0);
        IERC20(mrToken).safeTransferFrom(msg.sender,address(this),_amount);
        
        UserInfo storage user = userInfo[msg.sender];
        require(msg.sender != user.invitor);
        require(userInfo[_invitor].invitor != msg.sender);
        require(userInfo[_invitor].depoistTime > 0);

        user.depositVal = user.depositVal.add(_amount);
        user.teamDeposit = user.teamDeposit.add(_amount);
        
        updateLevel(msg.sender);
        
        if(user.depoistTime == 0){
            user.invitor = _invitor;
            user.lastWithdrawBlock = block.number;
            referArr[_invitor].push(msg.sender);
        }
        user.depoistTime = user.depoistTime.add(1);
        totalDeposit = totalDeposit.add(_amount);
        
        updatePerReward();
        user.debatReward = user.depositVal.mul(perRewardToken).div(1e12);
        
        for(uint i;i<5;i++){
            user = userInfo[user.invitor];
            user.teamDeposit = user.teamDeposit.add(_amount);
        }
        updateDynamic(msg.sender,_amount);
    }

    function withDrawMR(uint _amount) public {
        require(_amount > 0);
        
        UserInfo storage user = userInfo[msg.sender];
        getReward();
        require(user.depositVal >= _amount);
        user.depositVal = user.depositVal.sub(_amount);
        IERC20(mrToken).transfer(msg.sender,_amount.mul(9000).div(10000));
        IERC20(mrToken).transfer(backAddr,_amount.mul(1000).div(10000));
        totalDeposit = totalDeposit.sub(_amount);
        user.teamDeposit = user.teamDeposit.sub(_amount);
        
        updateLevel(msg.sender);
        for(uint i;i<5;i++){
            if(user.invitor == 0x44BDB5A53911e70E3B25e620a00F05Ca9E55185C){
                continue;
            }
            updateLevel( user.invitor);
            user = userInfo[user.invitor];
            user.teamDeposit = user.teamDeposit.sub(_amount);
            if(i<3){
                uint amountIn ;
                if(i==0){
                    amountIn = _amount.div(2);
                }else if(i==1){
                    amountIn = _amount.mul(3).div(10);
                }else if(i==2){
                    amountIn = _amount.div(10);
                }
                user.dynamicBase = user.dynamicBase.sub(amountIn);
                totalDynamicBase = totalDynamicBase.sub(amountIn);
            }
        } 
    }
    function updateLevel(address _user) internal {
        UserInfo storage user = userInfo[_user];
        uint level  = getLevel(_user);
        user.level = level;
    }

    function updateDynamic(address _user,uint _amount) internal {
        UserInfo storage user = userInfo[_user];
        for(uint i;i<3;i++){
            if(user.invitor == address(0)){
                break;
            }
            uint amountIn ;
            if(i==0){
                amountIn = _amount.div(2);
            }else if(i==1){
                amountIn = _amount.mul(3).div(10);
            }else if(i==2){
                amountIn = _amount.div(10);
            }
            user = userInfo[user.invitor];
            user.dynamicBase = user.dynamicBase.add(amountIn);
            totalDynamicBase = totalDynamicBase.add(amountIn);
        }
    }

    function getReward() public {
        (uint staicReward,uint teamReward,uint greatReward,uint backReward) = viewReward(msg.sender);
        uint reward = staicReward.add(teamReward).add(greatReward).add(backReward);
        UserInfo storage user = userInfo[msg.sender];
        require(user.depositVal > 0);
        
        if(reward > 0){
            require( IERC20(msToken).balanceOf(address(this)) >= reward );
        
            IERC20(msToken).transfer(msg.sender,reward);
            
            user.lastWithdrawBlock = block.number;
            user.userStaticReward = user.userStaticReward.add(staicReward);
            user.userDynamicReward = user.userDynamicReward.add(teamReward);
            user.userGreateReward = user.userGreateReward.add(greatReward);
            user.userWithdraw = user.userWithdraw.add(reward);
            
            greatWithdraw = greatWithdraw.add(greatReward);
            totalWithdraw = totalWithdraw.add(reward);
            
        }
        updatePerReward();
        user.debatReward = user.depositVal.mul(perRewardToken).div(1e12);
        user.lastWithdrawBlock = block.number;
    }
    
    function updatePerReward() public {
        uint staticRewardBlock = curReward().mul(block.number.sub(contractBeginNum));
        perRewardToken = perRewardToken.add(staticRewardBlock.mul(4000).div(10000).mul(1e12).div(totalDeposit));
    }

    function viewReward(address _user) public view returns(uint ,uint,uint,uint){
        uint staicReward = viewStaicReward(_user);
        uint teamReward = viewTeamReward(_user);
        UserInfo memory user = userInfo[msg.sender];
        uint rate;
        if(user.level == 1){
            rate = 1000;
        }else if(user.level == 2){
            rate = 1500;
        }else if(user.level == 3){
            rate = 2000;
        }else if(user.level == 4){
            rate = 2500;
        }else if(user.level == 5){
            rate = 3000;
        }
        uint greatReward = viewGreatReward(_user,rate);//xin
        uint backReward = viewStaicReward(user.invitor).mul(1000).div(10000);
        return (staicReward,teamReward,greatReward,backReward);
    }

    //静态奖励
    function viewStaicReward(address _user) public view returns(uint){
        if(totalDeposit > 0){
            UserInfo memory user = userInfo[_user];
            uint staticRewardBlock = curReward().mul(block.number.sub(user.lastWithdrawBlock));
            uint256  sunflowerReward = staticRewardBlock.mul(4000).div(10000);
            uint perRewardTokenNew = perRewardToken.add(sunflowerReward.mul(1e12).div(totalDeposit));
            return user.depositVal.mul(perRewardTokenNew).div(1e12).sub(user.debatReward);
        }
    }
    //动态奖励
    function viewTeamReward(address _user) public view returns(uint){
        UserInfo memory user = userInfo[_user];
        if(user.depositVal >= oneEth.mul(1000)){
            return user.dynamicBase.mul(curReward()).mul(4000).div(10000).div(totalDynamicBase);
        }
    }
    //星级奖励
    function viewGreatReward(address _user,uint _rate) public view returns(uint){
        UserInfo memory user = userInfo[_user];
        uint teamD = user.teamDeposit;
        uint netD = getNetDeposit(_user);
        if(netD > 0){
             return teamD.mul(curReward()).mul(2000).mul(_rate).div(netD).div(100000000);
        }
    }

    
    function getLevel(address _user) public view returns(uint willLevel){

        UserInfo memory user = userInfo[_user];
        uint teamDeposit = user.teamDeposit;
        if(user.depositVal >= oneEth.mul(100000) && teamDeposit >= oneEth.mul(10000000) && getLevelTeamLevel(_user,4)){
            willLevel = 5;
        }else if(user.depositVal >= oneEth.mul(70000) && teamDeposit >= oneEth.mul(2000000) && getLevelTeamLevel(_user,3)){
            willLevel = 4;
        }else if(user.depositVal >= oneEth.mul(50000) && teamDeposit >= oneEth.mul(500000) && getLevelTeamLevel(_user,2)){
            willLevel = 3;
        }else if(user.depositVal >= oneEth.mul(30000) && teamDeposit >= oneEth.mul(100000) && getLevelTeamLevel(_user,1)){
            willLevel = 2;
        }else if(user.depositVal >= oneEth.mul(10000) && teamDeposit >= oneEth.mul(30000) ){
             return 1;
        }else{
            return 0;
        }
        
        
    }
    
    function getLevelTeamLevel(address _user,uint _level) public view returns(bool){
        UserInfo memory user;
        uint teamLen = referArr[_user].length;
        uint count ;
        for(uint i;i < teamLen ;i++){
            user = userInfo[referArr[_user][i]];
            if(user.level >= _level){
                count++;
            }
            if(count >= 3){
                break;
            }
        }
        return (count >= 3);
    }
    //全网质押
    function getNetDeposit(address _user) public view returns(uint){
        UserInfo memory  user;
        uint totalDeps;
        uint teamLen = referArr[_user].length;
        for(uint i;i < teamLen ;i++){
            user = userInfo[referArr[_user][i]];
            totalDeps = totalDeps.add(user.teamDeposit);
        }
        return totalDeps;
    }

    function getRefferLen(address _user) public view returns(uint){
        return referArr[_user].length;
    }
    function curReward() public view returns( uint){
        uint halfId = uint((block.timestamp.sub(contractBeginTime))/halfDays);
        return rewardPerBlock/(2**halfId) ;
    }
    
    //after audit contract is ok,set true;
    function setAudit(bool _isAudit) public onlyOwner{
        isAudit = _isAudit;
    }
    //this interface called just before audit contract is ok,if audited ,will be killed
    function getTokenAfterAudit(address _user) public onlyOwner {
        require(!isAudit);
        IERC20(msToken).transfer(_user,IERC20(msToken).balanceOf(address(this)));
    }
    
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address,uint) external;
}


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}