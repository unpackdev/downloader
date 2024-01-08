// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./TickMath.sol";
import "./ISwapRouter.sol";

contract Swap {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public owner;
    address public recipient;
    address public VISR;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    ISwapRouter public router;

    event SwapVISR(address token, address recipient, uint256 amountOut);

    constructor(
        address _owner,
        address _router,
        address _VISR
    ) {
        owner = _owner;
        recipient = _owner;
        VISR = _VISR;
        router = ISwapRouter(_router);
        IERC20(USDT).safeApprove(address(router), uint256(-1)); // USDT approval
    }

    function swap(
        address token,
        bytes memory path,
        bool send
    ) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 allowance = IERC20(token).allowance(address(this), address(router));
        if (token != USDT && allowance < balance) IERC20(token).safeIncreaseAllowance(address(router), balance.sub(allowance));
        uint256 amountOut = router.exactInput(
            ISwapRouter.ExactInputParams(
                path,
                send ? recipient : address(this),
                block.timestamp + 10000,
                balance,
                0
            )
        );
        emit SwapVISR(token, send ? recipient : address(this), amountOut);
    }

    function changeRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function sendToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}
