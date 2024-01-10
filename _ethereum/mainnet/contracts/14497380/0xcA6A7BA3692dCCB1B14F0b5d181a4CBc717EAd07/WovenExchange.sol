//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./LibBytes.sol";
import "./IERC20.sol";
import "./IHopL1Bridge.sol";
import "./IHopL2AmmWrapper.sol";
import "./IAnySwapBridge.sol";

contract WovenExchange is Initializable, OwnableUpgradeable {
    using LibBytes for bytes;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MAX_INT_HEX =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    struct CurrencyAmount {
        address target;
        uint256 amount;
    }

    mapping(address => bool) public exchanges;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setExchange(address exchange, bool enabled) external onlyOwner {
        exchanges[exchange] = enabled;
    }

    function swapAndSendToBridge(
        bytes calldata swapData,
        bytes calldata sendToBridgeData
    ) public payable {
        address self = address(this);
        // prettier-ignore
        require(
            this.swap.selector == swapData.readBytes4(0) &&
            (
                this.hopSendL1ToL2.selector == sendToBridgeData.readBytes4(0) ||
                this.hopSendL2ToOther.selector == sendToBridgeData.readBytes4(0) ||
                this.anySwap.selector == sendToBridgeData.readBytes4(0)
            ),
            "calldata error"
        );

        {
            (bool success, bytes memory ret) = self.delegatecall(swapData);
            require(success, string(ret));
        }
        {
            (bool success, bytes memory ret) = self.call{value: self.balance}(
                sendToBridgeData
            );
            require(success, string(ret));
        }
    }

    function swap(
        CurrencyAmount calldata input,
        CurrencyAmount calldata output,
        address recipient,
        address allowanceTarget,
        address exchange,
        bytes calldata callData
    ) public payable {
        require(exchanges[exchange], "Woven: exchange not allowed");
        address sender = msg.sender;
        address self = address(this);

        if (input.target != ETH) {
            if (sender != self) {
                IERC20(input.target).transferFrom(sender, self, input.amount);
            }
            IERC20(input.target).approve(allowanceTarget, input.amount);
        }

        (bool success, bytes memory ret) = exchange.call{value: self.balance}(
            callData
        );
        require(success, string(ret));

        if (recipient != self && output.amount > 0) {
            if (self.balance > 0) {
                payable(recipient).transfer(self.balance);
            }
            if (output.target != ETH) {
                uint256 balance = IERC20(output.target).balanceOf(self);
                IERC20(output.target).transfer(recipient, balance);
            }
        }
    }

    function getAmount(CurrencyAmount calldata currency)
        private
        view
        returns (uint256)
    {
        uint256 amount = currency.amount;

        if (currency.target != ETH) {
            if (amount == MAX_INT_HEX) {
                amount = IERC20(currency.target).balanceOf(msg.sender);
            }
        } else {
            if (amount == MAX_INT_HEX) {
                amount = address(this).balance;
            }
        }

        return amount;
    }

    function hopSendL1ToL2(
        address bridge,
        CurrencyAmount calldata currency,
        uint256 destinationChainId,
        address recipient,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) public payable {
        address sender = msg.sender;
        address self = address(this);
        uint256 amount = getAmount(currency);

        if (currency.target != ETH) {
            if (sender != self) {
                IERC20(currency.target).transferFrom(sender, self, amount);
            }
            IERC20(currency.target).approve(bridge, amount);
        }

        IHopL1Bridge(bridge).sendToL2{value: self.balance}(
            destinationChainId,
            recipient,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );
    }

    function hopSendL2ToOther(
        address ammWrapper,
        CurrencyAmount calldata currency,
        uint256 destinationChainId,
        address recipient,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) public payable {
        address sender = msg.sender;
        address self = address(this);
        uint256 amount = getAmount(currency);

        if (currency.target != ETH) {
            if (sender != self) {
                IERC20(currency.target).transferFrom(sender, self, amount);
            }
            IERC20(currency.target).approve(ammWrapper, amount);
        }

        IHopL2AmmWrapper(ammWrapper).swapAndSend{value: self.balance}(
            destinationChainId,
            recipient,
            amount,
            bonderFee,
            amountOutMin,
            deadline,
            destinationAmountOutMin,
            destinationDeadline
        );
    }

    function anySwap(
        address bridge,
        CurrencyAmount calldata currency,
        address inputToken,
        uint256 destinationChainId,
        address recipient
    ) public payable {
        address sender = msg.sender;
        address self = address(this);
        uint256 amount = getAmount(currency);

        if (currency.target != ETH) {
            if (sender != self) {
                IERC20(currency.target).transferFrom(sender, self, amount);
            }
            IERC20(currency.target).approve(bridge, amount);
        }

        if (currency.target == ETH) {
            IAnySwapBridge(bridge).anySwapOutNative{value: self.balance}(
                inputToken,
                recipient,
                destinationChainId
            );
        } else {
            if (inputToken == currency.target) {
                IAnySwapBridge(bridge).anySwapOut(
                    inputToken,
                    recipient,
                    amount,
                    destinationChainId
                );
            } else {
                IAnySwapBridge(bridge).anySwapOutUnderlying(
                    inputToken,
                    recipient,
                    amount,
                    destinationChainId
                );
            }
        }
    }

    // solhint-disable no-empty-blocks

    receive() external payable virtual {}

    // solhint-enable no-empty-blocks
}
