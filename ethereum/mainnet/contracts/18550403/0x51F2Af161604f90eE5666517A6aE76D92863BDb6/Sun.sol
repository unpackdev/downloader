pragma solidity ^0.8.23;

import "./Erc20.sol";
import "./ISunra.sol";
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

contract PoolCreatableErc20 is ERC20 {
    uint256 public constant startTotalSupply = 1e9 * (10 ** _decimals);
    IUniswapV2Router02 constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address internal pair;
    uint256 internal _startTime;
    bool internal _inSwap;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function createPair() external payable lockTheSwap {
        pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _mint(address(this), startTotalSupply);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            startTotalSupply,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        _startTime = block.timestamp;
    }
}

contract Sun is Ownable, PoolCreatableErc20 {
    uint256 constant _startMaxBuyCount = (startTotalSupply * 25) / 10000;
    uint256 constant _addMaxBuyPercentPerSec = 1; // add 0.01%/second
    ISunra public immutable sunra;
    uint256 public taxPercent = 10;
    uint256 public tokenTaxPercent = 20; // noe of this is starts destruction on take

    constructor(address sunra_) PoolCreatableErc20("Sun", "RA") {
        sunra = ISunra(sunra_);
    }

    function changeTaxPercent(uint256 percent) external onlyOwner {
        require(percent <= 15);
        taxPercent = percent;
    }

    function changeTokenTaxPercent(uint256 percent) external onlyOwner {
        require(percent <= 100);
        tokenTaxPercent = percent;
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
            sunra.createNewLands();
            return;
        }

        if (to == pair) {
            transferToPair(from, amount);
            sunra.createNewLands();
            return;
        }

        super._transfer(from, to, amount);
    }

    function transferFromPair(address to, uint256 amount) private {
        require(amount <= maximumBuyCount(), "maximum buy count limit");
        uint256 tax = (amount * taxPercent) / 100;
        uint256 ercFee = (tax * tokenTaxPercent) / 100;
        uint256 ethFee = tax - ercFee;
        if (ercFee > 0) super._transfer(pair, address(sunra), ercFee);
        if (ethFee > 0) super._transfer(pair, address(this), ethFee);
        super._transfer(pair, to, amount - ercFee - ethFee);
    }

    function transferToPair(address from, uint256 amount) private {
        uint256 tax = (amount * taxPercent) / 100;
        uint256 ercFee = (tax * tokenTaxPercent) / 100;
        uint256 ethFee = tax - ercFee;

        uint256 swapCount = balanceOf(address(this));
        uint256 maxSwapCount = 2 * amount;
        if (swapCount > maxSwapCount) swapCount = maxSwapCount;
        _swapTokensForEth(swapCount);
        if (ercFee > 0) super._transfer(from, address(sunra), ercFee);
        if (ethFee > 0) super._transfer(from, address(this), ethFee);
        super._transfer(from, pair, amount - ercFee - ethFee);
    }

    function _swapTokensForEth(uint256 tokenAmount) internal lockTheSwap {
        if (tokenAmount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(sunra),
            block.timestamp
        );
    }

    function burned() public view returns (uint256) {
        return startTotalSupply - totalSupply();
    }

    function maximumBuyCount() public view returns (uint256) {
        if (pair == address(0)) return startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            10000;
        if (count > startTotalSupply) count = startTotalSupply;
        return count;
    }

    function maximumBuyCountWithoutDecimals() public view returns (uint256) {
        return maximumBuyCount() / (10 ** _decimals);
    }
}
