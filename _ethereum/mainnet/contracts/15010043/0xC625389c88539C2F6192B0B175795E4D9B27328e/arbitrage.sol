// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract ArbitrageBot {
    address public owner;
    address public daiAddress;
    address public wethAddress;
    address public uniswapRouterAddress;
    address public sushiswapRouterAddress;
    uint256 public arbitrageAmount;

    enum Exchange {
        UNI,
        SUSHI,
        NONE
    }

    constructor(
        address _uniswapRouterAddress,
        address _sushiswapRouterAddress,
        address _dai
    ) {
        uniswapRouterAddress = _uniswapRouterAddress;
        sushiswapRouterAddress = _sushiswapRouterAddress;
        owner = msg.sender;
        daiAddress = _dai;
        wethAddress = IUniswapV2Router02(uniswapRouterAddress).WETH();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    event swapPrice(uint256 uniswapPrice,uint256 bakeryswapPrice);
    function withdraw(uint256 amount) public onlyOwner {
        (bool sent, ) = payable(owner).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    function WithdrawBalance() public payable onlyOwner {
        // withdraw all ETH
        (bool sent, ) = msg.sender.call{ value: address(this).balance }("");
        require(sent, "Failed to send Ether");
    }

    function checkProfitable(uint256 amount) public view returns (bool){
        uint256 uniswapPrice = _getPrice(
            uniswapRouterAddress,
            wethAddress,
            daiAddress,
            amount
        );
        uint256 sushiswapPrice = _getPrice(
            sushiswapRouterAddress,
            wethAddress,
            daiAddress,
            amount
        );
        if(uniswapPrice * 1000 > sushiswapPrice * 1006 || sushiswapPrice * 1000 > uniswapPrice * 1006  )
            return true;
        else
            return false;
    }


    function makeArbitrage( uint256 _arbitrageAmount) public returns (bool)  {
        arbitrageAmount = _arbitrageAmount;
        uint256 uniswapPrice = _getPrice(
            uniswapRouterAddress,
            wethAddress,
            daiAddress,
            arbitrageAmount
        );
        uint256 sushiswapPrice = _getPrice(
            sushiswapRouterAddress,
            wethAddress,
            daiAddress,
            arbitrageAmount
        );

        emit swapPrice(uniswapPrice,sushiswapPrice);

        if(uniswapPrice > sushiswapPrice + 1000000000000000000){
             // uniswap test
            IUniswapV2Router02(uniswapRouterAddress).swapExactETHForTokens{ 
                value: arbitrageAmount 
            }(
                0, 
                getPathForETHToToken(daiAddress), 
                address(this),
                block.timestamp + 300
            );
            uint daiBalance = IERC20(daiAddress).balanceOf(address(this));
            IERC20(daiAddress).approve(sushiswapRouterAddress, daiBalance);
            IUniswapV2Router02(sushiswapRouterAddress).swapExactTokensForETH(
                daiBalance,
                0,
                getPathForTokenToETH(daiAddress),
                address(this),
                block.timestamp + 300
            );
        }else if (sushiswapPrice > uniswapPrice + 1000000000000000000){
            IUniswapV2Router02(sushiswapRouterAddress).swapExactETHForTokens{ 
                value: arbitrageAmount 
            }(
                0, 
                getPathForETHToToken(daiAddress), 
                address(this),
                block.timestamp + 300
            );
            uint daiBalance = IERC20(daiAddress).balanceOf(address(this));
            IERC20(daiAddress).approve(uniswapRouterAddress, daiBalance);
            IUniswapV2Router02(uniswapRouterAddress).swapExactTokensForETH(
                daiBalance,
                0,
                getPathForTokenToETH(daiAddress),
                address(this),
                block.timestamp + 300
            );
        }else{
            revert("Arbitrage not profitable");
        }
        return true;
    }
    
    function getPathForETHToToken(address ERC20Token) public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswapRouterAddress).WETH();
        path[1] = ERC20Token;
        return path;
    }
    
    function getPathForTokenToETH(address ERC20Token) public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = ERC20Token;
        path[1] = IUniswapV2Router02(sushiswapRouterAddress).WETH();
        return path;
    }

    function _getPrice(
        address routerAddress,
        address sell_token,
        address buy_token,
        uint256 amount
    ) internal view returns (uint256) {
        address[] memory pairs = new address[](2);
        pairs[0] = sell_token;
        pairs[1] = buy_token;
        uint256 price = IUniswapV2Router02(routerAddress).getAmountsOut(
            amount,
            pairs
        )[1];
        return price;
    }

    receive() external payable {
    }

    fallback() external payable {
    }
}
