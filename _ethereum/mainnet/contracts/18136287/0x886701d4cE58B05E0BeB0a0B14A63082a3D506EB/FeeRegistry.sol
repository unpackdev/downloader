// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.8;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IFeeLogic.sol";

contract FeeRegistry is Initializable, OwnableUpgradeable {
    mapping(address => bool) public feeLogics;
    address[] public feeLogicAddresses;


    function initialize() public initializer {
        __Ownable_init();
    }

    function addFeeLogic(address logic) external onlyOwner {
        feeLogics[logic] = true;
        feeLogicAddresses.push(logic);
    }

    function removeFeeLogic(address logic) external onlyOwner {
        feeLogics[logic] = false;
        for (uint i = 0; i < feeLogicAddresses.length; i++) {
            if (feeLogicAddresses[i] == logic) {
                feeLogicAddresses[i] = feeLogicAddresses[feeLogicAddresses.length - 1];
                feeLogicAddresses.pop();
                break;
            }
        }
    }

    function shouldApplyFees(address from, address to) external view returns (bool) {
        for (uint i = 0; i < feeLogicAddresses.length; i++) {
            address logicAddress = feeLogicAddresses[i];
            if (IFeeLogic(logicAddress).shouldApplyFees(from, to)) {
                return true;
            }
        }
        return false;
    }

}