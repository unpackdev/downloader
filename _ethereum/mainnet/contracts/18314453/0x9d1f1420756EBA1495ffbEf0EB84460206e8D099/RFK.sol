// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

interface IUniFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 inAmount,
        uint256 outAmountMin,
        address[] calldata route,
        address dest,
        uint256 endTimestamp
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniPair {
    function sync() external;
}

contract RFK is ERC20, Ownable {
    uint256 public constant DENOMINATOR = 1000;
    IUniRouter public constant router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable lpAddress;
    
    uint256 public purchaseTax = 50;
    uint256 public salesTax = 50;

    address public marketingAddr;
    uint256 public maxTxSize = type(uint256).max;
    uint256 public maxSwapImpact = 20;

    bool private swapping;

    mapping(address => bool) public feeExceptions;

    constructor() ERC20("RFK", "RFK") {
        _mint(msg.sender, 10_000_000_000 * (10 ** decimals()));
        
        lpAddress = IUniFactory(router.factory()).createPair(address(this), router.WETH());
        _approve(address(this), address(router), type(uint256).max);

        setMarketingWallet(0x72c00E653EC156e9eD07d8307E4e63125c5b7e3f);

        feeExceptions[msg.sender] = true;
        feeExceptions[address(this)] = true;
        feeExceptions[address(router)] = true;
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingAddr = _marketingWallet;
        feeExceptions[marketingAddr] = true;
    }

    function updateFees(uint256 newPurchaseTax, uint256 newSalesTax) public onlyOwner {
        require(newPurchaseTax < DENOMINATOR && newSalesTax < DENOMINATOR, "Invalid fees");
        purchaseTax = newPurchaseTax;
        salesTax = newSalesTax;
    }

    function defineMaxTxSize(uint256 _maxSize) public onlyOwner {
        maxTxSize = _maxSize;
    }

    function setSwapImpact(uint256 _maxImpact) external onlyOwner {
        maxSwapImpact = _maxImpact;
    }

    function exemptFromFees(address target) public onlyOwner {
        feeExceptions[target] = true;
    }

    function revokeFeeException(address target) external onlyOwner {
        feeExceptions[target] = false;
    }

    function _transfer(address from, address to, uint256 quantity) internal override {
        if (swapping) {
            return super._transfer(from, to, quantity);
        }

        bool isBuy = from == lpAddress && !feeExceptions[to];
        bool isSell = to == lpAddress && !feeExceptions[from];

        if (isBuy || isSell) {
            require(quantity <= maxTxSize, "Exceeds maximum trade size");

            quantity = subtractFees(from, quantity, isBuy);
        }

        super._transfer(from, to, quantity);
    }

    function subtractFees(address trader, uint256 qty, bool isBuy) private returns (uint256) {
        uint256 tradeTax = (isBuy ? purchaseTax : salesTax) * qty / DENOMINATOR;
        super._transfer(trader, address(this), tradeTax);
        if (!isBuy) executeSwap();

        return qty - tradeTax;
    }

    function executeSwap() private {
        uint256 balance = balanceOf(address(this));
        uint256 lpBalance = balanceOf(lpAddress);
        uint256 swapSize = lpBalance * maxSwapImpact / (2 * DENOMINATOR);
        if (balance > swapSize) balance = swapSize;
        if (balance == 0) return;

        swapping = true;

        address[] memory route = new address[](2);
        route[0] = address(this);
        route[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(balance, 0, route, marketingAddr, block.timestamp);

        swapping = false;
    }
}
