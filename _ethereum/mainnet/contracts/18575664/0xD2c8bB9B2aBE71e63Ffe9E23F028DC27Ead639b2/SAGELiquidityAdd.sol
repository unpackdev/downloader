// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessControlEnumerable.sol";
import "./IUniswapV2Router02.sol";

contract SAGELiquidityAdd is AccessControlEnumerable {
    // 0x7b765e0e932d348852a6f810bfa1ab891e259123f02db8cdcde614c570223357
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    // 0x7a97506be97703960d71e3a118f1850a50b01da6957110e8293eacb08d8c6060
    bytes32 public constant RECEIVER_ROLE = keccak256("RECEIVER_ROLE");

    IUniswapV2Router02 public uniswapRouter;
    IERC20 public SAGE;

    constructor(
        address _SAGE,
        address _uniswapRouter
    ) {
        SAGE = IERC20(_SAGE);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        SAGE.approve(address(uniswapRouter), type(uint256).max);

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
        SAGE.approve(address(uniswapRouter), amount);
    }

    function addLiquidity(
        uint256 amountSAGE,
        uint256 amountETH,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    ) external onlyControllerOrAdmin {
        require(hasRole(RECEIVER_ROLE, to), "Receiver is not authorized");
        if (amountSAGE == 0) {
            amountSAGE = SAGE.balanceOf(address(this));
        }
        if (amountETH == 0) {
            amountETH = address(this).balance;
        }
        uniswapRouter.addLiquidityETH{value: amountETH}({
            token: address(SAGE),
            amountTokenDesired: amountSAGE,
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
