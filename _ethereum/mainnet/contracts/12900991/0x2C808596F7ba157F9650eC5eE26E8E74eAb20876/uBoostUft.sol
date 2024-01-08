pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

import "./UnilendFlashLoanReceiverBase.sol";





interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}




contract BoostVolumeUnilend is UnilendFlashLoanReceiverBase {
    using SafeMath for uint256;
    
    uint public fee;
    address public feeAddress;
    address public owner;
    
    
    constructor() {
        owner = msg.sender;
        fee = 0;
        feeAddress = msg.sender;
    }
    
    
    
    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }
    
    
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        
        
        address token;
        address exchange;
        address baseToken;
        address payable sender;
        (exchange, token, baseToken, sender) = abi.decode(_params, (address, address, address, address));
        
        
        // address weth = IUniswapV2Router01(exchange).WETH();
        
        
        uint[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = baseToken;
        
        
        if(IERC20(token).allowance(address(this), exchange) < _amount){
            IERC20(token).approve(exchange, uint(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        }
        
        
        amounts = IUniswapV2Router01(exchange).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 10
        );
        
        if(IERC20(baseToken).allowance(address(this), exchange) < amounts[1]){
            IERC20(baseToken).approve(exchange, uint(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        }
        
        path[0] = baseToken;
        path[1] = token;
        
        amounts = IUniswapV2Router01(exchange).swapExactTokensForTokens(
            amounts[1],
            0,
            path,
            address(this),
            block.timestamp + 10
        );
        
        
        
        uint totalDebt = _amount.add(_fee);
        transferInternal(getUnilendCoreAddress(), _reserve, totalDebt);
    }
    
    function executeTrade(address _exchange, address token, address baseToken, uint _amount) external {
        bytes memory data = abi.encode(address(_exchange), address(token), address(baseToken), address(msg.sender));
        
        uint _totfee = (_amount.mul(65)).div(10000);
        uint feeAmount;
        if(fee > 0){
            feeAmount = (_amount.mul(fee)).div(10000);
        }
        
        IERC20(token).transferFrom(msg.sender, address(this), _totfee.add(feeAmount));
        
        if(feeAmount > 0){
            IERC20(token).transfer(feeAddress, feeAmount.mul(2));
        }
        
        flashLoan(address(this), token, _amount, data);
    }
    
    
    function updateFee(address payable newAddress, uint newFee) external onlyOwner {
        fee = newFee;
        feeAddress = newAddress;
    }
    
    
    function withdrawTokens(address token, address to, uint amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}