//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Presale.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";


contract Shelter is PresaleToken, Ownable{

    uint public constant ONE_HUNDRED_PERCENT = 10000;
    uint public constant CHARITY_TAX = 500;
    uint public constant LIQUIDITY_FEE = 300;
    address public constant charity = 0xb5bc62c665c13590188477dfD83F33631C1Da0ba;

    IUniswapV2Router02 uniRouter;
    address uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;


    constructor(address[] memory _investors, uint[] memory _amounts)PresaleToken("Shelter Token", "SHELTOR", _investors, _amounts){
        uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);     //Uniswap for ETH
    }

        modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
   
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    /// @dev charity tax before any transfer
    function _beforeTokenTransfer(address from, address to, uint256 amount)internal override{
        if(from != address(0) && to != address(0) && from != address(uniRouter) && to != address(uniRouter) && from != uniswapV2Pair && to != uniswapV2Pair){
            _mint(charity, _applyPercent(amount, CHARITY_TAX));
            _mint(address(this), _applyPercent(amount, LIQUIDITY_FEE));
            _burn(from, _applyPercent(amount, CHARITY_TAX) + _applyPercent(amount, LIQUIDITY_FEE));
            if(swapAndLiquifyEnabled && !inSwapAndLiquify){
                swapAndLiquify(balanceOf(address(this)));  
            }
        }
    }

    /// @dev helper function to apply percents
    function _applyPercent(uint _num, uint _percent) private pure returns(uint256){
        return ((_num * _percent) / ONE_HUNDRED_PERCENT);
    }

    function sendBNBToTeam(uint256 amount) private {
        swapTokensForEth(amount);
        payable(charity).transfer(address(this).balance);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into thirds
        uint256 halfOfLiquify = contractTokenBalance / 4;
        uint256 otherHalfOfLiquify = contractTokenBalance / 4;
        uint256 portionForFees = (contractTokenBalance - halfOfLiquify) - (otherHalfOfLiquify);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(halfOfLiquify); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - (initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalfOfLiquify, newBalance);
        sendBNBToTeam(portionForFees);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();

        _approve(address(this), address(uniRouter), tokenAmount);

        // make the swap
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniRouter), tokenAmount);

        // add the liquidity
        uniRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
   
}