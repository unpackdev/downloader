// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./Owned.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./EnumerableSet.sol";

contract LilManyu is ERC20, Owned {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet receivers;
    mapping(address => uint256) public receiversShares;
    uint256 public totalShares;

    uint256 public TOTAL_SUPPLY = 10_000_000_000 ether;

    IUniswapV2Router02 public constant uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public boughtAmount;

    // 1.25% of total supply
    uint256 public maxBuyAmount = 125_000_000 ether;

    uint256 public buyFee = 0;
    uint256 public sellFee = 0;

    address public immutable pair;

    bool public tradingEnabled;

    constructor() ERC20("LilManyu", "MANYU", 18) Owned(msg.sender) {
        _mint(msg.sender, TOTAL_SUPPLY);

        isExcludedFromFee[msg.sender] = true;
        isWhitelisted[msg.sender] = true;

        address _weth = uniswapRouter.WETH();

        pair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), _weth);

        isExcludedFromFee[pair] = true;
        isExcludedFromFee[address(this)] = true;

        allowance[address(this)][address(uniswapRouter)] = type(uint256).max;
    }

    function setMaxBuyAmount(uint256 _maxBuyAmount) external onlyOwner {
        require(_maxBuyAmount > 0, "max-buy-amount-must-be-greater-than-zero");
        maxBuyAmount = _maxBuyAmount;
    }

    function setExcludedFromFee(address account, bool excluded) external onlyOwner {
        isExcludedFromFee[account] = excluded;
    }

    function setWhitelisted(address account, bool whitelisted) external onlyOwner {
        isWhitelisted[account] = whitelisted;
    }

    function setBuyFee(uint256 _buyFee) external onlyOwner {
        require(_buyFee <= 30, "max-buy-fee-exceeded");
        buyFee = _buyFee;
    }

    function setSellFee(uint256 _sellFee) external onlyOwner {
        require(_sellFee <= 30, "max-sell-fee-exceeded");
        sellFee = _sellFee;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function removeLimits() external onlyOwner {
        maxBuyAmount = type(uint256).max;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;

        if (msg.sender == pair) {
            require(tradingEnabled || isWhitelisted[to], "trading-not-enabled");

            if (!isExcludedFromFee[to]) {
                uint256 taxAmount = amount * buyFee / 100;
                amount -= taxAmount;
                boughtAmount[to] += amount;

                require(boughtAmount[to] <= maxBuyAmount, "max-buy-amount-exceeded");

                balanceOf[address(this)] += taxAmount;
                distributeShares();
            }
        }

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        if (to == pair) {
            require(tradingEnabled || isWhitelisted[from], "trading-not-enabled");

            if (!isExcludedFromFee[from]) {
                uint256 taxAmount = amount * sellFee / 100;
                amount -= taxAmount;
                balanceOf[address(this)] += taxAmount;
                _swapTokensForEth(balanceOf[address(this)]);
            }
        }

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
        if (tokenAmount == 0) return;
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function addReceiver(address receiver, uint256 shares) external onlyOwner {
        require(!receivers.contains(receiver), "receiver-already-added");
        require(shares > 0, "shares-must-be-greater-than-zero");
        require(totalShares + shares <= 100, "max-shares-exceeded");

        receivers.add(receiver);
        receiversShares[receiver] = shares;
        totalShares += shares;
    }

    function removeReceiver(address receiver) external onlyOwner {
        require(receivers.contains(receiver), "receiver-not-added");

        receivers.remove(receiver);
        totalShares -= receiversShares[receiver];
        receiversShares[receiver] = 0;
    }

    function getReceivers() public view returns (address[] memory, uint256[] memory) {
        address[] memory _receivers = new address[](receivers.length());
        uint256[] memory _shares = new uint256[](receivers.length());

        for (uint256 i = 0; i < receivers.length(); i++) {
            _receivers[i] = receivers.at(i);
            _shares[i] = receiversShares[_receivers[i]];
        }

        return (_receivers, _shares);
    }

    function distributeShares() public {
        uint256 balance = address(this).balance;

        if (balance == 0) return;

        (address[] memory _receivers, uint256[] memory _shares) = getReceivers();

        for (uint256 i = 0; i < _receivers.length; i++) {
            payable(_receivers[i]).transfer((balance * _shares[i]) / 100);
        }
    }

    receive() external payable {}
}
