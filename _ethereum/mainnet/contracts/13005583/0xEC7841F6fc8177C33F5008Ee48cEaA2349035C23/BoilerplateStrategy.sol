// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IVault.sol";
import "./IStrategy.sol";

abstract contract BoilerplateStrategy is IStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum Setting { CONTROLLER_SET, STRATEGIST_SET, PROFIT_SHARING_SET, LIQ_ALLOWED_SET,
                    HARVEST_ALLOWED_SET, SELL_FLOOR_SET } 

    address public underlying;
    address public strategist;
    address public controller;
    address public vault;

    uint256 public profitSharingNumerator;
    uint256 public profitSharingDenominator;

    bool public harvestOnWithdraw;

    bool public liquidationAllowed = true;
    uint256 public sellFloor = 0;

    // These tokens cannot be claimed by the controller
    mapping(address => bool) public unsalvageableTokens;


    event ProfitShared(uint256 amount, uint256 fee, uint256 timestamp);
    event SettingChanged(Setting setting, address initiator, uint timestamp);

    modifier restricted() {
        require(
            msg.sender == vault || msg.sender == controller ||
            msg.sender == IVault(vault).governance() || msg.sender == strategist,
            "Sender must be privileged"
        );
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == IVault(vault).governance(), "!governance");
        _;
    }

    constructor(address _vault, address _underlying, address _strategist) public {
        vault = _vault;

        underlying = _underlying;

        strategist = _strategist;

        harvestOnWithdraw = true;

        profitSharingNumerator = 30;
        profitSharingDenominator = 100;

        require(IVault(vault).token() == _underlying, "vault does not support underlying");
        controller = IVault(vault).controller();       
    }

    function setController(address _controller) external onlyGovernance {
        controller = _controller;
        emit SettingChanged(Setting.CONTROLLER_SET, msg.sender, block.timestamp);
    }

    function setStrategist(address _strategist) external restricted {
        strategist = _strategist;
        emit SettingChanged(Setting.STRATEGIST_SET, msg.sender, block.timestamp);
    }

    function setProfitSharing(uint256 _profitSharingNumerator, uint256 _profitSharingDenominator) external restricted {
        require(_profitSharingDenominator > 0, "Incorrect denominator");
        require(_profitSharingNumerator < _profitSharingDenominator, "Numerator < Denominator");
        profitSharingNumerator = _profitSharingNumerator;
        profitSharingDenominator = _profitSharingDenominator;
        emit SettingChanged(Setting.PROFIT_SHARING_SET, msg.sender, block.timestamp);
    }

    function setHarvestOnWithdraw(bool _flag) external restricted {
        harvestOnWithdraw = _flag;
        emit SettingChanged(Setting.HARVEST_ALLOWED_SET, msg.sender, block.timestamp);
    }

    /**
     * Allows liquidation
     */
    function setLiquidationAllowed(bool allowed) external restricted {
        liquidationAllowed = allowed;
        emit SettingChanged(Setting.LIQ_ALLOWED_SET, msg.sender, block.timestamp);
    }

    function setSellFloor(uint256 value) external restricted {
        sellFloor = value;
        emit SettingChanged(Setting.SELL_FLOOR_SET, msg.sender, block.timestamp);
    }

    /**
     * Withdraws a token.
     */
    function withdraw(address token) external override restricted {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvageableTokens[token], "!salvageable");
        uint256 balance =  IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(vault, balance);
    }


    function _profitSharing(uint256 amount) internal virtual {
      if (profitSharingNumerator == 0) {
          return;
      }
      uint256 feeAmount = amount.mul(profitSharingNumerator).div(profitSharingDenominator);
      emit ProfitShared(amount, feeAmount, block.timestamp);

      if(feeAmount > 0) {
        IERC20(underlying).safeTransfer(controller, feeAmount);
      }
    }
}
