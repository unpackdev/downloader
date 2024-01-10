// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

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

contract JPEGvaultDAOTokenV3 is ERC20SnapshotUpgradeable, OwnableUpgradeable {
    //
    // Don't touch this if you want to upgrade - BEGIN
    //

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private excludedRedistribution; // exclure de la redistribution
    mapping(address => bool) private excludedTax;

    IUniswapV2Router02 private m_UniswapV2Router;
    address private uniswapV2Pair;
    address private WETHAddr;

    address private growthAddress; // Should no longer be used since v3
    address private vaultAddress; // Should no longer be used since v3
    address private liquidityAddress; // Should no longer be used since v3
    address private redistributionContract;

    uint8 private growthFees; // Should no longer be used since v3
    uint8 private vaultFees; // Should no longer be used since v3
    uint8 private liquidityFees; // Should no longer be used since v3
    uint8 private autoLiquidityFees;

    // Autoselling ratio between 0 and 100
    uint8 private autoSellingRatio;

    uint216 private minAmountForSwap;

    // Stores tokens waiting for the next swap
    uint private autoSellGrowthStack;
    uint private autoSellVaultStack;
    uint private autoSellLiquidityStack;

    //
    // Don't touch this if you want to upgrade - END
    //

    // v3 BEGIN

    uint8 public purchaseTax;
    uint8 public sellTax;
    uint8 public walletTax;

    address private treasuryAddress;

    uint16 public minimumBlockDelay;
    bool private migrated2v3;
    address private bridgeAddress;

    uint private autoSellStack;

    mapping(address => uint256) private lastTransfer;

    // v3 END

    function migrate2v3() external {
        require(migrated2v3 == false, "Already migrated");

        autoSellGrowthStack = 0;
        autoSellVaultStack = 0;
        autoSellLiquidityStack = 0;

        purchaseTax = 10;
        sellTax = 10;
        walletTax = 10;

        autoSellingRatio = 0;
        autoLiquidityFees = 0;

        treasuryAddress = 0x73d6F7de9e9Ba999088B691b72b7291e7738e0eD;
        excludedTax[treasuryAddress] = true;

        super._transfer(address(this), treasuryAddress, balanceOf(address(this)));

        migrated2v3 = true;
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (!excludedTax[sender] &&
            !excludedTax[recipient]) {
            if (recipient == uniswapV2Pair) {
                amount = applyTaxes(sender, amount, sellTax);
                checkLastTransfer(sender);
            }
            else if (sender == uniswapV2Pair) {
                amount = applyTaxes(sender, amount, purchaseTax);
                checkLastTransfer(recipient);
            }
            else {
                amount = applyTaxes(sender, amount, walletTax);
            }
        }
        super._transfer(sender, recipient, amount);
    }

    function checkLastTransfer(address trader) internal {
        if (minimumBlockDelay > 0) {
            require ((block.number - lastTransfer[trader]) >= minimumBlockDelay,
                      "Transfer too close from previous one");
            lastTransfer[trader] = block.number;
        }
    }

    function applyTaxes(address sender, uint amount, uint8 tax) internal returns (uint newAmountTransfer) {
        uint amountTax = amount * tax;
        uint amountAutoLiquidity = amount * autoLiquidityFees;
        // Cheaper without "no division by 0" check
        unchecked {
            amountTax /= 100;
            amountAutoLiquidity /= 100;
        }

        newAmountTransfer = amount
            - amountTax
            - amountAutoLiquidity;

        // Apply autoselling ratio
        uint autoSell = amountTax * autoSellingRatio;

        // Cheaper without "no division by 0" check
        unchecked {
            autoSell /= 100;
        }

        // Transfer the remaining tokens to wallets
        super._transfer(sender, treasuryAddress, amountTax - autoSell);

        // Transfer all autoselling + autoLP to the contract
        super._transfer(sender, address(this), autoSell
                                               + amountAutoLiquidity);

        uint tokenBalance = balanceOf(address(this));

        // Only swap if it's worth it
        if (tokenBalance >= (minAmountForSwap * 1 ether)
            && uniswapV2Pair != address(0)
            && uniswapV2Pair != msg.sender) {

            swapAndLiquify(tokenBalance,
                            autoSell);
        } else {
            // Stack tokens to be swapped for autoselling
            autoSellStack = autoSellStack + autoSell;
        }
    }

    function swapAndLiquify(uint tokenBalance,
                            uint autoSell) internal {
        uint finalAutoSell = autoSellStack + autoSell;

        uint amountToLiquifiy = tokenBalance - finalAutoSell;

        // Stack tokens for autoliquidity pool
        uint tokensToBeSwappedForLP;
        unchecked {
            tokensToBeSwappedForLP = amountToLiquifiy / 2;
        }
        uint tokensForLP = amountToLiquifiy - tokensToBeSwappedForLP;

        uint totalToSwap = finalAutoSell + tokensToBeSwappedForLP;

        // Swap all in one call
        uint balanceInEth = address(this).balance;
        swapTokensForEth(totalToSwap);
        uint totalETHswaped = address(this).balance - balanceInEth;

        // Redistribute according to weigth
        uint autosellETH = totalETHswaped * finalAutoSell / totalToSwap;

        AddressUpgradeable.sendValue(payable(treasuryAddress), autosellETH);

        uint availableETHForLP = totalETHswaped - autosellETH;
        addLiquidity(tokensForLP, availableETHForLP);

        autoSellStack = 0;
    }

    function addLiquidity(uint tokenAmount, uint ethAmount) internal {
        if (tokenAmount >0) {
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

    function setMinimumBlockDelay(uint16 blockCount) external onlyOwner {
        minimumBlockDelay = blockCount;
    }

    function setPurchaseTax(uint8 _tax) external onlyOwner {
        purchaseTax = _tax;
    }

    function setSellTax(uint8 _tax) external onlyOwner {
        sellTax = _tax;
    }

    function setWalletTax(uint8 _tax) external onlyOwner {
        walletTax = _tax;
    }

    function setTreasuryAddress(address _address) external onlyOwner {
        treasuryAddress = _address;
        excludedTax[_address] = true;
    }

    function setBridgeAddress(address _address) external onlyOwner {
        bridgeAddress = _address;
        excludedTax[_address] = true;
    }

    function excludeTaxAddress(address _address) external onlyOwner {
        excludedTax[_address] = true;
    }

    function removeTaxAddress(address _address) external onlyOwner {
        require(_address != address(this), "Not authorized to remove the contract from tax");
        excludedTax[_address] = false;
    }

    // Bridging feature
    function mint(address to, uint256 amount) external {
        require(msg.sender == bridgeAddress, "Only bridge can mint");
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        require(msg.sender == bridgeAddress, "Only bridge can mint");
        _burn(to, amount);
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
