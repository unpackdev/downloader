// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFlashLoanReceiver.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";


abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  constructor() public {
    ILendingPoolAddressesProvider _provider = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    ADDRESSES_PROVIDER = _provider;
    LENDING_POOL = ILendingPool(_provider.getLendingPool());
  }
}

contract AlphaThreeContract01 is Ownable, FlashLoanReceiverBase {
    
    uint256 public balance;
    uint256 public original;
    address[] arbPath;
    IUniswapV2Router02 public immutable uniSwapV2Router;

    event tokenTraded(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    );

    event flashloadRequested(
        uint256 amount,
        address[] path
    );
    
    constructor () FlashLoanReceiverBase () public {
        IUniswapV2Router02 _UniSwapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniSwapV2Router = _UniSwapV2Router;
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {

        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //
        try this.executeArbitrage() {
        } catch Error(string memory) {
            // Reverted with a reason string provided
        } catch (bytes memory) {
            //  TODO
        }
        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            require (IERC20(assets[i]).balanceOf(address(this)) > amountOwing, 'Not enough amount to pay back');
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }
    
    function executeArbitrage() public {
        require (arbPath.length > 1, "Path too short");
        require (arbPath[0] == arbPath[arbPath.length - 1], "Start and end token needs to be the same");
        
        for (uint256 i = 0; i < arbPath.length - 1; i++) {
            address inputTokenAddress = arbPath[i];
            address outputTokenAddress = arbPath[i + 1];
            
            balance = exchangeERC20(balance, inputTokenAddress, outputTokenAddress);
        }
        
        require (balance > original, "Did not make money");
    }
    
    function exchangeERC20(uint amount, address inputToken, address outputToken) public onlyOwner returns (uint256 tradedTokenAmount) {
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;
        
        uint deadline = block.timestamp + 3000;
        
        if (inputToken == uniSwapV2Router.WETH()) {
            tradedTokenAmount = _swapEthToToken(amount, deadline, path);
        } else if (outputToken == uniSwapV2Router.WETH()){
            tradedTokenAmount = _swapTokenToEth(amount, deadline, path);
        } else {
            tradedTokenAmount = _swapTokenToToken(amount, deadline, path);
        }

        emit tokenTraded(inputToken, outputToken, amount, tradedTokenAmount);
        
        return tradedTokenAmount;
    }
    
    function _swapTokenToToken(uint amount, uint deadline, address[] memory path) private returns (uint256 tradedTokenAmount) { 
        require(amount <= IERC20(path[0]).balanceOf(address(this)), "Not enough token _swapTokenToToken");
        
        uint256 beforeBalance = IERC20(path[1]).balanceOf(address(this));
        IERC20(path[0]).approve(address(uniSwapV2Router), amount);
        
        try uniSwapV2Router.swapExactTokensForTokens(
            amount,
            0, 
            path, 
            address(this), 
            deadline
        ){
        } catch {
            // error handling when arb failed due to trade 1
        }
        
        uint256 afterBalance = IERC20(path[1]).balanceOf(address(this));
        return afterBalance.sub(beforeBalance);
    }
    
    function _swapTokenToEth(uint amount, uint deadline, address[] memory path) private returns (uint256 tradedTokenAmount) { 
        require(amount <= IERC20(path[0]).balanceOf(address(this)), "Not enough token _swapTokenToEth");

        uint256 beforeBalance = address(this).balance;
        IERC20(path[0]).approve(address(uniSwapV2Router), amount);
        
        try uniSwapV2Router.swapExactTokensForETH(
            amount,
            0, 
            path, 
            address(this), 
            deadline
        ){
        } catch {
            // error handling when arb failed due to trade 1
        }
        uint256 afterBalance = address(this).balance;
        return afterBalance.sub(beforeBalance);
    }
    
    function _swapEthToToken(uint amount, uint deadline, address[] memory path) private returns (uint256 tradedTokenAmount) { 
        require(amount <= address(this).balance, "Not enough token _swapEthToToken");

        uint256 beforeBalance = IERC20(path[1]).balanceOf(address(this));
        
        try uniSwapV2Router.swapExactETHForTokens{ 
            value: amount 
        }(
            0, 
            path, 
            address(this), 
            deadline
        ){
        } catch {
            // error handling when arb failed due to trade 1
        } 
        
        uint256 afterBalance = IERC20(path[1]).balanceOf(address(this));
        return afterBalance.sub(beforeBalance);
    }

    function withdraw(address _assetAddress) public onlyOwner {
        uint assetBalance;
        if (_assetAddress == address(0)) {
            assetBalance = address(this).balance;
            msg.sender.transfer(assetBalance);
        } else {
            assetBalance = IERC20(_assetAddress).balanceOf(address(this));
            IERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
        }
    }

    function myFlashLoanCall(address[] memory _arbPath, uint256 amount) public onlyOwner {
        arbPath = _arbPath;
        balance = amount;
        original = amount;

        address originalTokenAddress = _arbPath[0];
        if (originalTokenAddress == uniSwapV2Router.WETH()) {
            originalTokenAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        }

        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = originalTokenAddress;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        flashloadRequested(amount, _arbPath);

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
}