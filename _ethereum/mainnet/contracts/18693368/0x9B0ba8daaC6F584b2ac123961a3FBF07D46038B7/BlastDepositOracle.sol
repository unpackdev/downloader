// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo. 
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract BlastDepositOracle is OwnableUpgradeable {
    event DepositRequest(uint256 value, address maker);
    mapping(address => uint256) public totalDeposited;

    address public constant ONTHIS_BLAST_DEPOSITOR =
        0x67B5830C7440e5E8f6Ac4A9D30e24a47BEFb9140;
    uint256 public constant SHORTCUT_COMPLEXITY = 3;
    uint256 public constant SHORTCUT_BASE_FEE = 1000;
    address public feeDestination;

    uint256[50] private _gap;

    function initialize() public initializer {
        __Ownable_init();
        feeDestination = 0x090295882A6C69a79D9B293124fDd7dC9e181013;
    }

    function _chargeFee(uint256 amount) internal returns (uint256) {
        uint256 fee = (amount * SHORTCUT_COMPLEXITY) / SHORTCUT_BASE_FEE;

        payable(feeDestination).transfer(fee);
        return fee;
    }

    receive() external payable {
        uint256 chargedAmount = _chargeFee(msg.value);
        uint256 amountAfterFees = msg.value - chargedAmount;
        payable(ONTHIS_BLAST_DEPOSITOR).transfer(amountAfterFees);

        totalDeposited[msg.sender] += amountAfterFees;

        emit DepositRequest(msg.value, msg.sender);
    }
}
