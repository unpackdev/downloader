// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./IModule.sol";
import "./Address.sol";
import "./TokenUtils.sol";
import "./IERC20.sol";
import "./Tokens.sol";
import "./IWETH.sol";

contract LimitOrdersFlashbots is IModule {
    using Address for address payable;
    using TokenUtils for address;

    struct Fees {
        uint256 totalFee;
        uint256 gelatoFee;
    }

    // solhint-disable var-name-mixedcase
    IWETH public immutable WETH;
    address payable public immutable GELATO;
    address payable public immutable MISTX_MANAGER;
    uint256 public mistxFeePct;

    // solhint-enable var-name-mixedcase

    constructor(
        IWETH _weth,
        address payable _gelato,
        address payable _mistxManager,
        uint256 _mistxFeePct
    ) {
        WETH = _weth;
        GELATO = _gelato;
        MISTX_MANAGER = _mistxManager;
        mistxFeePct = _mistxFeePct;
    }

    // solhint-disable-next-line
    receive() external payable override {}

    function setMistxFeePct(uint256 _mistxFeePct) external {
        require(
            msg.sender == MISTX_MANAGER,
            "LimitOrdersFlashbots#setMistxFeePct: only mistX manager"
        );
        require(
            _mistxFeePct < 100,
            "LimitOrdersFlashbots#setMistxFeePct: fee pct too high"
        );
        mistxFeePct = _mistxFeePct;
    }

    /**
     * @notice Executes an order
     * @param _inToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bought - amount of output token bought
     */
    // solhint-disable-next-line function-max-lines, code-complexity
    function execute(
        IERC20 _inToken,
        uint256,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _auxData
    ) external override returns (uint256 bought) {
        (IERC20 _outToken, uint256 _minReturn) = abi.decode(
            _data,
            (IERC20, uint256)
        );

        (
            Fees memory fees,
            address[] memory _swapHandlers,
            bytes[] memory _swapData
        ) = abi.decode(_auxData, (Fees, address[], bytes[]));

        require(
            fees.gelatoFee <= fees.totalFee,
            "LimitOrdersFlashbots#execute: EXCESSIVE_GELATOFEE_AMOUNT"
        );

        require(
            _swapHandlers.length == _swapData.length,
            "LimitOrdersFlashbots#execute: HANDLERS_LENGTH_MISMATCH"
        );

        if (_inToken == WETH || address(_inToken) == ETH) {
            // Deduct ETH fees before swap
            if (_inToken == WETH) {
                if (fees.totalFee > 0) WETH.withdraw(fees.totalFee);
            } else {
                WETH.deposit{value: address(this).balance - fees.totalFee}();
            }

            // SwapData must have inToken amount with fees already deducted off-chain
            bought = _swap(
                _owner,
                _outToken,
                _outToken.balanceOf(_owner),
                _minReturn,
                fees.totalFee,
                _swapHandlers,
                _swapData // needs to have user inputAmount - fees encoded
            );
        } else if (_outToken == WETH || address(_outToken) == ETH) {
            bought = _swap(
                _owner,
                _outToken,
                address(_outToken).balanceOf(_owner),
                _minReturn,
                fees.totalFee,
                _swapHandlers,
                _swapData // needs to have user minReturn + fees encoded
            );
        } else {
            bought = _swap(
                _owner,
                _outToken,
                _outToken.balanceOf(_owner),
                _minReturn,
                fees.totalFee,
                _swapHandlers,
                _swapData // needs to route through path that leaves WETH fees
            );
            if (fees.totalFee > 0) {
                uint256 wethBalance = WETH.balanceOf(address(this));
                if (wethBalance > 0) WETH.withdraw(wethBalance);
            }
        }

        // At this stage if hasFees the fees have been retained or converted to ETH
        if (fees.totalFee > 0) _payFees(fees.gelatoFee);
    }

    /**
     * @notice Check whether an order can be executed or not
     * @dev    Not applicable in this case
     * @return bool - whether the order can be executed or not
     */
    function canExecute(
        IERC20,
        uint256,
        bytes calldata,
        bytes calldata
    ) external view override returns (bool) {
        this; // silence pure warning
        return false;
    }

    // solhint-disable-next-line code-complexity
    function _swap(
        address _owner,
        IERC20 _outToken,
        uint256 _balanceOfOwnerBefore,
        uint256 _minReturn,
        uint256 fees,
        address[] memory _swapHandlers,
        bytes[] memory _swapData
    ) private returns (uint256 bought) {
        for (uint256 i = 0; i < _swapHandlers.length; i++) {
            (bool _swapSuccess, ) = _swapHandlers[i].call(_swapData[i]);
            require(
                _swapSuccess,
                "LimitOrdersFlashbots#_swap: SWAP_MULTICALL_FAILED"
            );
        }

        // Transfer WETH / ETH to owner + keep ETH fees
        if (_outToken == WETH) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            if (wethBalance > fees) WETH.transfer(_owner, wethBalance - fees);
            if (fees > 0) WETH.withdraw(fees);
        } else if (address(_outToken) == ETH) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            if (wethBalance > fees) WETH.withdraw(wethBalance);
            (bool success, ) = _owner.call{value: wethBalance - fees}("");
            require(
                success,
                "LimitOrdersFlashbots#_swap: OWNER_ETH_TRANSFER_FAILED"
            );
        }

        bought = address(_outToken).balanceOf(_owner) - _balanceOfOwnerBefore;

        // Limit Order Condition
        require(
            bought >= _minReturn,
            "LimitOrdersFlashbots#_swap: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function _payFees(uint256 _gelatoFee) private {
        GELATO.sendValue(_gelatoFee);
        // any remaining ETH is sent to miner and mistX
        uint256 balanceETH = address(this).balance;
        if (balanceETH > 0) {
            if (mistxFeePct > 0) MISTX_MANAGER.sendValue((balanceETH * mistxFeePct) / 100);
            // solhint-disable-next-line
            block.coinbase.call{value: address(this).balance}("");
        }
    }
}
