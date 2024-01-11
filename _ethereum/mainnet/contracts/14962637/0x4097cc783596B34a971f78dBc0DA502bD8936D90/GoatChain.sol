// SPDX-License-Identifier: MIT
/*

 .d8888b.                    888     .d8888b.  888               d8b               d8b
d88P  Y88b                   888    d88P  Y88b 888               Y8P               Y8P
888    888                   888    888    888 888
888         .d88b.   8888b.  888888 888        88888b.   8888b.  888 88888b.       888 .d8888b
888  88888 d88""88b     "88b 888    888        888 "88b     "88b 888 888 "88b      888 88K
888    888 888  888 .d888888 888    888    888 888  888 .d888888 888 888  888      888 "Y8888b.
Y88b  d88P Y88..88P 888  888 Y88b.  Y88b  d88P 888  888 888  888 888 888  888      888      X88
 "Y8888P88  "Y88P"  "Y888888  "Y888  "Y8888P"  888  888 "Y888888 888 888  888      888  88888P'



888    888                    8888888888       888
888    888                    888              888
888    888                    888              888
888888 88888b.   .d88b.       8888888 888  888 888888 888  888 888d888 .d88b.
888    888 "88b d8P  Y8b      888     888  888 888    888  888 888P"  d8P  Y8b
888    888  888 88888888      888     888  888 888    888  888 888    88888888
Y88b.  888  888 Y8b.          888     Y88b 888 Y88b.  Y88b 888 888    Y8b.
 "Y888 888  888  "Y8888       888      "Y88888  "Y888  "Y88888 888     "Y8888

*/

pragma solidity ^0.8.11;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "draft-ERC20Permit.sol";
import "IUniswapV2Router02.sol";


contract GoatChainContract is ERC20, ERC20Burnable, ERC20Permit, Ownable, ReentrancyGuard {
    uint256 MAX_TAX = 600;
    address public feeWallet;
    mapping (address => bool) public taxExcluded;
    uint256 public taxFee;
    uint256 public swapTokensAtAmount;
    IUniswapV2Router02 public router;
    bool private _swapping;

    event TaxChanged(uint256 taxFee);
    event FeeWalletChanged(address wallet);

    address weth;
    address uniswapV2Pair;

    constructor(address _feeWallet, uint256 _swapTokensAtAmount) ERC20("GoatChain", "GOAT") ERC20Permit("GoatChain") {
        setTaxFee(0);
        setSwapTokensAtAmount(_swapTokensAtAmount);
        excludeFromTax(_msgSender());
        excludeFromTax(address(this));
        _mint(msg.sender, 100_000_000_000 * 10 ** decimals());
        setFeeWallet(_feeWallet);
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        weth = router.WETH();
        uniswapV2Pair = pairFor(address(this), weth);
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        address factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    function setFeeWallet(address _feeWallet) onlyOwner public {
        require(_feeWallet != address(0), "Tax recipient can't be null address");
        require(_feeWallet != address(this), "Tax recipient can't be contract itself");
        excludeFromTax(_feeWallet);
        feeWallet = _feeWallet;
        emit FeeWalletChanged(_feeWallet);
    }

    function setSwapTokensAtAmount(uint256 _amount) onlyOwner public {
        swapTokensAtAmount = _amount;
    }

    function setTaxFee(uint256 _taxFee) public onlyOwner {
        require(_taxFee <= MAX_TAX, "Requested tax is too high");
        taxFee = _taxFee;
        emit TaxChanged(_taxFee);
    }

    function excludeFromTax(address who) public onlyOwner {
        taxExcluded[who] = true;
    }

    function includeInTax(address who) external onlyOwner {
        taxExcluded[who] = false;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        bool collectTax = (!(taxExcluded[from] || taxExcluded[to])) && taxFee > 0 && !_swapping;

        if(!collectTax) {
            super._transfer(from, to, amount);
            return;
        }

        if (!_swapping && from != uniswapV2Pair) {
            _swapping = true;
            swapTax();
            _swapping = false;
        }

        uint256 taxAmount = (amount * taxFee) / (100 * 100);
        uint256 restAmount = amount - taxAmount;

        super._transfer(from, address(this), taxAmount);
        super._transfer(from, to, restAmount);
    }

    function swapTax() internal {
        uint256 balance = balanceOf(address(this));
        if (balance < swapTokensAtAmount) return;
        _swapTokensForEth(swapTokensAtAmount);
    }

    function _swapTokensForEth(uint256 amount) private {
        _approve(address(this), address(router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            feeWallet,
            block.timestamp
        );
    }

    function forceSend() external onlyOwner {
        // send fees to the fee wallet
        address me = address(this);
        uint256 tokenBalance = balanceOf(me);
        if (tokenBalance > 0) {
            super._transfer(me, feeWallet, tokenBalance);
        }
    }
}