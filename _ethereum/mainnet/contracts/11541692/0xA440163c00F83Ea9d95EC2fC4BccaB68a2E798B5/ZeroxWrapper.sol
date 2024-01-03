pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./DSMath.sol";
import "./AdminAuth.sol";
import "./DFSExchangeHelper.sol";
import "./OffchainWrapperInterface.sol";
import "./TokenInterface.sol";

contract ZeroxWrapper is OffchainWrapperInterface, DFSExchangeHelper, AdminAuth, DSMath {
    string public constant ERR_SRC_AMOUNT = "Not enough funds";
    string public constant ERR_PROTOCOL_FEE = "Not enough eth for protcol fee";

    using SafeERC20 for ERC20;

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _type Action type (buy or sell)
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) override public payable returns (bool success, uint256) {
        // check that contract have enough balance for exchange and protocol fee
        require(getBalance(_exData.srcAddr) >= _exData.srcAmount, ERR_SRC_AMOUNT);
        require(getBalance(KYBER_ETH_ADDRESS) >= _exData.offchainData.protocolFee, ERR_PROTOCOL_FEE);
        
        /// @dev 0x always uses max approve in v1, so we approve the exact amount we want to sell
        /// @dev safeApprove is modified to always first set approval to 0, then to exact amount
        if (_type == ActionType.SELL) {
            ERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, _exData.srcAmount);
        } else {
            ERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, wdiv(_exData.destAmount, _exData.offchainData.price));
        }
        // we know that it will be eth if dest addr is either weth or eth
        address destAddr = _exData.destAddr == EXCHANGE_WETH_ADDRESS ? KYBER_ETH_ADDRESS : _exData.destAddr;

        uint256 tokensBefore = getBalance(destAddr);
        (success, ) = _exData.offchainData.exchangeAddr.call{value: _exData.offchainData.protocolFee}(_exData.offchainData.callData);
        uint256 tokensSwaped = 0;

        // convert weth to eth before sending back
        if (getBalance(EXCHANGE_WETH_ADDRESS) > 0) {
            TokenInterface(EXCHANGE_WETH_ADDRESS).withdraw(
                TokenInterface(EXCHANGE_WETH_ADDRESS).balanceOf(address(this))
            );
        }

        if (success) {
            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(destAddr) - tokensBefore;
        }

        // returns all funds from src addr, dest addr and eth funds (protocol fee leftovers)
        sendLeftover(_exData.srcAddr, _exData.destAddr, msg.sender);

        return (success, tokensSwaped);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}