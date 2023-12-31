// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IERC20MintableBurnable.sol";
import "./IERC20Pausable.sol";
import "./IUniswapV2Router02.sol";

error ACTIVATED();
error INVALID_AMOUNT();
error INVALID_ETHER();
error INVALID_LENGTH();

contract Activate is Ownable {
    using SafeERC20 for IERC20;

    /// @notice ADMIN
    address public constant ADMIN = 0xA004e4ceDea8497d6f028463e6756a5e6296bAd3;

    /// @notice SHEZMU
    IERC20 public constant SHEZMU =
        IERC20(0x5fE72ed557d8a02FFf49B3B826792c765d5cE162);

    /// @notice UniswapRouter
    IUniswapV2Router02 public constant ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /// @notice Shezmu amount of Liquidity
    uint256 public shezmuForLiquidity = 16000 ether;

    /// @notice Eth amount of Liquidity
    uint256 public ethForLiquidity = 10 ether;

    /// @notice Shezmu amount for burning
    uint256 public burnAmount = 60000 ether;

    /// @notice Activated
    bool public isActivated;

    /* ======== INITIALIZATION ======== */

    constructor() {
        _transferOwnership(ADMIN);
    }

    receive() external payable {}

    /* ======== POLICY FUNCTIONS ======== */

    function setLiquidity(uint256 shezmu, uint256 eth) external onlyOwner {
        if (shezmu == 0 || eth == 0) revert INVALID_AMOUNT();

        shezmuForLiquidity = shezmu;
        ethForLiquidity = eth;
    }

    function setBurn(uint256 shezmu) external onlyOwner {
        burnAmount = shezmu;
    }

    function activate(
        address[] calldata tos,
        uint256[] calldata amounts
    ) external payable onlyOwner {
        if (isActivated) revert ACTIVATED();
        isActivated = true;

        if (msg.value != ethForLiquidity) revert INVALID_ETHER();

        address account = _msgSender();

        // Unpause Shezmu
        if (IERC20Pausable(address(SHEZMU)).paused())
            IERC20Pausable(address(SHEZMU)).unpause();

        // Burn Shezmu
        if (burnAmount > 0) {
            IERC20MintableBurnable(address(SHEZMU)).burnFrom(
                account,
                burnAmount
            );
        }

        // Airdrop Shezmu
        uint256 length = tos.length;
        if (length != amounts.length) revert INVALID_LENGTH();

        for (uint256 i = 0; i < length; i++) {
            SHEZMU.safeTransferFrom(account, tos[i], amounts[i]);
            unchecked {
                ++i;
            }
        }

        // Transfer Shezmu
        SHEZMU.safeTransferFrom(account, address(this), shezmuForLiquidity);
        SHEZMU.approve(address(ROUTER), shezmuForLiquidity);

        // Add Liquidity
        ROUTER.addLiquidityETH{value: ethForLiquidity}(
            address(SHEZMU),
            shezmuForLiquidity,
            0,
            0,
            account,
            block.timestamp
        );

        // Renounce Pauser Role
        IERC20Pausable(address(SHEZMU)).renounceRole(
            IERC20Pausable(address(SHEZMU)).PAUSER_ROLE(),
            address(this)
        );
    }
}
