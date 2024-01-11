// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./ISwitchView.sol";
import "./ISwitchEvent.sol";
import "./SwitchRootEth.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract SwitchEth is SwitchRootEth {
    using UniswapExchangeLib for IUniswapExchange;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    ISwitchView public switchView;
    ISwitchEvent public switchEvent;
    address public reward;
    address public owner;

    constructor(address _switchViewAddress, address _switchEventAddress) public {
        switchView = ISwitchView(_switchViewAddress);
        switchEvent = ISwitchEvent(_switchEventAddress);
        reward = msg.sender;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    fallback() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
    public
    override
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    )
    {
        (returnAmount, distribution) = switchView.getExpectedReturn(fromToken, destToken, amount, parts);
    }

    function setReward(address newReward) external onlyOwner {
        reward = newReward;
    }

    function setSwitchEvent(ISwitchEvent newSwitchEvent) external onlyOwner {
        switchEvent = newSwitchEvent;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 expectedReturn,
        uint256 minReturn,
        address recipient,
        uint256[] memory distribution
    ) public payable returns(uint256 returnAmount) {
        require(expectedReturn >= minReturn, "expectedReturn must be equal or larger than minReturn");
        if (fromToken == destToken) {
            return amount;
        }

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts += distribution[i];
                lastNonZeroIndex = i;
            }
        }

        if (parts == 0) {
            if (fromToken.isETH()) {
                payable(msg.sender).transfer(msg.value);
                return msg.value;
            }
            return amount;
        }

        fromToken.universalTransferFrom(msg.sender, address(this), amount);

        // break function to avoid stack too deep error
        _swapInternal(distribution, amount, parts, lastNonZeroIndex, fromToken, destToken);

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "Switch: Return amount was not enough");
        if (returnAmount > expectedReturn) {
            destToken.universalTransfer(recipient, expectedReturn);
            destToken.universalTransfer(reward, returnAmount - expectedReturn);
            returnAmount = expectedReturn;
            switchEvent.emitSwapped(msg.sender, recipient, fromToken, destToken, amount, expectedReturn, returnAmount - expectedReturn);
        } else {
            destToken.universalTransfer(recipient, returnAmount);
            switchEvent.emitSwapped(msg.sender, recipient, fromToken, destToken, amount, returnAmount, 0);
        }

        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    function _swapInternal(
        uint256[] memory distribution,
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        IERC20 fromToken,
        IERC20 destToken
    ) internal {

        require(distribution.length <= DEXES_COUNT*PATHS_COUNT, "Switch: Distribution array should not exceed factories array size");

        uint256 remainingAmount = fromToken.universalBalanceOf(address(this));
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount * distribution[i] / parts;
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            if (i % PATHS_COUNT == 0) {
                _swap(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/PATHS_COUNT]));
            } else {
                _swapETH(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/PATHS_COUNT]));
            }
        }
    }

    // Swap helpers
    function _swapInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal returns(uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit{value: amount}();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        }
        else if (needSkim) {
            exchange.skim(0xBdB82D89731De719CAe1171C1Fa999E8c13ce77A);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint160(address(fromTokenReal)) < uint160(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal {
        _swapInternal(
            midToken,
            destToken,
            _swapInternal(
                fromToken,
                midToken,
                amount,
                factory
            ),
            factory
        );
    }

    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal {
        _swapInternal(
            fromToken,
            destToken,
            amount,
            factory
        );
    }

    function _swapETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal {
        _swapOverMid(
            fromToken,
            weth,
            destToken,
            amount,
            factory
        );
    }
}
