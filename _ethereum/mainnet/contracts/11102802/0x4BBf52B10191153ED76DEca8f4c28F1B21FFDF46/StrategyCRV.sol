pragma solidity ^0.5.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function name() external view returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface Controller {
    function vaults(address) external view returns (address);
    function rewards() external view returns (address);
}

interface CurveDeposit{
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function claimable_tokens(address) external view returns (uint256);
}

interface CurveMinter{
    function mint(address) external;
}

interface ICurveFi {
  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    uint256[2] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[2] calldata amounts
  ) external;
  function remove_liquidity_one_coin(
    uint256 _amount,
    int128 i,
    uint256 min
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
}

interface UniswapRouter {
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

contract StrategyCRV  {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant want = address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D); // renbtc
    address public constant curveminter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0); // Token minter
    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address constant public curve = address(0x93054188d876f558f4a66B2EF1d97d16eDf0895B); // Curve.fi:REN Swap
    address public constant curvedeposit = address(0xB1F2cdeC61db658F091671F5f199635aEF202CAC); // Curve.fi: renCrv Gauge
    address public constant rencrv = address(0x49849C98ae39Fff122806C06791Fa73784FB3675); // Curve.fi: renCrv Token
    address constant public output = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // crv

    uint constant public DENOMINATION = 10 ** 10;

    uint public fee = 600;
    uint public callfee = 100;
    uint constant public max = 1000;

    uint public withdrawalFee = 0;
    uint constant public withdrawalMax = 10000;
    
    address public governance;
    address public controller;
    
    string public getName;

    address[] public swap2TokenRouting;
    
    constructor() public {
        governance = tx.origin;
        controller = 0x67D320cf7148D69058477B2b86991D2C1dE60E86;
        getName = string(
            abi.encodePacked("farmland:Strategy:", 
                abi.encodePacked(IERC20(want).name(),
                    abi.encodePacked(":",IERC20(output).name())
                )
            ));
        doApprove();
        swap2TokenRouting = [output,weth,want]; 
    }
    
    function deposit() public {
        // renbtc -> ren
        uint _renbtc = IERC20(want).balanceOf(address(this));
        if (_renbtc > 0) {
            IERC20(want).safeApprove(curve, 0);
            IERC20(want).safeApprove(curve, _renbtc);
            ICurveFi(curve).add_liquidity([_renbtc, 0], 0);
        }
        uint _rencrv = IERC20(rencrv).balanceOf(address(this));
        if (_rencrv > 0) {
            IERC20(rencrv).safeApprove(curvedeposit, 0);
            IERC20(rencrv).safeApprove(curvedeposit, _rencrv);
            CurveDeposit(curvedeposit).deposit(_rencrv);
        }
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(rencrv != address(_asset), "rencrv");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            uint _diff = _amount.sub(_balance);
            // calculate amount of rencrv lp to withdraw for amount of _want_
            uint _rencrv = _diff.mul(1e18).div(ICurveFi(curve).get_virtual_price());
            _amount = _withdrawSome(_rencrv.mul(DENOMINATION));
            _amount = _amount.add(_balance);
        }
        uint _fee = 0;
        if (withdrawalFee > 0) {
            _fee = _amount.mul(withdrawalFee).div(withdrawalMax);        
            IERC20(want).safeTransfer(Controller(controller).rewards(), _fee);
        }
        
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) { 
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        balance = IERC20(want).balanceOf(address(this));
        
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);    
    }
    
    function _withdrawAll() internal { 
        uint256 b = CurveDeposit(curvedeposit).balanceOf(address(this));
        if (b > 0) {
            _withdrawSome(b);
        }
    }

    function _withdrawSome(uint256 _rencrv) internal returns(uint256) {
        uint _before = IERC20(rencrv).balanceOf(address(this));
        CurveDeposit(curvedeposit).withdraw(_rencrv); // get rencrv
        uint _after = IERC20(rencrv).balanceOf(address(this));

        return withdrawUnderlying(_after.sub(_before));
    }
    
    function withdrawUnderlying(uint256 _amount) internal returns (uint) {
        IERC20(rencrv).safeApprove(curve, 0);
        IERC20(rencrv).safeApprove(curve, _amount);

        uint _before = IERC20(want).balanceOf(address(this));
        ICurveFi(curve).remove_liquidity_one_coin(_amount, 0, 0);
        uint _after = IERC20(want).balanceOf(address(this));
        
        return _after.sub(_before);
    }

    function doApprove () public {
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, uint(-1));
    }
    
    function harvest() public {
        require(!Address.isContract(msg.sender),"!contract");
        CurveMinter(curveminter).mint(curvedeposit);//get crv
        
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

        doswap();

        deposit(); //循环生息
        
        // fee of want
        uint b = IERC20(want).balanceOf(address(this));
        uint _fee = b.mul(fee).div(max);
        uint _callfee = b.mul(callfee).div(max);
        IERC20(want).safeTransfer(Controller(controller).rewards(), _fee); //6% team
        IERC20(want).safeTransfer(msg.sender, _callfee); //call fee 1%

    }
    function doswap() internal {
            uint256 _2token = IERC20(output).balanceOf(address(this)); //100%
            UniswapRouter(unirouter).swapExactTokensForTokens(_2token, 0, swap2TokenRouting, address(this), now.add(1800));

            // want -> ren
            uint _renbtc = IERC20(want).balanceOf(address(this)).mul(90).div(100);
            if (_renbtc > 0) {
                IERC20(want).safeApprove(curve, 0);
                IERC20(want).safeApprove(curve, _renbtc);
                ICurveFi(curve).add_liquidity([_renbtc, 0], 0);
            }    
    }

    function balanceOf() public view returns (uint) {
        uint _rencrv = CurveDeposit(curvedeposit).balanceOf(address(this)); // amount of rencrv
        uint _amount = _rencrv.mul(ICurveFi(curve).get_virtual_price()).div(1e18);
        return _amount.div(DENOMINATION);
    }

    function balanceOfPendingReward() public view returns(uint){ //还没有领取的收益有多少...
        return CurveDeposit(curvedeposit).claimable_tokens(address(this));   
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setFee(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        fee = _fee;
    }
    function setCallFee(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        callfee = _fee;
    }
    function setWithdrawalFee(uint _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        require(_withdrawalFee <=100,"fee >= 1%"); //max:1%
        withdrawalFee = _withdrawalFee;
    }
}