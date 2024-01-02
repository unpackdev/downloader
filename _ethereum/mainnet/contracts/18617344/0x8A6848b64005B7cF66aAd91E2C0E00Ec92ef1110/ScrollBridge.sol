pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IPointsDistributor.sol";
import "./IScrollGateway.sol";
import "./IL2GasOracle.sol";
import "./console.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract ScrollBridge is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public constant SCROLL_GATEWAY =
        0x6774Bcbd5ceCeF1336b5300fb5186a12DDD8b367;
    address public constant L2_RECEPIENT =
        0xa46A62Be5955fB988c868654722Ea780e9EF72b6;
    address public constant FEE_REFUNDER =
        0x6774Bcbd5ceCeF1336b5300fb5186a12DDD8b367;
    address public constant GAS_PRICE_ORACLE =
        0x987e300fDfb06093859358522a79098848C33852;
    uint256 public constant GAS_LIMIT = 1_000_000;

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
        uint256 fee = (amount * shortcutComplexity) / baseShortcutFee;

        payable(feeDestination).transfer(fee);
        return fee;
    }

    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);
        uint256 l2GasPrice = IL2GasOracle(GAS_PRICE_ORACLE).l2BaseFee();
        uint256 gasLimitCost = GAS_LIMIT * l2GasPrice;

        bytes memory swapAndProveLiqudityData = abi.encodeWithSignature(
            "swapAndProveLiqudity(address)",
            msg.sender
        );
       
        IScrollGateway(FEE_REFUNDER).sendMessage{value: msg.value - chargedFees}(
            L2_RECEPIENT,
            msg.value - (gasLimitCost + chargedFees),
            swapAndProveLiqudityData,
            GAS_LIMIT,
            msg.sender
        );
        if (IPointsDistributor(rewardsContract).isPointDistributionActive()) {
            IPointsDistributor(rewardsContract).distributePoints(msg.value);
        }
    }
}
