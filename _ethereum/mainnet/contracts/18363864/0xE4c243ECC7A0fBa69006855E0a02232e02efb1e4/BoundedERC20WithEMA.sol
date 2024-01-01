// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "GovernanceOnly.sol";
import "IBoundedERC20WithEMA.sol";
import "ScaledMath.sol";
import "LogExpMath.sol";
import "ERC20Upgradeable.sol";
import "IERC20.sol";

contract BoundedERC20WithEMA is
    IBoundedERC20WithEMA,
    ERC20Upgradeable,
    GovernanceOnly
{
    using ScaledMath for uint256;
    using LogExpMath for uint256;

    event WindowWidthUpdated(uint256 windowWidth);

    IERC20 public immutable underlying;

    struct UintValue {
        uint256 blockNb;
        uint256 value;
    }

    UintValue public previousBoundedPctOfSupply;
    UintValue public expMovingAverage;

    uint256 public windowWidth;

    constructor(
        address governance,
        address _underlying
    ) GovernanceOnly(governance) {
        underlying = IERC20(_underlying);
    }

    function initialize(uint256 _windowWidth) external initializer {
        require(
            _windowWidth >= 0.01e18,
            "window width must be scaled to 18 decimals"
        );
        __ERC20_init("BoundedGYD", "bGYD");
        windowWidth = _windowWidth;

        uint256 boundedPct = boundedPctOfSupply();
        expMovingAverage.value = boundedPct;
        previousBoundedPctOfSupply.value = boundedPct;

        expMovingAverage.blockNb = block.number;
        previousBoundedPctOfSupply.blockNb = block.number;

        emit WindowWidthUpdated(windowWidth);
    }

    event Deposit(address indexed src, uint256 amount);

    function deposit(uint256 _amount) public {
        underlying.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
        _updateEMA();
    }

    event Withdraw(address indexed dst, uint256 amount);

    function withdraw(uint256 _amount) public {
        _burn(msg.sender, _amount);
        underlying.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
        _updateEMA();
    }

    function boundedPctOfSupply() public view returns (uint256) {
        uint256 gydTotalSupply = underlying.totalSupply();
        if (gydTotalSupply == 0) {
            return 0;
        }
        return totalSupply().divDown(gydTotalSupply);
    }

    function _updateEMA() internal {
        if (previousBoundedPctOfSupply.blockNb < block.number) {
            uint256 multiplier = ScaledMath.ONE;
            uint256 deltaBlockNb = (previousBoundedPctOfSupply.blockNb -
                expMovingAverage.blockNb) * multiplier;
            int256 exponent = -int256(deltaBlockNb.divDown(windowWidth));
            if (exponent > LogExpMath.MIN_NATURAL_EXPONENT) {
                int256 discount = LogExpMath.exp(exponent);
                multiplier -= uint256(discount);
            }

            if (previousBoundedPctOfSupply.value > expMovingAverage.value) {
                expMovingAverage.value += (previousBoundedPctOfSupply.value -
                    expMovingAverage.value).mulDown(multiplier);
            } else {
                expMovingAverage.value -= (expMovingAverage.value -
                    previousBoundedPctOfSupply.value).mulDown(multiplier);
            }

            expMovingAverage.blockNb = previousBoundedPctOfSupply.blockNb;
        }
        previousBoundedPctOfSupply.value = boundedPctOfSupply();
        previousBoundedPctOfSupply.blockNb = block.number;
    }

    function updateEMA() external {
        _updateEMA();
    }

    function setWindowWidth(uint256 _windowWidth) external governanceOnly {
        require(
            _windowWidth >= 0.01e18,
            "window width must be scaled to 18 decimals"
        );
        windowWidth = _windowWidth;
        emit WindowWidthUpdated(windowWidth);
    }

    function boundedPctEMA() public view returns (uint256) {
        return uint256(expMovingAverage.value);
    }
}
