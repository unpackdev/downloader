// Twitter: https://twitter.com/pgfe10000i
// Telegram: https://t.me/pgfe10000i

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Owned.sol";
import "./ERC20.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PeterGriffinFortniteEminem10000inu is ERC20, Owned {
    mapping (address => bool) isFeeExempt;

    uint256 public fee;
    uint256 constant feeDenominator = 1000;
    uint256 public whaleDenominator = 100;

    address internal team;

    IDEXRouter public router;
    address public pair;

    uint256 public swapThreshold;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _team, uint256 _fee) Owned(msg.sender) ERC20("PeterGriffinFortniteEminem10000inu", "VBUCKS", 18) {
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        team = _team;
        fee = _fee;
        allowance[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[_team] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;

        uint supply = 42069000 * (10**decimals);

        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());

        _mint(owner, supply);

        swapThreshold = supply / 1000 * 2; // 0.2%
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[sender][msg.sender];

        if (allowed != type(uint256).max) allowance[sender][msg.sender] = allowed - amount;

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (amount > totalSupply / whaleDenominator && sender != owner) { revert("Transfer amount exceeds the whale amount"); }
        if(inSwap){ return super.transferFrom(sender, recipient, amount); }

        if(shouldSwapBack(recipient)){ swapBack(); }

        balanceOf[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;

        unchecked {
            // Cannot overflow because the sum of all user
            balanceOf[recipient] += amountReceived;
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * fee) / feeDenominator;
        balanceOf[address(this)] = balanceOf[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function shouldSwapBack(address to) internal view returns (bool) {
        return msg.sender != pair 
        && !inSwap
        && balanceOf[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance - balanceBefore;

        (bool TeamSuccess,) = payable(team).call{value: amountETH, gas: 30000}("");
        require(TeamSuccess, "receiver rejected ETH transfer");
    }

    function clearStuckBalance() external {
        payable(team).transfer(address(this).balance);
    }

    function setWhaleDenominator(uint256 _whaleDenominator) external onlyOwner {
        whaleDenominator = _whaleDenominator;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    receive() external payable {}
}