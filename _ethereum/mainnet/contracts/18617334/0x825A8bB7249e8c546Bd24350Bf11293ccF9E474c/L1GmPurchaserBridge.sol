pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IPointsDistributor.sol";
import "./CrosschainPortal.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo. 
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/
contract L1GmPurchaserBridge is OwnableUpgradeable {
    address public constant FEE_RECEIVER =
        0xCe03b880634EbD9bD0F6974CcF430EDED3A8363F;
    address public constant CROSS_CHAIN_PORTAL =
        0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address public constant ARB_RECEIVER =
        0x3C39f730de2714e7856031D36E57e2bD8cbF050f;
    uint64 public constant GAS_LIMIT_FOR_CALL = 3_000_000;
    uint256 public constant MAX_FEE_PER_GAS = 1 gwei;
    uint256 public constant MAX_SUBMISSION_COST = 0.001 ether;

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

    /// @notice Creates crosschain tx to ARB_RECEIVER(deployed at arbitrum), swaps ETH to ARB => provides liqudity at GMX V2 pool(ARB/USDC)
    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);
        bytes memory createRequestData = abi.encodeWithSelector(
            bytes4(keccak256("swapAndProvideLiqudity(address)")),
            msg.sender
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
            createRequestData
        );
        if (IPointsDistributor(rewardsContract).isPointDistributionActive()) {
            IPointsDistributor(rewardsContract).distributePoints(msg.value);
        }
    }
}
