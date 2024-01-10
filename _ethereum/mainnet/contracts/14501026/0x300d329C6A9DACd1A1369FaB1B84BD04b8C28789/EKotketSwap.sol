// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./EGovernanceBase.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract EKotketSwap is EGovernanceBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint public kokeBasePrice = 200000;
    address walletAddress;

    event KokeBasePriceChanged(uint kokeBasePrice, address setter);
    event WalletAddressChanged(address walletAddress, address setter);

    event ExchangeUsdtToKoke(uint amountUSDT, uint amountKOKE, address beneficiary);
    event ExchangeKokeToUsdt(uint amountUSDT, uint amountKOKE, address beneficiary);

    constructor(address _governanceAdress, address _walletAddress, uint _kokeBasePrice) EGovernanceBase(_governanceAdress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        kokeBasePrice = _kokeBasePrice;
        walletAddress = _walletAddress;
    }

    function updateKokeBasePrice(uint _kokeBasePrice) public onlyAdminPermission{
        kokeBasePrice = _kokeBasePrice;
        emit KokeBasePriceChanged(kokeBasePrice, _msgSender());
    }

    function updateWalletAddress(address _walletAddress) public onlyAdminPermission{
        walletAddress = _walletAddress;
        emit WalletAddressChanged(walletAddress, _msgSender());
    }

    function exchangeUsdtToKoke(uint _amountUSDT) public{
        address usdtAddress = governance.usdtAddress();
        address kotketTokenAddress = governance.kotketTokenAddress();

        require(usdtAddress != address(0) && kotketTokenAddress != address(0), "Not found tokens address");

        IERC20 usdt = IERC20(usdtAddress);
        uint usdtBalance = usdt.balanceOf(_msgSender());
        require(usdtBalance >= _amountUSDT, "Insufficient USDT Balance!");

        uint usdtAllowance = usdt.allowance(_msgSender(), address(this));
        require(usdtAllowance >= _amountUSDT, "Not Allow Enough USDT To Exchange!");
        
        uint amountKOKE = _amountUSDT.mul(10**18).div(kokeBasePrice);

        require(amountKOKE > 0, "Invalid swap amount!");

        IERC20 kotkettoken = IERC20(kotketTokenAddress);
        uint kokeBalance = kotkettoken.balanceOf(walletAddress);
        require(kokeBalance >= amountKOKE, "Insufficient wallet KOKE Balance!");

        uint kokeAllowance = kotkettoken.allowance(walletAddress, address(this));
        require(kokeAllowance >= amountKOKE, "Contract does not have enough KOKE token allowance from wallet!");

        usdt.safeTransferFrom(_msgSender(), walletAddress, _amountUSDT);
        kotkettoken.safeTransferFrom(walletAddress, _msgSender(), amountKOKE);

        emit ExchangeUsdtToKoke(_amountUSDT, amountKOKE, _msgSender());
    }

    function exchangeKokeToUsdt(uint _amountKOKE) public{
        address usdtAddress = governance.usdtAddress();
        address kotketTokenAddress = governance.kotketTokenAddress();

        require(usdtAddress != address(0) && kotketTokenAddress != address(0), "Not found tokens address");

        IERC20 kotkettoken = IERC20(kotketTokenAddress);
        uint kokeBalance = kotkettoken.balanceOf(_msgSender());
        require(kokeBalance >= _amountKOKE, "Insufficient KOKE Balance!");

        uint kokeAllowance = kotkettoken.allowance(_msgSender(), address(this));
        require(kokeAllowance >= _amountKOKE, "Not Allow Enough KOKE To Exchange!");

        uint amountUSDT = _amountKOKE.mul(kokeBasePrice).div(10**18);

        require(amountUSDT > 0, "Invalid swap amount!");

        IERC20 usdt = IERC20(usdtAddress);
        uint usdtBalance = usdt.balanceOf(walletAddress);
        require(usdtBalance >= amountUSDT, "Insufficient wallet USDT Balance!");

        uint usdtAllowance = usdt.allowance(walletAddress, address(this));
        require(usdtAllowance >= amountUSDT, "Contract does not have enough USDT allowance from wallet!");
        
    
        kotkettoken.safeTransferFrom(_msgSender(), walletAddress, _amountKOKE);
        usdt.safeTransferFrom(walletAddress, _msgSender(), amountUSDT);

        emit ExchangeKokeToUsdt(amountUSDT, _amountKOKE, _msgSender());
    }
}