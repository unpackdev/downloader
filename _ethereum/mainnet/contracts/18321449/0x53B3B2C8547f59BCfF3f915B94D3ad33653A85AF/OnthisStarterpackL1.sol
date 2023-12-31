pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
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

contract OnthisStarterpackL1 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    event Paricipant(address paticipant);
    
    address public constant CROSS_CHAIN_PORTAL =
        0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address public constant STARTER_PACK_L2 =
        0xa46A62Be5955fB988c868654722Ea780e9EF72b6;
    uint64 public constant GAS_LIMIT_FOR_CALL = 2_500_000;
    uint256 public constant MAX_FEE_PER_GAS = 1 gwei;
    uint256 public constant MAX_SUBMISSION_COST = 0.001 ether;

    uint256[50] private _gap;
    
    function initialize() public initializer {
        __Ownable_init();
    }

    receive() external payable {
        bytes memory openLongData = abi.encodeWithSelector(
            bytes4(keccak256("starterpackSwap(address)")),
            msg.sender
        );
        uint256 requiredValue = MAX_SUBMISSION_COST +
            GAS_LIMIT_FOR_CALL *
            MAX_FEE_PER_GAS;

        CrosschainPortal(CROSS_CHAIN_PORTAL).createRetryableTicket{
            value: msg.value
        }(
            STARTER_PACK_L2,
            msg.value - requiredValue,
            MAX_SUBMISSION_COST,
            msg.sender,
            msg.sender,
            GAS_LIMIT_FOR_CALL,
            MAX_FEE_PER_GAS,
            openLongData
        );

        emit Paricipant(msg.sender);
    }
}
