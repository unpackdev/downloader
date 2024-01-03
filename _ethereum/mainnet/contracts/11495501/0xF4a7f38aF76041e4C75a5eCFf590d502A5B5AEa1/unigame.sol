pragma solidity ^0.4.24;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IUniswapV2Pair {

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);


    function minttest(address from, address to, uint256 value) external;
}

interface IUniswapV2Router02 {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

contract unigame {

    using SafeMath for uint256;
    struct User {
        uint256 lpAmount;
        uint256 bonus;
        uint256 historyWithdraw;
        bool used;
    }

    uint256 totalLpAmount;

    uint256 totalTokenAmount;
    uint256 newTokenAmount;

    mapping(address => User) userMap;
    address[]userArr;

    address owner;

    //TODO 
    address tokenAddr = 0x5A947A3e5B62Cb571C056eC28293b32126E4d743;

    address pairAddr = address(0);
    address gameAddr = address(0);


    function safeTransfer(address token, address to, uint256 value) internal {
        bytes4 id = bytes4(keccak256("transfer(address,uint256)"));
        bool success = token.call(id, to, value);
        require(success, 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        bool success = token.call(id, from, to, value);
        require(success, 'TransferHelper: TRANSFER_FAILED');
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    //
    function transferTokenV(uint256 _v) public {
        require(msg.sender == gameAddr, "aaa");
        totalTokenAmount = totalTokenAmount.add(_v);
        newTokenAmount = newTokenAmount.add(_v);
    }


    function _distributeToken() internal {
        uint256 len = userArr.length;
        uint256 bonusBaseAmount = newTokenAmount.mul(70).div(100);
        for (uint256 i = 0; i < len; i++) {
            //(userLp/totalLp)*newToken
            User storage user = userMap[userArr[i]];
            uint256 bonus = bonusBaseAmount.mul(user.lpAmount).div(totalLpAmount);
            user.bonus = user.bonus.add(bonus);
        }

        if (len != 0) {
            newTokenAmount = newTokenAmount.mul(30).div(100);
        }
    }

    function _getUnassignedBonus(address _addr) internal view returns (uint256){
        User memory user = userMap[_addr];
        if (newTokenAmount == 0 || totalTokenAmount == 0 || user.lpAmount == 0) {
            return 0;
        }
        uint256 bonus = newTokenAmount.mul(70).mul(user.lpAmount).div(totalLpAmount).div(100);
        return bonus;
    }


    function investLp(uint256 _value) public {
        require(pairAddr != address(0), "n,s");
        require(_value > 0, "zero");

        _distributeToken();

        User storage user = userMap[msg.sender];
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        require(pair.balanceOf(msg.sender) >= _value, "not enough");

        safeTransferFrom(pairAddr, msg.sender, address(this), _value);

        user.lpAmount = user.lpAmount.add(_value);
        totalLpAmount = totalLpAmount.add(_value);
        if (!user.used) {
            userArr.push(msg.sender);
            user.used = true;
            userMap[msg.sender] = user;
        }
    }

    function withdrawBonus() public {
        require(userMap[msg.sender].used, "illegal");
        require(userMap[msg.sender].bonus > 0 || newTokenAmount > 0, "not enough");

        _distributeToken();

        User storage user = userMap[msg.sender];
        safeTransfer(tokenAddr, msg.sender, user.bonus);
        user.historyWithdraw = user.historyWithdraw.add(user.bonus);
        user.bonus = 0;
    }

    function setPairAddr(address _addr) public onlyOwner {
        pairAddr = _addr;
    }

    function setGameAddr_aa(address _addr) public onlyOwner {
        gameAddr = _addr;
    }


    function showInfo(address _addr) public view returns (bool, uint256, uint256, uint256, uint256, uint256){
        User memory user = userMap[_addr];
        uint256 unassigned = _getUnassignedBonus(_addr);
        return (user.used, user.lpAmount, user.bonus.add(unassigned), user.historyWithdraw, totalTokenAmount, totalLpAmount);
    }

    function showOthers() public view returns (uint256, uint256, uint256){
        return (userArr.length, newTokenAmount * 7 / 10, newTokenAmount * 3 / 10);
    }

    function showAddrs() public view returns (address, address){
        return (pairAddr, gameAddr);
    }

    function showBonus(address _addr) public view returns (uint256, uint256, uint256){
        User memory user = userMap[_addr];
        return (user.lpAmount, user.bonus, user.historyWithdraw);
    }

}