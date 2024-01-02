// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./StakerBase.sol";
import "./IStaderStaker.sol";
import "./IPointsDistributor.sol";

contract StaderStaker is StakerBase {
    address public constant STADER = 0xcf5EA1b38380f6aF39068375516Daf40Ed70D299;
    address public constant ETH_X = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;

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
        uint256 baseShortcutFee = IPointsDistributor(rewardsContract)
            .shortcutBaseFee();
        uint256 fee = amount * shortcutComplexity / baseShortcutFee;

        payable(feeDestination).transfer(fee);
        return fee;
    }

    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);

        IStader(STADER).deposit{value: msg.value - chargedFees}(msg.sender);

        uint256 remaingEthX = IERC20(ETH_X).balanceOf(address(this));
        uint256 remainingEth = address(this).balance;

        require(remaingEthX == 0, "!remaingEthX");
        require(remainingEth == 0, "!remainingEth");

        if (IPointsDistributor(rewardsContract).isPointDistributionActive()) {
            IPointsDistributor(rewardsContract).distributePoints(msg.value);
        }
    }
}
