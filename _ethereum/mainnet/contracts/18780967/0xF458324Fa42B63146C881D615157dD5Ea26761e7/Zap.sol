// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Babylonian.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IAddressProvider.sol";

contract Zap is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @notice Uniswap Router
    IUniswapV2Router02 public router;

    /// @notice Uniswap fee
    uint256 public uniswapFee;

    /* ======== ERRORS ======== */

    error INVALID_ADDRESS();
    error INVALID_AMOUNT();

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _addressProvider,
        address _router
    ) external initializer {
        if (_addressProvider == address(0) || _router == address(0))
            revert INVALID_ADDRESS();

        // address provider
        addressProvider = IAddressProvider(_addressProvider);

        // uniswap router
        router = IUniswapV2Router02(_router);

        IERC20(addressProvider.getShezmu()).approve(_router, type(uint256).max);
        uniswapFee = 3; // 0.3% (1000 = 100%)

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    receive() external payable {}

    /* ======== VIEW FUNCTIONS ======== */

    function lpToken() public view returns (address) {
        return
            IUniswapV2Factory(router.factory()).getPair(
                addressProvider.getShezmu(),
                router.WETH()
            );
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     * @notice set address provider
     * @param _addressProvider address
     */
    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();
        addressProvider = IAddressProvider(_addressProvider);
    }

    function setUniswapFee(uint256 fee) external onlyOwner {
        uniswapFee = fee;
    }

    /**
     * @notice recover tokens
     */
    function recoverERC20(IERC20 _token) external onlyOwner {
        uint256 amount = _token.balanceOf(address(this));

        if (amount > 0) {
            _token.safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @notice recover ETH
     */
    function recoverETH() external onlyOwner {
        uint256 amount = address(this).balance;

        if (amount > 0) {
            payable(msg.sender).call{value: amount}('');
        }
    }

    /**
     * @notice pause
     */
    function pause() external onlyOwner whenNotPaused {
        return _pause();
    }

    /**
     * @notice unpause
     */
    function unpause() external onlyOwner whenPaused {
        return _unpause();
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function addLiquidity(
        uint256 _shezmuAmount
    )
        external
        payable
        nonReentrant
        returns (uint256 amountShezmu, uint256 amountETH, uint256 liquidity)
    {
        if (_shezmuAmount == 0 || msg.value == 0) revert INVALID_AMOUNT();

        IERC20 shezmu = IERC20(addressProvider.getShezmu());
        shezmu.safeTransferFrom(msg.sender, address(this), _shezmuAmount);

        (amountShezmu, amountETH, liquidity) = router.addLiquidityETH{
            value: msg.value
        }(address(shezmu), _shezmuAmount, 0, 0, msg.sender, block.timestamp);

        uint256 remainingShezmu = _shezmuAmount - amountShezmu;
        if (remainingShezmu > 0) {
            shezmu.safeTransfer(msg.sender, remainingShezmu);
        }

        uint256 remainingETH = msg.value - amountETH;
        if (remainingETH > 0) {
            payable(msg.sender).call{value: remainingETH}('');
        }
    }

    function removeLiquidity(
        uint256 _liquidity
    ) external nonReentrant returns (uint256 amountShezmu, uint256 amountETH) {
        if (_liquidity == 0) revert INVALID_AMOUNT();

        IERC20 token = IERC20(lpToken());
        token.safeTransferFrom(msg.sender, address(this), _liquidity);
        token.approve(address(router), _liquidity);

        (amountShezmu, amountETH) = router.removeLiquidityETH(
            addressProvider.getShezmu(),
            _liquidity,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }

    function zapInToken(
        uint256 _shezmuAmount
    )
        external
        nonReentrant
        returns (uint256 amountShezmu, uint256 amountETH, uint256 liquidity)
    {
        if (_shezmuAmount == 0) revert INVALID_AMOUNT();

        address shezmu = addressProvider.getShezmu();
        IERC20(shezmu).safeTransferFrom(
            msg.sender,
            address(this),
            _shezmuAmount
        );

        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(router.factory()).getPair(shezmu, router.WETH())
        );

        (uint256 rsv0, uint256 rsv1, ) = pair.getReserves();
        uint256 sellAmount = _calculateSwapInAmount(
            pair.token0() == shezmu ? rsv0 : rsv1,
            _shezmuAmount
        );

        address[] memory path = new address[](2);
        path[0] = shezmu;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            sellAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        (amountShezmu, amountETH, liquidity) = router.addLiquidityETH{
            value: address(this).balance
        }(
            shezmu,
            _shezmuAmount - sellAmount,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uint256 remainingShezmu = _shezmuAmount - amountShezmu - sellAmount;
        if (remainingShezmu > 0) {
            IERC20(shezmu).safeTransfer(msg.sender, remainingShezmu);
        }
    }

    function zapInETH()
        external
        payable
        nonReentrant
        returns (uint256 amountShezmu, uint256 amountETH, uint256 liquidity)
    {
        if (msg.value == 0) revert INVALID_AMOUNT();

        address shezmu = addressProvider.getShezmu();

        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(router.factory()).getPair(shezmu, router.WETH())
        );

        (uint256 rsv0, uint256 rsv1, ) = pair.getReserves();
        uint256 sellAmount = _calculateSwapInAmount(
            pair.token0() == shezmu ? rsv1 : rsv0,
            msg.value
        );

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = shezmu;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: sellAmount
        }(0, path, address(this), block.timestamp);

        (amountShezmu, amountETH, liquidity) = router.addLiquidityETH{
            value: msg.value - sellAmount
        }(
            shezmu,
            IERC20(shezmu).balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uint256 remainingETH = msg.value - amountETH - sellAmount;
        if (remainingETH > 0) {
            payable(msg.sender).call{value: remainingETH}('');
        }
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _calculateSwapInAmount(
        uint256 reserveIn,
        uint256 userIn
    ) internal view returns (uint256) {
        return
            (Babylonian.sqrt(
                reserveIn *
                    ((userIn * (uint256(4000) - (4 * uniswapFee)) * 1000) +
                        (reserveIn *
                            ((uint256(4000) - (4 * uniswapFee)) *
                                1000 +
                                uniswapFee *
                                uniswapFee)))
            ) - (reserveIn * (2000 - uniswapFee))) / (2000 - 2 * uniswapFee);
    }
}
