pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./ISpace.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    function owner() external view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

contract SURYA is ERC20, Ownable {
    uint256 public constant startTotalSupply = 1e9 * (10 ** _decimals);
    uint256 constant _startMaxBuyCount = (startTotalSupply * 25) / 10000;
    uint256 constant _addMaxBuyPercentPerSec = 1; // add 0.01%/second
    IUniswapV2Router02 constant router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ISpace public immutable space;
    bool _inSwap;
    address pair;
    uint256 _startTime;
    uint256 public feePercent = 10;
    uint256 public ercFeePercent = 20; // noe of this is starts destruction on claim

    constructor(address space_) ERC20("SURYA", "SUN") {
        space = ISpace(space_);
    }

    function setFeePercent(uint256 percent) external onlyOwner {
        require(percent <= 10);
        feePercent = percent;
    }

    function setErcPercent(uint256 percent) external onlyOwner {
        require(percent <= 100);
        ercFeePercent = percent;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (_inSwap) {
            super._transfer(from, to, amount);
            return;
        }

        if (to == address(0)) {
            require(
                _balances[from] >= amount,
                "ERC20: transfer amount exceeds balance"
            );
            unchecked {
                _balances[from] -= amount;
                _totalSupply -= amount;
            }
            emit Transfer(from, to, amount);
            return;
        }

        if (from == pair) {
            transferFromPair(to, amount);
            space.executeNewPlanets();
            return;
        }

        if (to == pair) {
            transferToPair(from, amount);
            space.executeNewPlanets();
            return;
        }

        super._transfer(from, to, amount);
    }

    function transferFromPair(address to, uint256 amount) private {
        require(amount <= maxBuy(), "maximum buy count limit");
        uint256 tax = (amount * (feePercent / 2)) / 100;
        uint256 ercPercent = (tax * ercFeePercent) / 100;
        uint256 ethPercent = tax - ercPercent;
        if (ercPercent > 0) super._transfer(pair, address(space), ercPercent);
        if (ethPercent > 0) super._transfer(pair, address(this), ethPercent);
        super._transfer(pair, to, amount - 2 * tax);
    }

    function transferToPair(address from, uint256 amount) private {
        uint256 swapCount = balanceOf(address(this));
        uint256 maxSwapCount = 2 * amount;
        if (swapCount > maxSwapCount) swapCount = maxSwapCount;
        _swapTokensForEth(swapCount);
        super._transfer(from, pair, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) internal lockTheSwap {
        if (tokenAmount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // make the swap
        router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(space),
            block.timestamp
        );
    }

    function burned() public view returns (uint256) {
        return startTotalSupply - totalSupply();
    }

    function createPair() external payable lockTheSwap {
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        _mint(address(this), startTotalSupply);
        _approve(address(this), address(router), type(uint256).max);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            startTotalSupply,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        _startTime = block.timestamp;
    }

    function maxBuy() public view returns (uint256) {
        if (pair == address(0)) return startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            10000;
        if (count > startTotalSupply) count = startTotalSupply;
        return count;
    }

    function maxBuyWithoutDecimals() public view returns (uint256) {
        return maxBuy() / (10 ** _decimals);
    }
}
