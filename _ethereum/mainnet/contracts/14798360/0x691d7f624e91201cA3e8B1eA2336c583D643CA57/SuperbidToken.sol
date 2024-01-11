// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "draft-ERC20Permit.sol";
import "IUniswapV2Router02.sol";


contract SuperbidToken is ERC20, ERC20Burnable, ERC20Permit, Ownable, ReentrancyGuard {
    // 5% max, by default 2%
    uint256 MAX_TAX = 500;
    // address / contract receiving the tax
    address public feeWallet;
    mapping (address => bool) public taxExcluded;
    // tax fee, 2 decimal points, so "253" is "2.53%"
    uint256 public taxFee;
    uint256 public swapTokensAtAmount;
    IUniswapV2Router02 public router;
    bool private _swapping;

    event TaxChanged(uint256 taxFee);
    event FeeWalletChanged(address wallet);

    address weth;
    address uniswapV2Pair;

    constructor(address _feeWallet, uint256 _swapTokensAtAmount) ERC20("SuperBid", "SUPERB") ERC20Permit("SuperBid") {
        setTaxFee(200);  // 2%
        setSwapTokensAtAmount(_swapTokensAtAmount);
        excludeFromTax(_msgSender());
        excludeFromTax(address(this));
        _mint(msg.sender, 17_000_000 * 10 ** decimals());
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

    // excluding from tax is needed because of some contracts
    // like contract for converting SB into XPad - these should
    // not be taxed.
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
        // send fees to the fee wallet, emergency procedure
        address me = address(this);
        uint256 tokenBalance = balanceOf(me);
        if (tokenBalance > 0) {
            super._transfer(me, feeWallet, tokenBalance);
        }
    }

    function airdrop(address[] calldata to, uint[] calldata amount) external nonReentrant {
        assert(to.length == amount.length);
        // only taxExcluded accounts are allowed to do this, otherwise
        // it would be tax bypass
        require(taxExcluded[msg.sender], "only-tax-excluded");

        // because it's simplified we only allow doing this from addresses which are tax exempt
        for (uint i = 0; i < to.length; i++) {
            super._transfer(msg.sender, to[i], amount[i]);
        }
    }
}