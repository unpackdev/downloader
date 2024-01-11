//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";

contract Router is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address zeroXExchangeProxy;

    function initialize(address initZeroXExchangeProxy) public initializer {
        __Ownable_init();

        zeroXExchangeProxy = initZeroXExchangeProxy;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    function fromERC20ToERC20(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address toReceiver,
        bytes calldata swapCallData
    ) external payable {
        receiveAndApproveToken(fromToken, fromAmount, zeroXExchangeProxy);

        (bool swapSuccess, ) = zeroXExchangeProxy.call{value: msg.value}(
            swapCallData
        );
        require(swapSuccess, "Swap failed");

        require(
            toToken.transfer(toReceiver, toAmount),
            "Token could not be transferred to receiver"
        );

        refundToken(fromToken);
        refundToken(toToken);
    }

    function fromETHToERC20(
        IERC20Upgradeable toToken,
        uint256 toAmount,
        address toReceiver,
        bytes calldata swapCallData
    ) external payable {
        (bool swapSuccess, ) = zeroXExchangeProxy.call{value: msg.value}(
            swapCallData
        );
        require(swapSuccess, "Swap failed");

        require(
            toToken.transfer(toReceiver, toAmount),
            "Token could not be transferred to receiver"
        );

        refundToken(toToken);
        refundETH();
    }

    function fromERC20ToETH(
        IERC20Upgradeable fromToken,
        uint256 fromAmount,
        uint256 toAmount,
        address toReceiver,
        bytes calldata swapCallData
    ) external payable {
        receiveAndApproveToken(fromToken, fromAmount, zeroXExchangeProxy);

        (bool swapSuccess, ) = zeroXExchangeProxy.call{value: msg.value}(
            swapCallData
        );
        require(swapSuccess, "Swap failed");

        (bool transferSuccess, ) = toReceiver.call{value: toAmount}("");
        require(transferSuccess, "ETH could not be transferred to receiver");

        refundToken(fromToken);
        refundETH();
    }

    function receiveAndApproveToken(
        IERC20Upgradeable token,
        uint256 amount,
        address spender
    ) internal {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token could not be transferred from sender"
        );
        require(
            token.approve(spender, amount),
            "Token could not be approved for spender"
        );
    }

    function refundToken(IERC20Upgradeable token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            require(
                token.transfer(msg.sender, balance),
                "Token could not be refunded to sender"
            );
        }
    }

    function refundETH() internal {
        if (address(this).balance > 0) {
            (bool success, ) = msg.sender.call{value: address(this).balance}(
                ""
            );
            require(success, "ETH could not be refunded to sender");
        }
    }

    function setZeroXExchangeProxy(address newZeroXExchangeProxy)
        external
        onlyOwner
    {
        zeroXExchangeProxy = newZeroXExchangeProxy;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
