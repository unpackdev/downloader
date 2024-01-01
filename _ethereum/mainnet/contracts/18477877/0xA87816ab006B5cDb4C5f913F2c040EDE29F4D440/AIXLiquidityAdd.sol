// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessControlEnumerable.sol";
import "./IUniswapV2Router02.sol";

contract AIXLiquidityAdd is AccessControlEnumerable {
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant RECEIVER_ROLE = keccak256("RECEIVER_ROLE");

    IUniswapV2Router02 public uniswapRouter;
    IERC20 public AIX;

    constructor(
        address _AIX,
        address _uniswapRouter
    ) {
        AIX = IERC20(_AIX);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        AIX.approve(address(uniswapRouter), type(uint256).max);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTROLLER_ROLE, msg.sender);
        _setupRole(RECEIVER_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    modifier onlyControllerOrAdmin() {
        require(hasRole(CONTROLLER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a controller or admin");
        _;
    }

    function setApproval(uint256 amount) external onlyAdmin {
        AIX.approve(address(uniswapRouter), amount);
    }

    function addLiquidity(
        uint256 amountAIX,
        uint256 amountETH,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    ) external onlyControllerOrAdmin {
        require(hasRole(RECEIVER_ROLE, to), "Receiver is not authorized");
        if (amountAIX == 0) {
            amountAIX = AIX.balanceOf(address(this));
        }
        if (amountETH == 0) {
            amountETH = address(this).balance;
        }
        uniswapRouter.addLiquidityETH{value: amountETH}({
            token: address(AIX),
            amountTokenDesired: amountAIX,
            amountTokenMin: amountTokenMin,
            amountETHMin: amountETHMin,
            to: to,
            deadline: block.timestamp
        });
    }

    function takeTokens(IERC20 token) external onlyAdmin {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Insufficient token balance");
        token.transfer(msg.sender, balance);
    }

    receive() external payable {}

    function withdrawETH() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }
}
