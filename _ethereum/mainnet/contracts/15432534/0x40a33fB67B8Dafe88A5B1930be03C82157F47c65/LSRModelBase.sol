// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./LSRMinter.sol";
import "./LSRCalculator.sol";

import "./IStrategy.sol";

/**
 * @title dForce's Liquid Stability Reserve Base Model
 * @author dForce
 */
abstract contract LSRModelBase is Pausable, LSRMinter, LSRCalculator {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @dev Address of LSR's active strategy.
    address internal strategy_;

    /// @dev Emitted when `strategy_` is changed.
    event ChangeStrategy(address oldStrategy, address strategy);

    /// @dev Emitted when buy msd.
    event BuyMsd(
        address caller,
        address recipient,
        uint256 msdAmount,
        uint256 mprAmount
    );

    /// @dev Emitted when sell msd.
    event SellMsd(
        address caller,
        address recipient,
        uint256 msdAmount,
        uint256 mprAmount
    );

    /**
     * @notice Initialize the MSD,MPR,strategy related data.
     * @param _msd MSD address.
     * @param _mpr MSD peg reserve address.
     * @param _strategy strategy address.
     */
    function _initialize(
        address _msd,
        address _mpr,
        address _strategy
    ) internal virtual {
        LSRCalculator._initialize(_msd, _mpr);
        _setStrategy(_strategy);
    }

    /**
     * @dev Unpause when LSR is paused.
     */
    function _open() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Pause LSR.
     */
    function _close() external onlyOwner {
        _pause();
    }

    /**
     * @dev Change strategy and move totalDeposits into new strategy.
     * @param _strategy strategy address.
     */
    function _switchStrategy(address _strategy) public virtual onlyOwner {
        require(_strategy != strategy_, "_switchStrategy: _strategy is active");

        strategy_.functionDelegateCall(
            abi.encodeWithSignature("withdrawAll()")
        );

        strategy_.functionDelegateCall(
            abi.encodeWithSignature("approveStrategy(bool)", false)
        );

        _setStrategy(_strategy);
    }

    /**
     * @dev Withdraw reserves to recipient address.
     * @param _recipient Recipient address.
     * @return _reservesAmount Amount of reserves.
     */
    function _withdrawReserves(address _recipient)
        external
        virtual
        onlyOwner
        returns (uint256 _reservesAmount)
    {
        uint256 _mprTotal = _calculator(
            totalMint_,
            msdDecimalScaler_,
            mprDecimalScaler_
        );

        if (_mprTotal == 0) {
            strategy_.functionDelegateCall(
                abi.encodeWithSignature("withdrawAll()")
            );
            _reservesAmount = IERC20(mpr_).balanceOf(address(this));
        } else {
            uint256 _totalDeposits = totalDeposits();

            if (_totalDeposits > _mprTotal) {
                _reservesAmount = _totalDeposits - _mprTotal;
                strategy_.functionDelegateCall(
                    abi.encodeWithSignature(
                        "withdraw(uint256)",
                        _reservesAmount
                    )
                );
            }
        }

        if (_reservesAmount > 0)
            IERC20(mpr_).safeTransfer(_recipient, _reservesAmount);
    }

    /**
     * @dev Claim rewards and transfer to the treasury.
     * @param _treasury Treasury address.
     */
    function _claimRewards(address _treasury) external virtual onlyOwner {
        strategy_.functionDelegateCall(
            abi.encodeWithSignature("_claimRewards(address)", _treasury)
        );
    }

    /**
     * @dev Set strategy and add to `strategies_`.
     * @param _strategy strategy address.
     */
    function _setStrategy(address _strategy) internal {
        require(
            IStrategy(_strategy).isLSRStrategy(),
            "_setStrategy: _strategy is not LSRStrategy contract"
        );
        require(
            IStrategy(_strategy).mpr() == mpr_,
            "_setStrategy: strategy's mpr does not match LSR"
        );

        _strategy.functionDelegateCall(
            abi.encodeWithSignature("approveStrategy(bool)", true)
        );

        uint256 _reserves = IERC20(mpr_).balanceOf(address(this));
        if (_reserves > 0)
            _strategy.functionDelegateCall(
                abi.encodeWithSignature("deposit(uint256)", _reserves)
            );

        address _oldStrategy = strategy_;
        strategy_ = _strategy;
        emit ChangeStrategy(_oldStrategy, strategy_);
    }

    /**
     * @dev The caller's MPR are deposited into liquidity model.
     * @param _caller Caller's address.
     * @param _amount Deposit amount.
     */
    function _deposit(address _caller, uint256 _amount) internal virtual {
        strategy_.functionDelegateCall(
            abi.encodeWithSignature(
                "depositFor(address,uint256)",
                _caller,
                _amount
            )
        );
    }

    /**
     * @dev Withdraw from liquidity model and transfer to recipient.
     * @param _recipient Recipient address.
     * @param _amount Withdraw amount.
     */
    function _withdraw(address _recipient, uint256 _amount) internal virtual {
        strategy_.functionDelegateCall(
            abi.encodeWithSignature(
                "withdrawTo(address,uint256)",
                _recipient,
                _amount
            )
        );
    }

    /**
     * @dev Caller buy MSD with MPR.
     * @param _caller Caller's address.
     * @param _recipient Recipient's address.
     * @param _mprAmount MPR amount.
     */
    function _buyMsd(
        address _caller,
        address _recipient,
        uint256 _mprAmount
    ) internal virtual whenNotPaused {
        _deposit(_caller, _mprAmount);
        uint256 _msdAmount = _amountToBuy(_mprAmount);
        _mint(_recipient, _msdAmount);
        emit BuyMsd(_caller, _recipient, _msdAmount, _mprAmount);
    }

    /**
     * @dev Caller sells MSD, receives MPR.
     * @param _caller Caller's address.
     * @param _recipient Recipient's address.
     * @param _msdAmount Msd amount.
     */
    function _sellMsd(
        address _caller,
        address _recipient,
        uint256 _msdAmount
    ) internal virtual whenNotPaused {
        _burn(_caller, _msdAmount);
        uint256 _mprAmount = _amountToSell(_msdAmount);
        _withdraw(_recipient, _mprAmount);
        emit SellMsd(_caller, _recipient, _msdAmount, _mprAmount);
    }

    /**
     * @dev Buy MSD with MPR.
     * @param _mprAmount MPR amount.
     */
    function buyMsd(uint256 _mprAmount) external {
        _buyMsd(msg.sender, msg.sender, _mprAmount);
    }

    /**
     * @dev Buy MSD with MPR.
     * @param _recipient Recipient's address.
     * @param _mprAmount MPR amount.
     */
    function buyMsd(address _recipient, uint256 _mprAmount) external {
        _buyMsd(msg.sender, _recipient, _mprAmount);
    }

    /**
     * @dev Sells MSD, receives MPR.
     * @param _msdAmount MSD amount.
     */
    function sellMsd(uint256 _msdAmount) external {
        _sellMsd(msg.sender, msg.sender, _msdAmount);
    }

    /**
     * @dev Sells MSD, receives MPR.
     * @param _recipient Recipient's address.
     * @param _msdAmount MSD amount.
     */
    function sellMsd(address _recipient, uint256 _msdAmount) external {
        _sellMsd(msg.sender, _recipient, _msdAmount);
    }

    /**
     * @dev Active strategy address.
     */
    function strategy() external view returns (address) {
        return strategy_;
    }

    /**
     * @dev  LSD estimated reserves.
     */
    function estimateReserves() external virtual returns (uint256 _reserve) {
        uint256 _totalDeposits = totalDeposits();

        uint256 _mprAmount = _calculator(
            totalMint_,
            msdDecimalScaler_,
            mprDecimalScaler_
        );

        if (_totalDeposits > _mprAmount)
            _reserve = _totalDeposits.sub(_mprAmount);
    }

    /**
     * @dev Deposit amount of LSR in strategy.
     */
    function totalDeposits() public virtual returns (uint256) {
        return
            abi.decode(
                strategy_.functionDelegateCall(
                    abi.encodeWithSignature("totalDeposits()")
                ),
                (uint256)
            );
    }

    /**
     * @dev Strategy current liquidity.
     */
    function liquidity() public virtual returns (uint256) {
        return
            abi.decode(
                strategy_.functionDelegateCall(
                    abi.encodeWithSignature("liquidity()")
                ),
                (uint256)
            );
    }

    /**
     * @dev Quotas for MSD peg reserve
     */
    function mprQuota() external view virtual returns (uint256) {
        return _calculator(totalMint_, msdDecimalScaler_, mprDecimalScaler_);
    }

    /**
     * @dev Available quota for MPR in LSR.
     */
    function mprOutstanding() external virtual returns (uint256 _outstandings) {
        _outstandings = totalDeposits();

        uint256 _cash = liquidity();
        if (_outstandings > _cash) _outstandings = _cash;

        uint256 _mprTotal = _calculator(
            totalMint_,
            msdDecimalScaler_,
            mprDecimalScaler_
        );

        if (_outstandings > _mprTotal) _outstandings = _mprTotal;
    }

    /**
     * @dev  Amount of reward earned in the strategy.
     */
    function rewardsEarned() external returns (uint256) {
        return
            abi.decode(
                strategy_.functionDelegateCall(
                    abi.encodeWithSignature("rewardsEarned()")
                ),
                (uint256)
            );
    }
}
