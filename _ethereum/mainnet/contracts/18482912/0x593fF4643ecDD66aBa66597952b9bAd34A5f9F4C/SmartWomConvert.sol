// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";

import "./IWombatRouter.sol";
import "./IMWom.sol";
import "./IAsset.sol";
import "./ISimpleHelper.sol";
import "./IMasterMagpie.sol";
import "./ILocker.sol";

/// @title Smart Convertor
/// @author Magpie Team

contract SmartWomConvert is ISimpleHelper, Ownable {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public immutable mWom;
    address public immutable wom;    
    address public immutable router;
    address public immutable womMWomPool;
    address public immutable masterMagpie;
    address public immutable womAsset;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant WAD = 1e18;
    uint256 public ratio;
    uint256 public buybackThreshold;
    ILocker public mWomSV;

    /* ============ Errors ============ */
    
    error IncorrectRatio();
    error MinRecNotMatch();
    error MustNoBeZero();
    error IncorrectThreshold();

    /* ============ Events ============ */

    event mWomConverted(address user, uint256 depositedWom, uint256 obtainedmWom, uint256 mode);

    /* ============ Constructor ============ */

    constructor(
        address _mwom,
        address _wom,
        address _mWomSV,
        address _router,
        address _womMWomPool,
        address _masterMagpie,
        address _womAsset,
        uint256 _ratio
    ) {
        mWom = _mwom;
        wom = _wom;
        router = _router;
        womMWomPool = _womMWomPool;
        masterMagpie = _masterMagpie;
        womAsset = _womAsset;
        ratio = _ratio;
        mWomSV = ILocker(_mWomSV);
        buybackThreshold = 9000;
    }

    /* ============ External Getters ============ */

    function estimateTotalConversion(uint256 _amount, uint256 _convertRatio)
        external
        view
        returns (uint256 minimumEstimatedTotal)
    {
        if (_convertRatio > DENOMINATOR)
            revert IncorrectRatio();
            
        uint256 buybackAmount = _amount - (_amount * _convertRatio / DENOMINATOR);
        uint256 convertAmount = _amount - buybackAmount;
        uint256 amountOut = 0;

        if (buybackAmount > 0) {
            address[] memory tokenPath = new address[](2);
            tokenPath[0] = wom;
            tokenPath[1] = mWom;

            address[] memory poolPath = new address[](1);
            poolPath[0] = womMWomPool;

            (amountOut, ) = IWombatRouter(router).getAmountOut(tokenPath, poolPath, int256(buybackAmount));
        }

        return (amountOut + convertAmount);
    }

    function maxSwapAmount() public view returns (uint256) {
        uint256 womCash = IAsset(womAsset).cash();
        uint256 womLiability = IAsset(womAsset).liability();
        if (womCash >= womLiability)
            return 0;

        return (womLiability - womCash) * ratio / DENOMINATOR;
    }

    function currentRatio() public view returns (uint256) {
        address[] memory tokenPath = new address[](2);
        tokenPath[0] = mWom;
        tokenPath[1] = wom;
        
        address[] memory poolPath = new address[](1);
        poolPath[0] = womMWomPool;
    
        (uint256 amountOut, ) = IWombatRouter(router).getAmountOut(tokenPath, poolPath, 1e18);
        return amountOut * DENOMINATOR / 1e18;
    }

    /* ============ External Functions ============ */

    function convert(uint256 _amountIn, uint256 _convertRatio, uint256 _minRec, uint256 _mode) external returns (uint256 obtainedmWomAmount) {
        obtainedmWomAmount = _convertFor(_amountIn, _convertRatio, _minRec, msg.sender, _mode);
    }

    function convertFor(uint256 _amountIn, uint256 _convertRatio, uint256 _minRec, address _for, uint256 _mode)
        external
        returns (uint256 obtainedmWomAmount)
    {
        obtainedmWomAmount = _convertFor(_amountIn, _convertRatio, _minRec, _for, _mode);
    }

    // should mainly used by wombat staking upon sending wom
    function smartConvert(uint256 _amountIn, uint256 _mode) external returns (uint256 obtainedmWomAmount) {
        if (_amountIn == 0) revert MustNoBeZero();

        uint256 convertRatio = DENOMINATOR;
        uint256 mWomToWom = currentRatio();

        if (mWomToWom < buybackThreshold) {
            uint256 maxSwap = maxSwapAmount();
            uint256 amountToSwap = _amountIn > maxSwap ? maxSwap : _amountIn;
            uint256 convertAmount = _amountIn - amountToSwap;
            convertRatio = convertAmount * DENOMINATOR / _amountIn;
        }

        return _convertFor(_amountIn, convertRatio, _amountIn, msg.sender, _mode);
    }

    function depositFor(uint256 _amount, address _for) override external {
        IERC20(mWom).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(mWom).safeApprove(masterMagpie, _amount);
        IMasterMagpie(masterMagpie).depositFor(mWom, _amount, _for);
    }

    function setRatio(uint256 _ratio) external onlyOwner {
        if (_ratio > DENOMINATOR)
            revert IncorrectRatio();

        ratio = _ratio;
    }

    function setBuybackThreshold(uint256 _threshold) external onlyOwner {
        if (_threshold > DENOMINATOR)
            revert IncorrectThreshold();

        buybackThreshold = _threshold;
    }

    /* ============ Internal Functions ============ */

    function _convertFor(uint256 _amount, uint256 _convertRatio, uint256 _minRec, address _for, uint256 _mode)
        internal returns (uint256 obtainedmWomAmount) {

        if (_convertRatio > DENOMINATOR)
            revert IncorrectRatio();

        IERC20(wom).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 buybackAmount = _amount - (_amount * _convertRatio / DENOMINATOR);
        uint256 convertAmount = _amount - buybackAmount;
        uint256 amountRec = 0;

        if (buybackAmount > 0) {
            address[] memory tokenPath = new address[](2);
            tokenPath[0] = wom;
            tokenPath[1] = mWom;
            address[] memory poolPath = new address[](1);
            poolPath[0] = womMWomPool;
        
            IERC20(wom).safeApprove(router, buybackAmount);
            amountRec = IWombatRouter(router).swapExactTokensForTokens(
                tokenPath, poolPath, buybackAmount, 0, address(this), block.timestamp
            );
        }

        if (convertAmount > 0) {
            IERC20(wom).safeApprove(mWom, convertAmount);
            IMWom(mWom).deposit(convertAmount);
        }

        if (convertAmount + amountRec < _minRec)
            revert MinRecNotMatch();

        obtainedmWomAmount = convertAmount + amountRec;

        if (_mode == 1) {
            IERC20(mWom).safeApprove(masterMagpie, obtainedmWomAmount);
            IMasterMagpie(masterMagpie).depositFor(mWom, obtainedmWomAmount, _for);
        } else if (_mode == 2) {
            IERC20(mWom).safeApprove(address(mWomSV), obtainedmWomAmount);
            mWomSV.lockFor(obtainedmWomAmount, _for);
        } else {
            IERC20(mWom).safeTransfer(_for, obtainedmWomAmount);
        }

        emit mWomConverted(_for, _amount, obtainedmWomAmount, _mode);
    }
}