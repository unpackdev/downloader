// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract CreatorTrust is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    address public foundAddress;
    // event
    event Subsciption(uint256 _transId, uint256 _amount);

    constructor(address _found) {
        foundAddress = _found;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    function subscribe(uint256 _transId) external payable callerIsUser {
        require(msg.value > 0, "value is not valid");
        payable(address(foundAddress)).transfer(msg.value);
        emit Subsciption(_transId, msg.value);
    }

    function withdraw(uint256 _amount) public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: _amount}("");
        require(os);
    }
}
