// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./EnumerableSetUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./ERC20SnapshotUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

interface IUniswapV2Router02 {
    function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external;

    function WETH() external pure returns (address);
}

contract JPEGvaultDAOTokenV2 is ERC20SnapshotUpgradeable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private excludedRedistribution; // exclure de la redistribution
    mapping(address => bool) private excludedTax;

    IUniswapV2Router02 private m_UniswapV2Router;
    address private uniswapV2Pair;
    address private WETHAddr;

    address private growthAddress;
    address private vaultAddress;
    address private liquidityAddress;
    address private redistributionContract;

    uint8 private growthFees;
    uint8 private vaultFees;
    uint8 private liquidityFees;
    uint8 private autoLiquidityFees;

    // Autoselling ratio between 0 and 100
    uint8 private autoSellingRatio;

    uint216 private minAmountForSwap;

    // Stores tokens waiting for the next swap
    uint private autoSellGrowthStack;
    uint private autoSellVaultStack;
    uint private autoSellLiquidityStack;

    function initialize(address _growthAddress,
                address _vaultAddress,
                address _liquidityAddress,
                address _router) external initializer {
        __Ownable_init();
        __ERC20_init("JPEG", "JPEG");
        __ERC20Snapshot_init();

        m_UniswapV2Router = IUniswapV2Router02(_router);
        WETHAddr = m_UniswapV2Router.WETH();

        growthAddress = _growthAddress;
        _transferOwnership(growthAddress);
        vaultAddress = _vaultAddress;
        liquidityAddress = _liquidityAddress;

        excludedRedistribution.add(address(this));
        excludedRedistribution.add(growthAddress);
        excludedRedistribution.add(vaultAddress);
        excludedRedistribution.add(liquidityAddress);

        excludedTax[address(this)] = true;
        excludedTax[growthAddress] = true;
        excludedTax[vaultAddress] = true;
        excludedTax[liquidityAddress] = true;

        growthFees = 2;
        vaultFees = 6;
        liquidityFees = 1;
        autoLiquidityFees = 1;

        minAmountForSwap = 1000;

        autoSellingRatio = 70;

        _mint(growthAddress, 1000000000 * 10 ** 18);
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (!excludedTax[sender] &&
            !excludedTax[recipient]) {
            amount = applyTaxes(sender, amount);
        }
        super._transfer(sender, recipient, amount);
    }

    function applyTaxes(address sender, uint amount) internal returns (uint newAmountTransfer) {
        uint amountGrowth = amount * growthFees;
        uint amountVault = amount * vaultFees;
        uint amountLiquidity = amount * liquidityFees;
        uint amountAutoLiquidity = amount * autoLiquidityFees;
        // Cheaper without "no division by 0" check
        unchecked {
            amountGrowth /= 100;
            amountVault /= 100;
            amountLiquidity /= 100;
            amountAutoLiquidity /= 100;
        }

        newAmountTransfer = amount
            - amountGrowth
            - amountVault
            - amountLiquidity
            - amountAutoLiquidity;

        // Apply autoselling ratio
        uint autoSellGrowth = amountGrowth * autoSellingRatio;
        uint autoSellVault = amountVault * autoSellingRatio;
        uint autoSellLiquidity = amountLiquidity * autoSellingRatio;
        // Cheaper without "no division by 0" check
        unchecked {
            autoSellGrowth /= 100;
            autoSellVault /= 100;
            autoSellLiquidity /= 100;
        }

        // Transfer the remaining tokens to wallets
        super._transfer(sender, growthAddress, amountGrowth - autoSellGrowth);
        super._transfer(sender, vaultAddress, amountVault - autoSellVault);
        super._transfer(sender, liquidityAddress, amountLiquidity - autoSellLiquidity);

        // Transfer all autoselling + autoLP to the contract
        super._transfer(sender, address(this), autoSellGrowth
                                               + autoSellVault
                                               + autoSellLiquidity
                                               + amountAutoLiquidity);

        uint tokenBalance = balanceOf(address(this));

        // Only swap if it's worth it
        if (tokenBalance >= (minAmountForSwap * 1 ether)
            && uniswapV2Pair != address(0)
            && uniswapV2Pair != msg.sender) {

            swapAndLiquify(tokenBalance,
                            autoSellGrowth,
                            autoSellVault,
                            autoSellLiquidity);
        } else {
            // Stack tokens to be swapped for autoselling
            autoSellGrowthStack = autoSellGrowthStack + autoSellGrowth;
            autoSellVaultStack = autoSellVaultStack + autoSellVault;
            autoSellLiquidityStack = autoSellLiquidityStack + autoSellLiquidity;
        }
    }

    function swapAndLiquify(uint tokenBalance,
                            uint autoSellGrowth,
                            uint autoSellVault,
                            uint autoSellLiquidity) internal {
        uint finalAutoSellGrowth = autoSellGrowthStack + autoSellGrowth;
        uint finalAutoSellVault = autoSellVaultStack + autoSellVault;
        uint finalAutoSellLiquidity = autoSellLiquidityStack + autoSellLiquidity;

        uint totalStacked = finalAutoSellGrowth
                            + finalAutoSellVault
                            + finalAutoSellLiquidity;

        uint amountToLiquifiy = tokenBalance - totalStacked;

        // Stack tokens for autoliquidity pool
        uint tokensToBeSwappedForLP;
        unchecked {
            tokensToBeSwappedForLP = amountToLiquifiy / 2;
        }
        uint tokensForLP = amountToLiquifiy - tokensToBeSwappedForLP;

        uint totalToSwap = totalStacked + tokensToBeSwappedForLP;

        // Swap all in one call
        uint balanceInEth = address(this).balance;
        swapTokensForEth(totalToSwap);
        uint totalETHswaped = address(this).balance - balanceInEth;

        // Redistribute according to weigth
        uint growthETH = totalETHswaped * finalAutoSellGrowth / totalToSwap;
        uint vaultETH = totalETHswaped * finalAutoSellVault / totalToSwap;
        uint liquidityETH = totalETHswaped * finalAutoSellLiquidity / totalToSwap;

        AddressUpgradeable.sendValue(payable(growthAddress), growthETH);
        AddressUpgradeable.sendValue(payable(vaultAddress), vaultETH);
        AddressUpgradeable.sendValue(payable(liquidityAddress), liquidityETH);

        uint availableETHForLP = totalETHswaped - growthETH - vaultETH - liquidityETH;
        addLiquidity(tokensForLP, availableETHForLP);

        autoSellGrowthStack = 0;
        autoSellVaultStack = 0;
        autoSellLiquidityStack = 0;
    }

    function addLiquidity(uint tokenAmount, uint ethAmount) internal {
        // add liquidity with token and ETH
        _approve(address(this), address(m_UniswapV2Router), tokenAmount);
        m_UniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 amount) private {
        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = address(WETHAddr);

        _approve(address(this), address(m_UniswapV2Router), amount);

        m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            _path,
            address(this),
            block.timestamp
        );
    }

    function createRedistribution() public returns (uint, uint) {
        require(msg.sender == redistributionContract, "Bad caller");

        uint newSnapshotId = _snapshot();

        return (newSnapshotId, calcSupplyHolders());
    }

    function calcSupplyHolders() internal view returns (uint) {
        uint balanceExcluded = 0;

        for (uint i = 0; i < excludedRedistribution.length(); i++)
            balanceExcluded += balanceOf(excludedRedistribution.at(i));

        return totalSupply() - balanceExcluded;
    }

    // Tax management
    function setGrowthFees(uint8 _fees) external onlyOwner {
        growthFees = _fees;
    }

    function setVaultFees(uint8 _fees) external onlyOwner {
        vaultFees = _fees;
    }

    function setLiquidityFees(uint8 _fees) external onlyOwner {
        liquidityFees = _fees;
    }

    function setGrowthAddress(address _address) external onlyOwner {
        growthAddress = _address;
        excludedRedistribution.add(_address);
        excludedTax[_address] = true;
    }

    function setVaultAddress(address _address) external onlyOwner {
        vaultAddress = _address;
        excludedRedistribution.add(_address);
        excludedTax[_address] = true;
    }

    function setLiquidityAddress(address _address) external onlyOwner {
        liquidityAddress = _address;
        excludedRedistribution.add(_address);
        excludedTax[_address] = true;
    }

    function excludeTaxAddress(address _address) external onlyOwner {
        excludedTax[_address] = true;
    }

    function removeTaxAddress(address _address) external onlyOwner {
        require(_address != address(this), "Not authorized to remove the contract from tax");
        excludedTax[_address] = false;
    }

    // Liquidity settings

    function setAutoLiquidityFees(uint8 _fees) external onlyOwner {
        autoLiquidityFees = _fees;
    }

    function setMinAmountForSwap(uint216 _amount) external onlyOwner {
        minAmountForSwap = _amount;
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
        excludedRedistribution.add(_pair);
    }

    function setAutoSellingRatio(uint8 ratio) external onlyOwner{
        require(autoSellingRatio <= 100, "autoSellingRatio should be lower than 100");
        autoSellingRatio = ratio;
    }

    // Redistribution management

    function setRedistributionContract(address _address) external onlyOwner {
        redistributionContract = _address;
        excludedRedistribution.add(_address);
        excludedTax[_address] =true;
    }

    function removeRedistributionAddress(address _address) external onlyOwner {
        excludedRedistribution.remove(_address);
    }

    function excludedRedistributionAddress(address _address) external onlyOwner {
        excludedRedistribution.add(_address);
    }

}
