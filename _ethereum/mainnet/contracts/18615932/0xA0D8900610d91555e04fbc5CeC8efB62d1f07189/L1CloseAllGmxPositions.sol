pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./L1GmxBase.sol";
import "./CrosschainPortal.sol";

contract L1CloseAllGmxPositions is L1GmxBase {
    uint256 public constant GMX_CLOSING_FEES = 0.00072 ether;
    address public constant FEE_RECEIVER =
        0xCe03b880634EbD9bD0F6974CcF430EDED3A8363F;

    function depositFeeFunds() public payable {}

    function withdrawFunds(address to, uint256 amount) public onlyOwner {
        payable(to).transfer(amount);
    }

    receive() external payable {
        bytes memory closeAllPositionsData = abi.encodeWithSelector(
            bytes4(keccak256("closeAllPositions(address)")),
            msg.sender
        );

        uint256 requiredGasValue = MAX_SUBMISSION_COST +
            GMX_CLOSING_FEES +
            GAS_LIMIT_FOR_CALL *
            MAX_FEE_PER_GAS;

        CrosschainPortal(CROSS_CHAIN_PORTAL).createRetryableTicket{
            value: requiredGasValue
        }(
            ARB_RECEIVER,
            GMX_CLOSING_FEES,
            MAX_SUBMISSION_COST,
            FEE_RECEIVER,
            FEE_RECEIVER,
            GAS_LIMIT_FOR_CALL,
            MAX_FEE_PER_GAS,
            closeAllPositionsData
        );
    }
}
