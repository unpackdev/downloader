/*

  Submitted for verification at Etherscan.io on 2023-12-10

  Twitter: @NiagaraFallsERC

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH {
    function withdraw(uint amount) external;
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);
}

contract Niagara is IERC20 {
    string public name = "Niagara";
    string public symbol = "FALLS";

    uint8 public decimals = 18;
    uint public totalSupply = 1_000_000_000 * 10 ** decimals;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public owner;

    address public pair;
    bool public tradingLive;

    uint256 public buyTax = 500; // 5%
    uint256 public maxBuyPercentage = 100; // 1%

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor () {
        owner = msg.sender;
        balanceOf[owner] += totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    // CORE ERC20 FUNCTIONS //

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        require(tradingLive);

        balanceOf[msg.sender] -= amount;

        if (msg.sender == pair) {

          uint amountNoFee = _enforceTax(msg.sender, amount);
          balanceOf[recipient] += amountNoFee;
          uint256 maxWalletSupply = totalSupply * maxBuyPercentage / 10000;
          require(maxWalletSupply >= balanceOf[recipient]);
          emit Transfer(msg.sender, recipient, amountNoFee);

        } else {

          balanceOf[recipient] += amount;
          emit Transfer(msg.sender, recipient, amount);

        }

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        if (sender == address(this)) return _uniswapTransferFrom(recipient, amount);

        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // AUXILIARY TO TAX ENFORCER //

    function sellTaxed() public {

        uint balance = balanceOf[address(this)];
        require(balance > 0);

        uint amountOut = _swap(balance);
        
        IWETH(WETH).withdraw(amountOut);

        uint reward = amountOut / 100;
        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Failed to send Ether");

        balanceOf[address(this)] = 0;

    }

    // PRIVATE FUNCTIONS //

    function _enforceTax(address sender, uint amount) private returns (uint) {
        uint256 _fee = amount * buyTax / 10000;
        balanceOf[address(this)] += _fee;
        emit Transfer(sender, address(this), _fee);

        return amount - _fee;
    }

    function _swap(
        uint amountIn
    ) private returns (uint amountOut) {

        IERC20(address(this)).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: WETH,
                fee: 10000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    function _uniswapTransferFrom(address recipient, uint amount) private returns (bool) {
        allowance[address(this)][msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(address(this), recipient, amount);
        return true;
    }

    // ADMINISTRATOR FUNCTIONS //

    function enableTrading(address _pair) public onlyOwner {
      tradingLive = true;
      pair = _pair;
    }

    function upgradeParameters(uint256 _buyTax, uint256 _maxBuyPercentage) public onlyOwner {
      buyTax = _buyTax;
      maxBuyPercentage = _maxBuyPercentage;
    }

    function changeOwner(address _owner) public onlyOwner {
      owner = _owner;
    }

    function saveEther() public onlyOwner {
      (bool sent, ) = msg.sender.call{value: address(this).balance}("");
      require(sent, "Failed to send Ether");
    }

    function saveToken(address token) public onlyOwner {
      uint256 amount = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(msg.sender, amount);
    }

    receive() external payable {}

}
