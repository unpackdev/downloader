// File: contracts/BulkRenewal.sol
// Deployed: 0xfF252725f6122A92551A5FA9a6b6bf10eb0Be035
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./IETHRegistrarController.sol";

contract BulkRenewal {

    function getController() internal pure returns(IETHRegistrarController) {
        return IETHRegistrarController(0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5);
    }

    function rentPrice(string[] calldata names, uint duration) external view returns(uint total) {
        IETHRegistrarController controller = getController();
        for(uint i = 0; i < names.length; i++) {
            total += controller.rentPrice(names[i], duration);
        }
    }

    function renewAll(string[] calldata names, uint duration) external payable {
        IETHRegistrarController controller = getController();
        for(uint i = 0; i < names.length; i++) {
            uint cost = controller.rentPrice(names[i], duration);
            controller.renew{value: cost}(names[i], duration);
        }
        // Send any excess funds back
        payable(msg.sender).transfer(address(this).balance);
    }
}