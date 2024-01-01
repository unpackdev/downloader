// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IPointsDistributor.sol";
import "./ICurve.sol";
import "./IWeth.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo. 
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract FrxCurve is OwnableUpgradeable {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CRV_FRX_WETH_POOL =
        0x9c3B46C0Ceb5B9e304FCd6D88Fc50f7DD24B31Bc;

    uint256[50] private _gap;
    address public rewardsContract;

    function initialize() public initializer {
        __Ownable_init();
    }


    function setPointsDistributorContract(
        address _rewardsContract
    ) public onlyOwner {
        rewardsContract = _rewardsContract;
    }

    function _chargeFee(uint256 amount) private returns (uint256) {
        address feeDestination = IPointsDistributor(rewardsContract)
            .feeDestination();
        uint256 shortcutComplexity = IPointsDistributor(rewardsContract)
            .shortcuts(address(this))
            .complexity;
        uint256 fee = amount / (shortcutComplexity * 1000);

        payable(feeDestination).transfer(fee);
        return fee;
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);

        uint256 balanceBefore = IWeth(WETH).balanceOf(address(this));

        IWeth(WETH).deposit{value: msg.value - chargedFees}();
        IWeth(WETH).approve(
            CRV_FRX_WETH_POOL,
            IWeth(WETH).balanceOf(address(this))
        );
        ICurve(CRV_FRX_WETH_POOL).add_liquidity(
            [IWeth(WETH).balanceOf(address(this)), 0],
            0
        );

        uint256 balanceAfter = IWeth(WETH).balanceOf(address(this));

        IERC20(CRV_FRX_WETH_POOL).transfer(
            msg.sender,
            IERC20(CRV_FRX_WETH_POOL).balanceOf(address(this))
        );

        if (IWeth(WETH).balanceOf(address(this)) > 0) {
            IWeth(WETH).transfer(msg.sender, balanceAfter - balanceBefore);
        }
        if (IPointsDistributor(rewardsContract).isPointDistributionActive()) {
            IPointsDistributor(rewardsContract).distributePoints(msg.value);
        }
    }
}
