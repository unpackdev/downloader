// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./PriceOracle.sol";
import "./IVicsExchange.sol";
import "./IDABotManager.sol";

interface IERC20Token {
    function decimals() external view returns(uint8);
}

contract SimpleVicsExchange is IVicsExchange, Context, Ownable, Initializable {

    using SafeERC20 for IERC20;

    uint public _vicsPrice;
    PriceOracle public priceOracle;
    IERC20 public _vics;
    IDABotManager public _botManager;
    

    event Swap(address indexed asset, uint amountIn, uint amountOut);
    event VicsPriceUpdated(uint previousPrice, uint newPrice);
    event BotManagerChanged(address indexed oldManager, address indexed newManager);

    function initialize(IERC20 vics_, uint price, PriceOracle oracle) external payable initializer {
        _vicsPrice = price;
        priceOracle = oracle;
        _vics = vics_;
        _transferOwnership(_msgSender());
    }

    function setVicsPrice(uint price) external onlyOwner {
        emit VicsPriceUpdated(_vicsPrice, price);
        _vicsPrice = price;
    }

    function vicsPrice() public view returns(uint) {
        uint currentVicsPrice = priceOracle.getAssetPrice(address(_vics));
        if (currentVicsPrice == 0) 
            currentVicsPrice = _vicsPrice;
        return currentVicsPrice;
    }

    function setBotManager(address account) external onlyOwner {
        emit BotManagerChanged(address(_botManager), account);
        _botManager = IDABotManager(account);
    }

    function withdraw(IERC20 asset, uint amount) external onlyOwner {
        asset.safeTransfer(owner(), amount);
    }

    function swap(IERC20 asset, uint amountIn) external override returns(uint amountOut) { 
        uint assetPrice = priceOracle.getAssetPrice(address(asset));
        uint currentVicsPrice = vicsPrice();

        require(assetPrice > 0, "VicsExchange: cannot determine asset price");
        require(_vicsPrice > 0, "VicsExchange: vics price is not set");
        require(address(_botManager) != address(0), "VicsExchange: bot manager not set");
        require(_botManager.isRegisteredBot(_msgSender()), "VicsExchange: for registered bot only");

        asset.safeTransferFrom(_msgSender(), address(this), amountIn);

        amountOut = toWad(asset, amountIn) * assetPrice / currentVicsPrice;
        require(_vics.balanceOf(address(this)) >= amountOut, 'VicsExchange: insufficient VICS supply');
        _vics.safeTransfer(_msgSender(), amountOut);

        emit Swap(address(asset), amountIn, amountOut);
    }

    function toWad(IERC20 asset, uint amount) private view returns(uint) {
        uint8 assetDecimal = IERC20Token(address(asset)).decimals();
        if (assetDecimal < 18)
            amount = amount * 10**(18 - assetDecimal);
        return amount;
    }
}