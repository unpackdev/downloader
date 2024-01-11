// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./TickMath.sol";
import "./ISwapRouter.sol";

/// @title Swap

contract Swap {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public owner;
    address public recipient;

    ISwapRouter public router;

    event Swap(address token, address recipient, uint256 amountOut);

    constructor(
        address _owner,
        address _router
    ) {
        require(_owner != address(0), "_owner should be non-zero");
        require(_router != address(0), "_router should be non-zero");
        owner = _owner;
        recipient = _owner;
        router = ISwapRouter(_router);
    }

    /// @notice Swap given token via ISwapRouter
    /// @param token Address of token to twap
    /// @param path Path info for router
    /// @param send Boolean variable for sending to recipient or contract
    function swap(
        address token,
        bytes memory path,
        bool send
    ) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (IERC20(token).allowance(address(this), address(router)) < balance) IERC20(token).approve(address(router), balance);
        uint256 amountOut = router.exactInput(
            ISwapRouter.ExactInputParams(
                path,
                send ? recipient : address(this),
                block.timestamp + 10000,
                balance,
                0
            )
        );
        emit Swap(token, send ? recipient : address(this), amountOut);
    }

    /// @param _recipient Address of the recipient
    function changeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "_recipient should be non-zero");
        recipient = _recipient;
    }

    /// @param token Address of token to send
    /// @param amount Amount of tokens to send
    function sendToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "newOwner should be non-zero");
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}
