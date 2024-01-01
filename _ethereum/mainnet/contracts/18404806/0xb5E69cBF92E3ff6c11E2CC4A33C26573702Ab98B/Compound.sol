// SPDX-License-Identifier: MIT
/*
                                           +##*:                                          
                                         .######-                                         
                                        .########-                                        
                                        *#########.                                       
                                       :##########+                                       
                                       *###########.                                      
                                      :############=                                      
                   *###################################################.                  
                   :##################################################=                   
                    .################################################-                    
                     .*#############################################-                     
                       =##########################################*.                      
                        :########################################=                        
                          -####################################=                          
                            -################################+.                           
               =##########################################################*               
               .##########################################################-               
                .*#######################################################:                
                  =####################################################*.                 
                   .*#################################################-                   
                     -##############################################=                     
                       -##########################################=.                      
                         :+####################################*-                         
           *###################################################################:          
           =##################################################################*           
            :################################################################=            
              =############################################################*.             
               .*#########################################################-               
                 :*#####################################################-                 
                   .=################################################+:                   
                      -+##########################################*-.                     
     .+*****************###########################################################*:     
      +############################################################################*.     
       :##########################################################################=       
         -######################################################################+.        
           -##################################################################+.          
             -*#############################################################=             
               :=########################################################+:               
                  :=##################################################+-                  
                     .-+##########################################*=:                     
                         .:=*################################*+-.                         
                              .:-=+*##################*+=-:.                              
                                     .:=*#########+-.                                     
                                         .+####*:                                         
                                           .*#:    */
pragma solidity 0.8.18;

import "./IERC20.sol";

import "./BaseProtocolProxy.sol";
import "./ICEther.sol";
import "./IComet.sol";
import "./ICompound.sol";
import "./ICToken.sol";
import "./IWETH9.sol";

/**
 * @title Compound V2/V3 proxy
 * @author Pino development team
 * @notice Calls Compound V2/V3 functions
 */
contract Compound is ICompound, BaseProtocolProxy {
    IComet public immutable comet;
    ICEther public immutable cEther;

    /**
     * @notice Sets Permit2, WETH9, Compound V3(Comet), and Compound V2's CEther contracts
     * @param _permit2 Address of Permit2 contract
     * @param _weth Address of WETH9 contract
     * @param _comet Address of CompoundV3 (comet) contract
     * @param _cEther Address of Compound V2 CEther
     */
    constructor(address _permit2, address _weth, IComet _comet, ICEther _cEther)
        payable
        BaseProtocolProxy(_permit2, _weth)
    {
        comet = _comet;
        cEther = _cEther;
    }

    /**
     * @notice Deposits ERC20 to the Compound protocol and transfers cTokens to the recipient
     * @param _amount Amount to deposit
     * @param _cToken Address of the cToken to receive
     * @param _recipient The destination address that will receive cTokens
     */
    function depositV2(uint256 _amount, ICToken _cToken, address _recipient) external payable {
        uint256 errorCode = _cToken.mint(_amount);

        if (errorCode != 0) {
            revert CompoundCallFailed(msg.sender, errorCode);
        }

        sweepToken(_cToken, _recipient);

        emit Deposit(msg.sender, _recipient, address(_cToken), _amount);
    }

    /**
     * @notice Deposits ETH to the Compound protocol and transfers CEther to the recipient
     * @param _recipient The destination address that will receive cTokens
     * @param _proxyFeeInWei Fee of the proxy contract
     */
    function depositETHV2(address _recipient, uint256 _proxyFeeInWei) external payable nonETHReuse {
        address _cEther = address(cEther);

        ICEther(_cEther).mint{value: msg.value - _proxyFeeInWei}();

        sweepToken(ICEther(_cEther), _recipient);

        emit Deposit(msg.sender, _recipient, _cEther, msg.value - _proxyFeeInWei);
    }

    /**
     * @notice Deposits WETH, converts it to ETH and mints CEther for the recipient
     * @param _amount The amount of WETH to deposit
     * @param _recipient The destination address that will receive CEther
     */
    function depositWETHV2(uint256 _amount, address _recipient) external payable nonETHReuse {
        address _cEther = address(cEther);

        // CEther works only with ETH, so WETH needs to be unwrapped
        weth.withdraw(_amount);

        ICEther(_cEther).mint{value: _amount}();

        sweepToken(ICEther(_cEther), _recipient);

        emit Deposit(msg.sender, _recipient, _cEther, _amount);
    }

    /**
     * @notice Deposits cTokens back to the Compound protocol
     *   and receives underlying ERC20 tokens and transfers it to the recipient
     * @param _amount Amount to withdraw
     * @param _cToken Address of the cToken
     * @param _recipient The destination that will receive the underlying token
     */
    function withdrawV2(uint256 _amount, ICToken _cToken, address _recipient) external payable {
        uint256 errorCode = _cToken.redeem(_amount);

        if (errorCode != 0) {
            revert CompoundCallFailed(msg.sender, errorCode);
        }

        sweepToken(IERC20(_cToken.underlying()), _recipient);

        emit Withdraw(msg.sender, _recipient, address(_cToken), _amount);
    }

    /**
     * @notice Deposits CEther back the the Compound protocol and receives ETH and transfers it to the recipient
     * @param _amount Amount to withdraw
     * @param _recipient The destination address that will receive ETH
     */
    function withdrawETHV2(uint256 _amount, address _recipient) external payable nonETHReuse {
        address _cEther = address(cEther);
        uint256 balanceBefore = address(this).balance;
        uint256 errorCode = ICEther(_cEther).redeem(_amount);

        if (errorCode != 0) {
            revert CompoundCallFailed(msg.sender, errorCode);
        }

        // Calculate how many ETH contract received after redeem and transfer it to the recipient
        _sendETH(_recipient, address(this).balance - balanceBefore);

        emit Withdraw(msg.sender, _recipient, _cEther, _amount);
    }

    /**
     * @notice Deposits CEther back the the Compound protocol and receives ETH and transfers WETH to the recipient
     * @param _amount Amount to withdraw
     * @param _recipient The destination address that will receive WETH
     */
    function withdrawWETHV2(uint256 _amount, address _recipient) external payable nonETHReuse {
        IWETH9 _weth = weth;
        address _cEther = address(cEther);
        uint256 balanceBefore = address(this).balance;
        uint256 errorCode = ICEther(_cEther).redeem(_amount);

        if (errorCode != 0) {
            revert CompoundCallFailed(msg.sender, errorCode);
        }

        // Calculate how many ETH contract received after redeem and wrap it
        _weth.deposit{value: address(this).balance - balanceBefore}();

        sweepToken(_weth, _recipient);

        emit Withdraw(msg.sender, _recipient, _cEther, _amount);
    }

    /**
     * @notice Repays a borrowed token on behalf of the recipient
     * @param _cToken Address of the cToken
     * @param _amount Amount to repay
     * @param _recipient The address of the recipient
     */
    function repayV2(ICToken _cToken, uint256 _amount, address _recipient) external payable {
        uint256 errorCode = _cToken.repayBorrowBehalf(_recipient, _amount);

        if (errorCode != 0) {
            revert CompoundCallFailed(msg.sender, errorCode);
        }

        emit Repay(msg.sender, _recipient, address(_cToken), _amount);
    }

    /**
     * @notice Repays ETH on behalf of the recipient
     * @param _recipient The address of the recipient
     * @param _proxyFeeInWei Fee of the proxy contract
     */
    function repayETHV2(address _recipient, uint256 _proxyFeeInWei) external payable nonETHReuse {
        address _cEther = address(cEther);

        uint256 errorCode = ICEther(_cEther).repayBorrowBehalf{value: msg.value - _proxyFeeInWei}(_recipient);

        if (errorCode != 0) {
            revert CompoundCallFailed(msg.sender, errorCode);
        }

        emit Repay(msg.sender, _recipient, _cEther, msg.value - _proxyFeeInWei);
    }

    /**
     * @notice Repays ETH on behalf of the recipient but receives WETH from the caller
     * @param _amount The amount of WETH to repay
     * @param _recipient The address of the recipient
     */
    function repayWETHV2(uint256 _amount, address _recipient) external payable nonETHReuse {
        address _cEther = address(cEther);

        // CEther works only with ETH, so WETH needs to be unwrapped
        weth.withdraw(_amount);

        uint256 errorCode = ICEther(_cEther).repayBorrowBehalf{value: _amount}(_recipient);

        if (errorCode != 0) {
            revert CompoundCallFailed(msg.sender, errorCode);
        }

        emit Repay(msg.sender, _recipient, _cEther, _amount);
    }

    /**
     * @notice Deposits ERC20 tokens to the Compound protocol or repays a borrow on behalf of the recipient
     * @param _token The underlying ERC20 token
     * @param _amount Amount to deposit
     * @param _recipient The address of the recipient
     */
    function depositV3(address _token, uint256 _amount, address _recipient) external payable {
        comet.supplyTo(_recipient, _token, _amount);

        emit DepositV3(msg.sender, _recipient, _token, _amount);
    }

    /**
     * @notice Withdraws an ERC20 token or borrows an amount and transfers it to the recipient
     * @param _token The underlying ERC20 token to withdraw
     * @param _amount Amount to withdraw
     * @param _recipient The address of the recipient
     */
    function withdrawV3(address _token, uint256 _amount, address _recipient) external payable {
        comet.withdrawFrom(msg.sender, _recipient, _token, _amount);

        emit WithdrawV3(msg.sender, _recipient, _token, _amount);
    }
}
