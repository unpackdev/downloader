// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IAcross.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract AnimaOnArb is OwnableUpgradeable {
    uint256 public constant CHAIN_ID = 42161;
    uint256 public constant SHORTCUT_COMPLEXITY = 2;
    uint256 public constant SHORTCUT_BASE_FEE = 1000;

    address public constant BRIDGE = 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public feeDestination;
    address public l2Recepient;
    uint256 public decimal1;
    uint256 public decimal2;
    uint256 public percent1;
    uint256 public percent2;

    uint256[50] private _gap;

    function initialize() public initializer {
        __Ownable_init();
        decimal1 = 16;
        decimal2 = 15;
        percent1 = 10;
        percent2 = 2;
        l2Recepient = 0xb908Da90726f0959266F28BDD37c84edBbAc1Cd3;
    }

    function changeRecepinet(address newL2Recepient) public onlyOwner {
        l2Recepient = newL2Recepient;
    }

    function changeDecimal1(uint256 newDec1) public onlyOwner {
        decimal1 = newDec1;
    }

    function changeDecimal2(uint256 newDec2) public onlyOwner {
        decimal2 = newDec2;
    }

    function changePercent1(uint256 newPercent1) public onlyOwner {
        percent1 = newPercent1;
    }

    function changePercent2(uint256 newPercent2) public onlyOwner {
        percent2 = newPercent2;
    }

    function changeFeeDestination(address newFeeDestination) public onlyOwner {
        feeDestination = newFeeDestination;
    }

    function speedUpDeposit(
        address depositor,
        int64 updatedRelayerFeePct,
        uint32 depositId,
        address updatedRecipient,
        bytes memory updatedMessage,
        bytes memory depositorSignature
    ) public onlyOwner {
        IAcross(BRIDGE).speedUpDeposit(
            depositor,
            updatedRelayerFeePct,
            depositId,
            updatedRecipient,
            updatedMessage,
            depositorSignature
        );
    }

    function getHighRelayersFee(uint256 val) public view returns (int64) {
        if (val <= 0.1 ether) {
            return int64(int256((percent1 * 10 ** decimal1)));
        } else {
            return int64(int256((percent2 * 10 ** decimal2)));
        }
    }

    function _chargeFee(uint256 amount) internal returns (uint256) {
        uint256 fee = (amount * SHORTCUT_COMPLEXITY) / SHORTCUT_BASE_FEE;

        payable(feeDestination).transfer(fee);
        return fee;
    }

    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);
        uint256 valueAfterFees = msg.value - chargedFees;
        int64 relayerFeePct = getHighRelayersFee(valueAfterFees);
        bytes memory message = abi.encode(msg.sender);
        
        IAcross(BRIDGE).deposit{value: valueAfterFees}(
            l2Recepient,
            WETH,
            valueAfterFees,
            CHAIN_ID,
            relayerFeePct,
            uint32(block.timestamp),
            message,
            type(uint256).max
        );
    }
}
