// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./CompoundXYCore.sol";
import "./ICompound.sol";
import "./IUniswapV3Oracle.sol";
import "./IToken.sol";

/// @title This strategy will deposit collateral token in Compound and based on position it will borrow
/// another token. Supply X borrow Y and keep borrowed amount here. It does handle rewards and handle
/// wrap/unwrap of WETH as ETH is required to interact with Compound.
contract CompoundXYStrategy is CompoundXYCore {
    using SafeERC20 for IERC20;

    address public immutable rewardToken;
    address private constant CETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    constructor(
        address _pool,
        address _swapManager,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        address _borrowCToken,
        string memory _name
    ) CompoundXYCore(_pool, _swapManager, _comptroller, _receiptToken, _borrowCToken, _name) {
        require(_rewardToken != address(0), "rewardToken-address-is-zero");
        rewardToken = _rewardToken;
    }

    //solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return super.isReservedToken(_token) || _token == rewardToken;
    }

    /**
     * @notice Calculate total value using rewardToken accrued, supply and borrow position
     * @dev Compound calculate rewardToken accrued and store it when user interact with
     * Compound contracts, i.e. deposit, withdraw or transfer tokens.
     * So compAccrued() will return stored rewardToken accrued amount, which may be inaccurate.
     */
    function totalValue() public view virtual override returns (uint256 _totalValue) {
        _totalValue = super.totalValue();
        uint256 _rewardAccrued = comptroller.compAccrued(address(this));
        if (_rewardAccrued > 0) {
            (, uint256 _rewardAsCollateral, ) =
                swapManager.bestOutputFixedInput(rewardToken, address(collateralToken), _rewardAccrued);
            // Update totalValue
            _totalValue += _rewardAsCollateral;
        }
    }

    function _approveRouter(address _router, uint256 _amount) internal virtual override {
        IERC20(rewardToken).safeApprove(_router, _amount);
    }

    /// @dev If borrowToken WETH then wrap borrowed ETH to get WETH
    function _borrowY(uint256 _amount) internal override {
        if (_amount > 0) {
            require(borrowCToken.borrow(_amount) == 0, "borrow-from-compound-failed");
            if (borrowToken == WETH) {
                TokenLike(WETH).deposit{value: address(this).balance}();
            }
            _afterBorrowY(_amount);
        }
    }

    /// @notice Claim rewardToken and convert rewardToken into collateral token.
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        address[] memory _markets = new address[](2);
        _markets[0] = address(supplyCToken);
        _markets[1] = address(borrowCToken);
        comptroller.claimComp(address(this), _markets);
        uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardAmount > 0) {
            _safeSwap(rewardToken, _toToken, _rewardAmount, 1);
        }
    }

    /// @dev Native Compound cETH doesn't has underlying method
    function _getUnderlyingToken(address _cToken) internal view virtual override returns (address) {
        if (_cToken == CETH) {
            return WETH;
        }
        return CToken(_cToken).underlying();
    }

    /// @dev If borrowToken is WETH then unwrap WETH to get ETH and repay borrow using ETH.
    function _repayY(uint256 _amount) internal override {
        _beforeRepayY(_amount);
        if (borrowToken == WETH) {
            TokenLike(WETH).withdraw(_amount);
            borrowCToken.repayBorrow{value: _amount}();
        } else {
            require(borrowCToken.repayBorrow(_amount) == 0, "repay-to-compound-failed");
        }
    }
}
