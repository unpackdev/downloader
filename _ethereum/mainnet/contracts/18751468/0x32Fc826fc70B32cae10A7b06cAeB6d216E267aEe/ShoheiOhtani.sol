// Twitter: https://twitter.com/SOinu69
// Telegram: https://t.me/shoheiohtaninu

// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "./Owned.sol";
import "./ERC20.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ShoheiOhtani is ERC20, Owned {
    mapping (address => bool) isFeeExempt;

    // Fee decrementation schedule
    uint256 private constant startingFee = 250;
    uint256 private constant intermediateSellFee = 150;
    uint256 private constant finalFee = 0;
    uint256 private constant feeDenominator = 1000;

    uint256 public fee = startingFee;

    // Fees are changed at these block numbers
    uint256 public immutable startingBlock;
    uint256 public immutable taxLowerBlockIntermediate;
    uint256 public immutable taxLowerBlockFinal;

    uint256 private constant whalePercent = 2;
    uint256 private constant whaleDenominator = 100;

    uint256 private constant swapPercent = 2;
    uint256 private constant swapDenominator = 100;

    uint256 public immutable swapThreshold;

    address private marketing;

    address public immutable pair;
    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event FeeChanged(uint256 fee, uint256 block);

    constructor (address _marketing) Owned(msg.sender) ERC20("Shohei Ohtani", "Ohtani", 18) {
        marketing = _marketing;
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

        startingBlock = block.number;
        taxLowerBlockIntermediate = startingBlock + 50;
        taxLowerBlockFinal = startingBlock + 150;

        isFeeExempt[_marketing] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;

        uint supply = 42069000 * (10**decimals);

        pair = IDEXFactory(factory).createPair(address(this), WETH);
        
        allowance[address(this)][router] = type(uint256).max;
        allowance[address(this)][pair] = type(uint256).max;

        _mint(owner, supply);

        swapThreshold = supply * swapPercent / swapDenominator;
    }

    /// @notice By using super.transfer we bypass any buy taxes after the intermediate block
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (block.number > taxLowerBlockIntermediate) {
            return super.transfer(recipient, amount);
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[sender][msg.sender];

        if (allowed != type(uint256).max) allowance[sender][msg.sender] = allowed - amount;

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (amount > (totalSupply * whalePercent / whaleDenominator) && sender != owner && recipient != owner && sender != address(this)) { revert("Transfer amount exceeds the whale amount"); }
        if(inSwap){ return super.transferFrom(sender, recipient, amount); }

        if(shouldSwapBack()){ swapBack(); }

        balanceOf[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;

        unchecked {
            // Cannot overflow because the sum of all user
            balanceOf[recipient] += amountReceived;
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        if (fee == startingFee && block.number > taxLowerBlockIntermediate) {
            emit FeeChanged(intermediateSellFee, taxLowerBlockIntermediate);
            fee = intermediateSellFee;
        }
        if (fee == intermediateSellFee && block.number > taxLowerBlockFinal) {
            emit FeeChanged(finalFee, block.number);
            fee = finalFee;
        }
        // If the fee is 0, we don't take taxes
        if (fee == finalFee) {
            return amount;
        }
        uint256 feeAmount = (amount * fee) / feeDenominator;
        balanceOf[address(this)] = balanceOf[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair 
        && !inSwap
        && balanceOf[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balance = this.balanceOf(address(this));

        IDEXRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            balance,
            0,
            path,
            marketing,
            block.timestamp
        );
    }

    function manualSwap() external {

    }

    function clearStuckBalance() external {
        payable(marketing).transfer(address(this).balance);
    }

    receive() external payable {}
}