pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface For{
    function deposit(address token, uint256 amount) external payable;
    function withdraw(address underlying, uint256 withdrawTokens) external;
    function withdrawUnderlying(address underlying, uint256 amount) external;
    function controller() view external returns(address);

}
interface IFToken {
    function balanceOf(address account) external view returns (uint256);

    function calcBalanceOfUnderlying(address owner)
        external
        view
        returns (uint256);
}

interface IBankController {

    function getFTokeAddress(address underlying)
        external
        view
        returns (address);
}
interface ForReward{
    function claimReward() external;
}
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface UniswapRouter {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}
contract fortube{
     using SafeERC20 for IERC20;
     using SafeMath for uint256;
    
    address constant public fortube = address(0xdE7B3b2Fe0E7b4925107615A5b199a4EB40D9ca9);//主合约.
    address  public fortube_reward = address(0xF8Df2E6E46AC00Cdf3616C4E35278b7704289d82); //领取奖励的合约
    
    address constant public eth_address = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    address public want = address(0x9AFb950948c2370975fb91a441F36FDC02737cD4); //hfil
     
    address public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address[] public swap2TokenRouting;
    
    address public owner;
    
    function () external payable {
    }
    
    constructor () public payable{
        owner = tx.origin;
        // For(fortube).deposit.value(msg.value)(eth_address,msg.value);
    }
    function setFortubeReward(address _reward) public{
        fortube_reward = _reward;
    }
    function setUnirouter( address _uni) public{
        unirouter = _uni;
    }
    
    function setWant(address _want) public{
        require(msg.sender == owner, "!owner");
        want = _want;
    }
    
    function depositETH() public payable{
        For(fortube).deposit.value(msg.value)(eth_address,msg.value);
    }
    function deposit() public{
        uint _want = IERC20(want).balanceOf(address(this));
            address _controller = For(fortube).controller();
            if (_want > 0) {
                IERC20(want).safeApprove(_controller, 0);
                IERC20(want).safeApprove(_controller, _want);
                For(fortube).deposit(want,_want);
            }
    }
    function deposit1() public{
        uint _want = IERC20(want).balanceOf(address(this));
            address _controller = For(fortube).controller();
            if (_want > 0) {
                // IERC20(want).safeApprove(_controller, 0);
                IERC20(want).safeApprove(_controller, _want);
                For(fortube).deposit(want,_want);
            }
    }
    
    function swapToken(address _tokenaddress) public{
        uint256 _token = IERC20(_tokenaddress).balanceOf(address(this));
        IERC20(_tokenaddress).safeApprove(unirouter, 0);
        IERC20(_tokenaddress).safeApprove(unirouter, uint(-1));
        UniswapRouter(unirouter).swapExactTokensForTokens(_token, 0, swap2TokenRouting, address(this), now.add(1800));
    }
    
    function setSwapRouting(address[] memory _path) public{
        swap2TokenRouting = _path;
    }

    
    function _withdrawAll() public {
        address _controller = For(fortube).controller();
        IFToken fToken = IFToken(IBankController(_controller).getFTokeAddress(want));
        uint b = fToken.balanceOf(address(this));
        For(fortube).withdraw(want,b);
    }
    
    function _withdrawSome(uint256 _amount) public returns (uint) {
        For(fortube).withdrawUnderlying(want,_amount);
        return _amount;
    }
    
    function harvest() public{
        ForReward(fortube_reward).claimReward();
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function balanceOfPool() public view returns (uint) {
        address _controller = For(fortube).controller();
        IFToken fToken = IFToken(IBankController(_controller).getFTokeAddress(want));
        return fToken.calcBalanceOfUnderlying(address(this));
    }
    
    
    function balanceOf() public view returns (uint) {
        return balanceOfWant().add(balanceOfPool());
    }
    
    function inCaseTokenGetsStuck(IERC20 _TokenAddress) public  {
        require(msg.sender == owner, "!owner");
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(msg.sender, qty);
    }

    // incase of half-way error
    function inCaseETHGetsStuck() public  {
        require(msg.sender == owner, "!owner");
        (bool result, ) = msg.sender.call.value(address(this).balance)("");
        require(result, "transfer of ETH failed");
    }
    
} 