// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

import "./IHandler.sol";
import "./IModule.sol";
import "./Address.sol";
import "./TokenUtils.sol";
import "./IERC20.sol";
import "./Tokens.sol";
import "./Proxied.sol";

library SafeERC20 {
    function transfer(
        IERC20 _token,
        address _to,
        uint256 _val
    ) internal returns (bool) {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(_token.transfer.selector, _to, _val)
        );
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }
}

// File: contracts/commons/Order.sol

contract StopLimitOrders is
    IModule,
    Initializable,
    ReentrancyGuardUpgradeable,
    Proxied
{
    uint256 public slippageBps;

    /// @notice receive ETH
    receive() external payable override {
        revert();
    }

    function initialize() external initializer {
        __ReentrancyGuard_init();
        slippageBps = 500;
    }

    /**
     * @notice Executes an order
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return protectedFunds - amount of output tokens saved
     */

    function execute(
        IERC20 _inputToken,
        uint256,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _auxData
    ) external override nonReentrant returns (uint256 protectedFunds) {
        (
            IERC20 outputToken,
            uint256 _minReturn,
            ,
            /* handler */
            uint256 _maxReturn
        ) = abi.decode(_data, (IERC20, uint256, address, uint256));

        IHandler handler = abi.decode(_auxData, (IHandler));

        // Do not trust on _inputToken, it can mismatch the real balance
        uint256 inputAmount = TokenUtils.balanceOf(
            address(_inputToken),
            address(this)
        );
        // Handler gets Input Tokens
        _transferAmount(_inputToken, payable(address(handler)), inputAmount);

        handler.handle(
            _inputToken,
            outputToken,
            inputAmount,
            _minReturn,
            _auxData
        );

        protectedFunds = TokenUtils.balanceOf(
            address(outputToken),
            address(this)
        );
        require(
            protectedFunds <= _getSlippageAdjustedMaxReturn(_maxReturn),
            "StopLimitOrders#execute: STOPLIMIT_THRESHOLD_NOT_REACHED"
        );
        require(
            protectedFunds >= _minReturn,
            "StopLimitOrders#execute: OUTSIDE_MIN_RETURN"
        );

        _transferAmount(outputToken, _owner, protectedFunds);

        return protectedFunds;
    }

    function setSlippageBps(uint256 _slippageBps) external onlyProxyAdmin {
        slippageBps = _slippageBps;
    }

    /**
     * @notice Check whether an order can be executed or not
     * @param _inputToken - Address of the input token
     * @param _inputAmount - uint256 of the input token amount (order amount)
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bool - whether the order can be executed or not
     */
    function canExecute(
        IERC20 _inputToken,
        uint256 _inputAmount,
        bytes calldata _data,
        bytes calldata _auxData
    ) external view override returns (bool) {
        (
            IERC20 outputToken,
            uint256 _minReturn,
            ,
            /* handler */
            uint256 _maxReturn
        ) = abi.decode(_data, (IERC20, uint256, address, uint256));

        IHandler handler = abi.decode(_auxData, (IHandler));

        bytes memory encodedData = abi.encode(_auxData, _maxReturn);
        return
            handler.canHandle(
                _inputToken,
                outputToken,
                _inputAmount,
                _minReturn,
                encodedData
            );
    }

    /**
     * @notice Transfer token or Ether amount to a recipient
     * @param _token - Address of the token
     * @param _to - Address of the recipient
     * @param _amount - uint256 of the amount to be transferred
     */
    function _transferAmount(
        IERC20 _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == NATIVE) {
            (bool success, ) = _to.call{value: _amount}("");
            require(
                success,
                "StopLimitOrders#_transferAmount: ETH_TRANSFER_FAILED"
            );
        } else {
            require(
                SafeERC20.transfer(_token, _to, _amount),
                "StopLimitOrders#_transferAmount: TOKEN_TRANSFER_FAILED"
            );
        }
    }

    function _getSlippageAdjustedMaxReturn(uint256 _maxReturn)
        internal
        view
        returns (uint256 slippageAdjustedMaxReturn)
    {
        slippageAdjustedMaxReturn =
            _maxReturn +
            ((_maxReturn * slippageBps) / 10000);
    }
}
