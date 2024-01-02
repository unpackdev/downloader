// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./IERC3156FlashLender.sol";
import "./IPool.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract AaveERC3156Wrapper is IERC3156FlashLender {
    using SafeERC20 for IERC20;

    IPool public immutable pool;

    struct CallbackData {
        IERC3156FlashBorrower receiver;
        address initiator;
        bytes data;
    }

    constructor(IPool _pool) {
        pool = _pool;
    }

    function _getATokenAddress(address token) internal view returns (address) {
        return pool.getReserveData(token).aTokenAddress;
    }

    /// @inheritdoc IERC3156FlashLender
    function maxFlashLoan(address token) external view override returns (uint256) {
        address aToken = _getATokenAddress(token);
        return aToken == address(0) ? 0 : IERC20(token).balanceOf(aToken);
    }

    /// @inheritdoc IERC3156FlashLender
    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        require(_getATokenAddress(token) != address(0), "Token is not supported");
        return (amount * pool.FLASHLOAN_PREMIUM_TOTAL()) / 10000;
    }

    /// @inheritdoc IERC3156FlashLender
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata userData)
        external
        override
        returns (bool)
    {
        bytes memory data = abi.encode(CallbackData({receiver: receiver, initiator: msg.sender, data: userData}));
        pool.flashLoanSimple(address(this), token, amount, data, 0);
        return true;
    }

    /// @dev Aave flash loan callback.
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bool)
    {
        CallbackData memory data = abi.decode(params, (CallbackData));

        require(msg.sender == address(pool), "Only pool can call this function");
        require(initiator == address(this), "Only this contract can initiate flash loan");

        IERC20(asset).safeTransfer(address(data.receiver), amount);
        require(
            data.receiver.onFlashLoan(data.initiator, asset, amount, premium, data.data)
                == keccak256("ERC3156FlashBorrower.onFlashLoan"),
            "IERC3156: Callback failed"
        );
        IERC20(asset).safeTransferFrom(address(data.receiver), address(this), amount + premium);

        IERC20(asset).approve(address(pool), amount + premium);

        return true;
    }
}
