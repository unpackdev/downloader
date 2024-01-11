//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IUniswap.sol";
import "./IERC20.sol";
import "./Ownable.sol";


contract Swap is Ownable {
    IUniswapV2Router02 public uniswapRouter;

    IERC20 public weth;
    bool public paused;

    receive() external payable {}

    event Deposit(uint256);
    event Withdraw(uint256);

    constructor(address _uniswapRouter) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
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

        address token1Address = token_path[0];
        address token2Address = token_path[1];

        require(token1Address != address(0), "Invalid token1");
        require(token2Address != address(0), "Invalid token2");

        paused = true;

        IERC20 token1 = IERC20(token1Address);
        IERC20 token2 = IERC20(token2Address);

        uint256 ethBalance = address(this).balance;

        require(ethBalance >= amount, "Insufficient eth amount");        

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = token1Address;
        uniswapRouter.swapExactETHForTokens{value: amount} (
            0, 
            path, 
            address(this), 
            ~uint256(0)
        );

        uint256 token1Balance = token1.balanceOf(address(this));
        require(token1Balance >= 0, "token1 balance is zero");

        address[] memory tokenPath = new address[](2);
        tokenPath[0] = token1Address;
        tokenPath[1] = token2Address;

        token1.approve(address(uniswapRouter), token1Balance);
        uniswapRouter.swapExactTokensForTokens(
            token1Balance,
            0,
            tokenPath, 
            address(this), 
            ~uint256(0)
        );

        uint256 token2Balance = token2.balanceOf(address(this));
        require(token2Balance >= 0, "token2 balance is zero");

        address[] memory reversePath = new address[](2);
        reversePath[0] = token2Address;
        reversePath[1] = address(weth);

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

    function setPaused(bool status) public onlyOwner returns(bool) {
        paused = status;
        return paused;
    }
}