// SPDX-License-Identifier: MIT

/*

https://twitter.com/RZBBC_Token
https://rzbbc.com

*/

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract Bart is ERC20, Ownable {

    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    IUniswapV2Router02 public immutable router;
    IUniswapV2Pair public immutable pair;        
    address public immutable pairAddress;
    
    address public immutable admin;
    
    bool private swapping;
    bool public tradingActive;

    mapping(address => bool) public isExcludedFromMaxTransaction;

    uint256 public fees;
    uint256 maxTxAmount = 10_000_000 ether; // 1% of supply
    uint256 public swapTreshold = 0.05 ether;

    constructor(uint256 _supply, uint256 _fees) ERC20("ReptilianZuckerBidenBartCoin", "BART") {
        admin = msg.sender;
        router = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

        pairAddress = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        fees = _fees;

        _approve(address(this), UNISWAP_ROUTER_ADDRESS, type(uint256).max);
        _approve(address(this), pairAddress, type(uint256).max);

        excludeFromMaxTransaction(UNISWAP_ROUTER_ADDRESS, true);
        excludeFromMaxTransaction(pairAddress, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, _supply);
    }

    modifier isTradingActive(address _from) {
        if (_from != owner())
            require(tradingActive, "Trading not active");
        _;
    }

   modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier lockSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    receive() external payable {}

    function excludeFromMaxTransaction(address _account, bool _excluded) public onlyOwner {
        isExcludedFromMaxTransaction[_account] = _excluded;
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function _transfer(address _from, address _to, uint256 _amount) internal override isTradingActive(_from) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");

        if(_from == owner() || _to == owner() || swapping) {
            super._transfer(_from, _to, _amount);
        } else {
           
            if (!swapping) distributeFees();

            uint256 feeAmount;

            if (_from == pairAddress) {
                if (!isExcludedFromMaxTransaction[_to]) {
                    require(_amount <= maxTxAmount);
                }
                feeAmount = _amount * fees / 10000; 
            } else if (_to == pairAddress) {
                feeAmount = _amount * fees / 10000; 
            } else {
                feeAmount = 0;
            }

            if (feeAmount > 0) {
                super._transfer(_from, address(this), feeAmount);
            }

            uint256 finalAmount = _amount - feeAmount;

            super._transfer(_from, _to, finalAmount);
        }
    }

    function calculateTokenAmountInETH(uint256 amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        try router.getAmountsOut(amount, path) returns (uint[] memory amountsOut) {
            return amountsOut[1];
        } catch {return 0;}
    }

    function manualSwap() external onlyAdmin {
        swapBalanceToETHAndSend();
    }

    function distributeFees() private {
        uint256 amountInETH = calculateTokenAmountInETH(balanceOf(address(this)));
        if (amountInETH >= swapTreshold) swapBalanceToETHAndSend();
    }

    function swapBalanceToETHAndSend() private lockSwap {
        uint256 amountIn = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

        (bool success, ) = payable(admin).call{value: address(this).balance}("");
        require(success);
    }
}