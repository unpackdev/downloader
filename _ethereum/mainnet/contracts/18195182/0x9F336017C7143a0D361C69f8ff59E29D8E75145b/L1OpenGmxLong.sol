pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./L1GmxBase.sol";
import "./CrosschainPortal.sol";

contract L1OpenGmxLong is L1GmxBase {
    receive() external payable {
        bytes memory openLongData = abi.encodeWithSelector(
            bytes4(keccak256("openX20Leverage(address,bool)")),
            msg.sender,
            true
        );
        uint256 requiredValue = MAX_SUBMISSION_COST +
            GAS_LIMIT_FOR_CALL *
            MAX_FEE_PER_GAS;

        CrosschainPortal(CROSS_CHAIN_PORTAL).createRetryableTicket{
            value: msg.value
        }(
            ARB_RECEIVER,
            msg.value - requiredValue,
            MAX_SUBMISSION_COST,
            msg.sender,
            msg.sender,
            GAS_LIMIT_FOR_CALL,
            MAX_FEE_PER_GAS,
            openLongData
        );
    }
}
