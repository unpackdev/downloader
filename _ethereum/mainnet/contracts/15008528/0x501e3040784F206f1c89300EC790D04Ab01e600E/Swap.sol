//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IUniswap.sol";
import "./IERC20.sol";
import "./Ownable.sol";


contract Swap is Ownable {
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Router02 public sushiRouter;

    IERC20 public weth;
    bool public paused;

    receive() external payable {}

    event Deposit(uint256);
    event Withdraw(uint256);

    constructor(address _uniswapRouter, address _sushiswapRouter) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        sushiRouter = IUniswapV2Router02(_sushiswapRouter);
        weth = IERC20(uniswapRouter.WETH());
        paused = false;
    }


    function deposit() public onlyOwner payable {
        emit Deposit(msg.value);
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success,) = msg.sender.call{ value: amount }(new bytes(0));
        if (success) {
            emit Withdraw(amount);
        }        
    }

    function balance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    function uniswapPath(address[] memory token_path, uint256 amount) public onlyOwner {
        require(paused == false, "Service is paused");
        require(token_path.length >= 2, "Invalid length");
        paused = true;

        address token1Address = token_path[0];
        address token2Address = token_path[1];

        IERC20 token1 = IERC20(token1Address);
        IERC20 token2 = IERC20(token2Address);


        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = token1Address;
        uniswapRouter.swapExactETHForTokens{value: amount} (
            0, 
            path, 
            address(this), 
            ~uint256(0)
        );

        address[] memory tokenPath = new address[](2);
        tokenPath[0] = token1Address;
        tokenPath[1] = token2Address;

        uint256 token1Balance = token1.balanceOf(address(this));
        token1.approve(address(uniswapRouter), token1Balance);
        uniswapRouter.swapExactTokensForTokens(
            token1Balance,
            0,
            tokenPath, 
            address(this), 
            ~uint256(0)
        );


        address[] memory reversePath = new address[](2);
        reversePath[0] = token2Address;
        reversePath[1] = address(weth);

        uint256 token2Balance = token2.balanceOf(address(this));
        token2.approve(address(uniswapRouter), token2Balance);
        uniswapRouter.swapExactTokensForETH(
            token2Balance, 
            0, 
            reversePath, 
            address(this), 
            ~uint256(0)
        );
        paused = false;
    }

    function uniswapETE(address _tokenAddress, uint256 amount) public onlyOwner returns(uint256) {
        require(paused == false, "Service is paused");

        paused = true;

        IERC20 token = IERC20(_tokenAddress);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = _tokenAddress;
        uniswapRouter.swapExactETHForTokens{value: amount} (
            0, 
            path, 
            address(this), 
            ~uint256(0)
        );

        uint256 balanceBefore = address(this).balance;

        address[] memory reversePath = new address[](2);
        reversePath[0] = _tokenAddress;
        reversePath[1] = address(weth);

        uint256 tokenBalance = token.balanceOf(address(this));
        
        token.approve(address(sushiRouter), tokenBalance);
        sushiRouter.swapExactTokensForETH(
            tokenBalance, 
            0, 
            reversePath, 
            address(this), 
            ~uint256(0)
        );

        uint256 difference = address(this).balance - balanceBefore;
        paused = false;

        return difference;
    }

    function setPaused(bool status) public onlyOwner returns(bool) {
        paused = status;
        return paused;
    }
}