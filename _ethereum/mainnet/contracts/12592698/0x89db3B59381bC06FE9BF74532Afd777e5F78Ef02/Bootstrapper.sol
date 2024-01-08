pragma solidity ^0.5.0;

import "./Comptroller.sol";
import "./Require.sol";

contract Bootstrapper is Comptroller {

    bytes32 private constant FILE = "Bootstrapper";

    event Swap(address indexed sender, uint256 amount, uint256 contributions);
    event Incentivization(address indexed account, uint256 amount);
    event DAIIncentivization(address indexed account, uint256 amount);
    event MixedIncentivization(address indexed account, uint256 daiqAmount, uint256 daiAmount);

    function step() internal {
        if (epoch() == 0) {
            uint256 bootstrapInflation = Constants.getBootstrappingPrice().sub(Decimal.one()).div(Constants.getSupplyChangeDivisor()).value;
            uint256 supply = dollar().totalSupply().mul(1e18);
            uint256 supplyTarget = Constants.getBootstrappingTarget().value;
            uint256 epochs = 0;

            if (supply > 0)
                while(supply < supplyTarget) {
                    supply = supply + supply * bootstrapInflation / 1e18;
                    epochs ++;
                }

            setBootstrappingPeriod(epochs > 0 ? epochs - 1 : 0);

            uint256 daiIncentive = epochs > 0 ? totalContributions().div(epochs) : Constants.getDaiAdvanceIncentiveCap();
            setDAIAdvanceIncentive(
                daiIncentive > 0
                    ? daiIncentive > Constants.getDaiAdvanceIncentiveCap()
                        ? Constants.getDaiAdvanceIncentiveCap()
                        : daiIncentive
                    : Constants.getAdvanceIncentive()
            );

            shouldDistributeDAI(true);
        }

        if (shouldDistributeDAI()) {
            uint256 balance = dai().balanceOf(address(this));
            uint256 incentive = daiAdvanceIncentive();

            if (balance > incentive) {
                dai().transfer(msg.sender, incentive);
                emit DAIIncentivization(msg.sender, incentive);
            }
            else {
                uint256 daiqIncentive = incentive.sub(balance);
                dai().transfer(msg.sender, balance);
                mintToAccount(msg.sender, daiqIncentive);
                emit MixedIncentivization(msg.sender, daiqIncentive, balance);
                
                shouldDistributeDAI(false);
            }
        }
        else {
            // Mint advance reward to sender
            uint256 incentive = Constants.getAdvanceIncentive();
            mintToAccount(msg.sender, incentive);
            emit Incentivization(msg.sender, incentive);
        }
    }
}