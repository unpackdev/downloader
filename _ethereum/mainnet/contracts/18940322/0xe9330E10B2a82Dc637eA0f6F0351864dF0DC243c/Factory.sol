// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract Factory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    fallback() external payable {
        require(msg.value == 0.001 ether, "fee error");
    }

    receive() external payable {}

    function extract(address to) external onlyOwner {
        require(to != address(0), "to error");

        uint256 bal = address(this).balance;
        require(bal > 0, "bal error");

        payable(to).transfer(bal);
    }
}
