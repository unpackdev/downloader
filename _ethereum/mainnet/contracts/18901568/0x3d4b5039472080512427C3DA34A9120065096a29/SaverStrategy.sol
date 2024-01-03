// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import "./BaseStrategy.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./OracleLibrary.sol";
import "./ISwapRouter.sol";

import "./Utils.sol";
import "./IAcrossHub.sol";
import "./IAcrossStaker.sol";

contract SaverStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address public saver;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist,
        address _saver
    ) external {
        _initialize(_vault, _strategist, _strategist, _strategist);
        saver = _saver;
        want.approve(saver, type(uint256).max);
    }

    function name() external pure override returns (string memory) {
        return "Saver Strategy";
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        return 300 ether;
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        want.safeTransfer(saver, want.balanceOf(address(this)));
    }

    function liquidateAllPositions() internal override returns (uint256) {}

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {}

    function prepareMigration(address _newStrategy) internal override {}

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {}

    function ethToWant(
        uint256 _amtInWei
    ) public view virtual override returns (uint256) {}

    receive() external payable {}
}
