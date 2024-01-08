// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IParaswapAugustus.sol";
import "./IUniswapV2Router02.sol";
import "./ILockedOwner.sol";

import "./FundLogic.sol";

contract BuybackVault {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20;

    address public fundDeployer;
    address public owner;

    address[] public deployedFunds;
    mapping(address => bool) isDeployedFund;

    address public PARASWAP_TOKEN_PROXY;
    address public PARASWAP_AUGUSTUS;
    address public UNISWAP_ROUTER;

    address public BOTS;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == fundDeployer || msg.sender == owner, "Unauthorized");
        _;
    }

    constructor(
        address _paraswapProxy,
        address _paraswapAugustus,
        address _uniRouter,
        address _bots
    ) public {
        owner = msg.sender;
        PARASWAP_TOKEN_PROXY = _paraswapProxy;
        PARASWAP_AUGUSTUS = _paraswapAugustus;
        UNISWAP_ROUTER = _uniRouter;
        BOTS = _bots;
    }

    function changeDeployer(address _newDeployer) external onlyOwner {
        fundDeployer = _newDeployer;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeParaswap(address _newProxy, address _newAugustus) external onlyOwner {
        PARASWAP_TOKEN_PROXY = _newProxy;
        PARASWAP_AUGUSTUS = _newAugustus;
    }

    function changeUniswap(address _newRouter) external onlyOwner {
        UNISWAP_ROUTER = _newRouter;
    }

    function changeBots(address _newBOTS) external onlyOwner {
        BOTS = _newBOTS;
    }

    function addFund(address _vaultProxy) external onlyDeployer {
        if(!isDeployedFund[_vaultProxy]){
            isDeployedFund[_vaultProxy] = true;
            deployedFunds.push(_vaultProxy);
        }
    }

    function removeFund(address _vaultProxy) external onlyDeployer {
        if(isDeployedFund[_vaultProxy]){
            isDeployedFund[_vaultProxy] = false;
            uint256 _length = deployedFunds.length;
            for (uint256 i = 0; i < _length; i++) {
                if (deployedFunds[i] == _vaultProxy) {
                    if (i < _length - 1) {
                        deployedFunds[i] = deployedFunds[_length - 1];
                    }
                    deployedFunds.pop();
                    break;
                }
            }
        }
    }

    function withdrawFromFund(address _fundProxy, uint256 _sharesAmount) public onlyOwner {
        uint256 _myBal = FundLogic(_fundProxy).balanceOf(address(this));
        if(_sharesAmount > _myBal || _sharesAmount == 0){
            _sharesAmount = _myBal;
        }

        // Soft fail
        if(_sharesAmount > 0){
            FundLogic(_fundProxy).withdraw(_sharesAmount);
        }
    }

    function withdrawFromFunds(address[] memory _funds) public onlyOwner {
        uint256 _length = _funds.length;
        for(uint256 i = 0; i < _length; i++){
            withdrawFromFund(_funds[i], 0); // Withdraw all
        }
    }

    function withdrawAllFunds() external onlyOwner {
        withdrawFromFunds(deployedFunds);
    }

    function paraswapSwap(address _src, uint256 _amount, uint256 _toAmount, uint256 _expectedAmount, IParaswapAugustus.Path[] memory _path) public onlyOwner {
        uint256 _srcBal = ERC20(_src).balanceOf(address(this));
        if(_srcBal < _amount || _amount == 0){
            _amount = _srcBal;
        }
        
        ERC20(_src).safeApprove(PARASWAP_TOKEN_PROXY, 0);
        ERC20(_src).safeApprove(PARASWAP_TOKEN_PROXY, _amount);

        IParaswapAugustus.SellData memory swapData = IParaswapAugustus.SellData({
            fromToken: _src,
            fromAmount: _amount,
            toAmount: _toAmount,
            expectedAmount: _expectedAmount,
            beneficiary: payable(address(this)),
            referrer: "BOTOCEAN",
            useReduxToken: false,
            path: _path
        });

        IParaswapAugustus(PARASWAP_AUGUSTUS).multiSwap(swapData);
    }

    function uniswapSwap(uint256 _amount, uint256 _toMinAmount, address[] memory _path) public onlyOwner {
        address _src = _path[0];
        uint256 _srcBal = ERC20(_src).balanceOf(address(this));
        if(_srcBal < _amount || _amount == 0){
            _amount = _srcBal;
        }

        ERC20(_src).safeApprove(UNISWAP_ROUTER, _amount);
        uint256 expTime = uint256(block.timestamp).add(uint256(1 days));

        IUniswapV2Router02(UNISWAP_ROUTER).swapExactTokensForTokens(
            _amount,
            _toMinAmount,
            _path,
            address(this),
            expTime
        );
    }

    function burnBOTS() external onlyOwner {
        uint256 _botsBal = ERC20(BOTS).balanceOf(address(this));
        address botsOwner = ERC20(BOTS).owner();
        ILockedOwner(botsOwner).burnTokens(_botsBal);
    }

    // Only used if burnBOTS fails
    function manualBurnBOTS() external onlyOwner {
        uint256 _botsBal = ERC20(BOTS).balanceOf(address(this));
        ERC20(BOTS).safeTransfer(address(0x0000000000000000000000000000000000000001), _botsBal);
    }

    function getRegisteredFundsLength() external view returns (uint) {
        return deployedFunds.length;
    }

    function getIsDeployedFund(address _fund) external view returns (bool) {
        return isDeployedFund[_fund];
    }
}