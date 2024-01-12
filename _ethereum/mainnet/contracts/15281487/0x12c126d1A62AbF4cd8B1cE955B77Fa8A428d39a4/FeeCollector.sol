// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./PercentageMath.sol";
import "./IWETH.sol";
import "./IFeeCollector.sol";

contract FeeCollector is IFeeCollector, Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using PercentageMath for uint256;
    IWETH public WETH;
    address public feeDistributor;
    uint256 public treasuryPercentage;
    address public treasury;

    function initialize(
        IWETH _weth,
        address _treasury,
        address _feeDistributor
    ) external initializer {
        __Ownable_init();
        WETH = _weth;
        treasury = _treasury;
        feeDistributor = _feeDistributor;
    }

    function setTreasuryPercentage(uint256 _treasuryPercentage)
        external
        onlyOwner
    {
        require(
            _treasuryPercentage <= PercentageMath.PERCENTAGE_FACTOR,
            "FeeCollector: treasury percentage overflow"
        );
        treasuryPercentage = _treasuryPercentage;
    }

    function collect() external override {
        require(
            feeDistributor != address(0),
            "FeeCollector: feeDistributor can't be null"
        );
        require(treasury != address(0), "FeeCollector: treasury can't be null");

        uint256 _toDistribute = WETH.balanceOf(address(this));
        uint256 _toTreasury = _toDistribute.percentMul(treasuryPercentage);

        if (_toTreasury > 0) {
            IERC20Upgradeable(address(WETH)).safeTransfer(
                treasury,
                _toTreasury
            );
        }
        _toDistribute = _toDistribute - _toTreasury;
        if (_toDistribute > 0) {
            IERC20Upgradeable(address(WETH)).safeTransfer(
                feeDistributor,
                _toDistribute
            );
        }
    }
}
