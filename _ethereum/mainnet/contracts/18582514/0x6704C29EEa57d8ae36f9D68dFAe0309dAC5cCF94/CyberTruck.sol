// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract CyberTruck is Ownable, ERC20 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private initToken = 6900000000 * 10 ** 18;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public factory;
    address public pair;
    address public marketingAddress;

    uint256 public buyFee = 2;
    uint256 public sellFee = 2;
    bool inSwap = false;

    mapping(address => bool) public isExcludedFromFee;
    uint256 public numTokenSwap = 100000000 * 10 ** 18;

    bool public tradingEnabled;
    constructor(address _router) ERC20("CYBERTRUCK", "CYBERTRUCK") {
        _mint(_msgSender(), initToken);
//        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x327Df1E6de05895d2ab08513aaDD9313Fe505d86);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;
        factory = IUniswapV2Factory(_uniswapV2Router.factory());
        marketingAddress = address(_msgSender());
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        tradingEnabled = false;
        address _pair = factory.createPair(uniswapV2Router.WETH(), address(this));
        pair = _pair;
    }

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {

        uint256 taxFee;
        require(tradingEnabled || isExcludedFromFee[sender] || isExcludedFromFee[recipient], "Trading not yet enabled!");
        if (inSwap) {
            super._transfer(sender, recipient, amount);
            return;
        }
        if (!isExcludedFromFee[sender] && isPair(recipient)) {
            taxFee = sellFee;
        } else if (!isExcludedFromFee[recipient] && isPair(sender)) {
            taxFee = buyFee;
        }

        if (taxFee > 0 && sender != address(this) && recipient != address(this)) {
            uint256 _fee = amount.mul(taxFee).div(100);
            super._transfer(sender, address(this), _fee);
            amount = amount.sub(_fee);
        } else {
            if (balanceOf(address(this)) > numTokenSwap && !isPair(sender)) {
                swapFeeToMarketing();
            }
        }

        super._transfer(sender, recipient, amount);
    }

    function swapFeeToMarketing() internal lockTheSwap {
        uint256 numTokenToSell = balanceOf(address(this));
        swapTokensForETH(numTokenToSell);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETH(tokenAmount, 0, path, marketingAddress, block.timestamp);
    }

    function setExcludeFromFee(address _address, bool _status) external onlyOwner {
        require(_address != address(0), "0x is not accepted here");
        require(isExcludedFromFee[_address] != _status, "Status was set");
        isExcludedFromFee[_address] = _status;
    }

    function changeMarketingAddress(address _marketingAddress) external {
        require(_msgSender() == marketingAddress, "Only Marketing Wallet!");
        require(_marketingAddress != address(0), "0x is not accepted here");

        marketingAddress = _marketingAddress;
    }

    function isPair(address _pair) public view returns (bool) {
        return pair==_pair;
    }

    // receive eth
    receive() external payable {}

}
