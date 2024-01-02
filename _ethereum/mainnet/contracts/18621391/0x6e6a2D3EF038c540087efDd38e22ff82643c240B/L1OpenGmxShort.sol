pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IPointsDistributor.sol";
import "./L1GmxBase.sol";
import "./CrosschainPortal.sol";

contract L1OpenGmxShort is L1GmxBase {
    address public rewardsContract;

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
        uint256 fee = (amount * shortcutComplexity) / baseShortcutFee;

        payable(feeDestination).transfer(fee);
        return fee;
    }

    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);

        bytes memory openShortData = abi.encodeWithSelector(
            bytes4(keccak256("openX10Leverage(address,bool)")),
            msg.sender,
            false
        );
        uint256 requiredValue = MAX_SUBMISSION_COST +
            GAS_LIMIT_FOR_CALL *
            MAX_FEE_PER_GAS;
        CrosschainPortal(CROSS_CHAIN_PORTAL).createRetryableTicket{
            value: msg.value - chargedFees
        }(
            ARB_RECEIVER,
            msg.value - (requiredValue + chargedFees),
            MAX_SUBMISSION_COST,
            msg.sender,
            msg.sender,
            GAS_LIMIT_FOR_CALL,
            MAX_FEE_PER_GAS,
            openShortData
        );
        if (IPointsDistributor(rewardsContract).isPointDistributionActive()) {
            IPointsDistributor(rewardsContract).distributePoints(msg.value);
        }
    }
}
