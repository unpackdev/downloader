// SPDX-License-Identifier: UNLICENSED

/**
 * Proxy Router Manager Contract.
 * Designed by Wallchain in Metaverse.
*/

pragma solidity >=0.8.6;

import "./IUniswapV2Router02.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./IWChainMaster.sol";

contract ApeRouterManager is Ownable {
    event EventMessage(string message);
    uint256 constant UINT256_MAX = type(uint256).max;

    mapping(address => bool) public routers;
    IWChainMaster public wchainMaster;
    address public dexAgent;
    address public immutable WETH;
    uint256 public exchangeProfitShare = 50; // 40%

    constructor(
        address[] memory _routers,
        address _dexAgent,
        IWChainMaster _wchainMaster
    ) {
        dexAgent = _dexAgent;
        wchainMaster = _wchainMaster;
        WETH = IUniswapV2Router02(_routers[0]).WETH();

        for (uint256 i = 0; i < _routers.length; i++) {
            routers[_routers[i]] = true;
        }
    }

    receive() external payable {}

    modifier coverUp(bytes calldata masterInput) {
        _;
        // masterInput should be empty if txn is not profitable
        if (masterInput.length > 8) {
            try
                wchainMaster.execute(
                    masterInput,
                    msg.sender,
                    dexAgent,
                    exchangeProfitShare
                )
            {} catch {
                emit EventMessage("Profit Capturing Error");
            }
        } else {
            emit EventMessage("Non Profit Txn");
        }
    }

    function setShare(uint256 _exchangeProfitShare) external onlyOwner {
        require(_exchangeProfitShare <= 80, "New share is too high");

        exchangeProfitShare = _exchangeProfitShare;
        emit EventMessage("New Share Was Set");
    }

    function setDexAgent(address _dexAgent) external onlyOwner {
        dexAgent = _dexAgent;
        emit EventMessage("New Dex Agent Was Set");
    }

    function addBackupRouter(address _router)
        external
        onlyOwner
    {
        routers[_router] = true;
        emit EventMessage("New Backup Router Was Added");
    }

    function removeBackupRouter(address _router)
        external
        onlyOwner
    {
        routers[_router] = false;
        emit EventMessage("Backup Router Was Removed");
    }

    function upgradeMaster() external onlyOwner {
        if (address(wchainMaster) != wchainMaster.nextAddress()) {
            wchainMaster = IWChainMaster(wchainMaster.nextAddress());
            emit EventMessage("New WChainMaster Was Set");
            return;
        }
        emit EventMessage("WChainMaster Is Already Up To Date");
    }

    function maybeApproveERC20(
        IERC20 token,
        uint256 amount,
        IUniswapV2Router02 router
    ) private {
        // approve router to fetch the funds for swapping
        if (token.allowance(address(this), address(router)) < amount) {
            token.approve(address(router), UINT256_MAX);
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountIn
        );
        maybeApproveERC20(IERC20(path[0]), amountIn, router);
        return
            router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        amounts = router.getAmountsIn(amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amounts[0]
        );
        maybeApproveERC20(IERC20(path[0]), amounts[0], router);
        router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external payable coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        amounts = router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = router.getAmountsIn(amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amounts[0]
        );
        maybeApproveERC20(IERC20(path[0]), amounts[0], router);
        router.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountIn
        );
        maybeApproveERC20(IERC20(path[0]), amountIn, router);
        return
            router.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external payable coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        amounts = router.swapETHForExactTokens{value: msg.value}(
            amountOut,
            path,
            to,
            deadline
        );
        // refund dust eth, if any
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }
}
