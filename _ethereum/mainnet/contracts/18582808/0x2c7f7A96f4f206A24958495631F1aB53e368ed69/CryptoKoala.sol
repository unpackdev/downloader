// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract CryptoKoala is Ownable, ERC20 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private initToken = 1000000000 * 10 ** 18;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public factory;
    address public pair;
    address public treePlantingAddress;

    uint256 public buyFee = 3;
    uint256 public sellFee = 3;
    bool inSwap = false;

    mapping(address => bool) public isExcludedFromFee;
    uint256 public antiBotAmount = 37500000 * 10 ** 18;
    uint256 public numTokensAutoswap = 3500000 * 10 ** 18;
    uint256 public maxTokensAutoswap = 15000000 * 10 ** 18;

    uint256 public antiBotInterval = 25;
    uint256 public antiBotEndTime;
    bool public tradingEnabled;
    constructor(address _router) ERC20("Crypto Koala", "CKOALA") {
        _mint(_msgSender(), initToken);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;
        factory = IUniswapV2Factory(_uniswapV2Router.factory());
        treePlantingAddress = address(0xBAbF1cC4101Cc515200ac0EcEAA90D0E6140D480);
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[treePlantingAddress] = true;
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
        antiBotEndTime = block.timestamp + antiBotInterval;
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
        //Take Fee
        if (!isExcludedFromFee[sender] && isPair(recipient)) {
            taxFee = sellFee;
        } else if (!isExcludedFromFee[recipient] && isPair(sender)) {
            taxFee = buyFee;
        }

        if (
            antiBotEndTime > block.timestamp &&
            amount > antiBotAmount &&
            sender != address(this) &&
            recipient != address(this) &&
            isPair(sender)
        ) {
            taxFee = 85;
        }

        if (taxFee > 0 && sender != address(this) && recipient != address(this)) {
            uint256 _fee = amount.mul(taxFee).div(100);
            super._transfer(sender, address(this), _fee);
            amount = amount.sub(_fee);
        } else {
            if (balanceOf(address(this)) > numTokensAutoswap && !isPair(sender)) {
                swapFeeToTreePlanting();
            }
        }

        super._transfer(sender, recipient, amount);
    }

    function swapFeeToTreePlanting() internal lockTheSwap {
        uint256 numTokenToSell = balanceOf(address(this)) > maxTokensAutoswap ? maxTokensAutoswap : balanceOf(address(this));
        swapTokensForETH(numTokenToSell);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETH(tokenAmount, 0, path, treePlantingAddress, block.timestamp);
    }

    function setExcludeFromFee(address _address, bool _status) external onlyOwner {
        require(_address != address(0), "0x is not accepted here");
        require(isExcludedFromFee[_address] != _status, "Status was set");
        isExcludedFromFee[_address] = _status;
    }

    function changeTreePlantingAddress(address _treePlantingAddress) external {
        require(_msgSender() == treePlantingAddress, "Only TreePlanting Wallet!");
        require(_treePlantingAddress != address(0), "0x is not accepted here");

        treePlantingAddress = _treePlantingAddress;
    }

    function isPair(address _pair) public view returns (bool) {
        return pair==_pair;
    }

    // receive eth
    receive() external payable {}

}
