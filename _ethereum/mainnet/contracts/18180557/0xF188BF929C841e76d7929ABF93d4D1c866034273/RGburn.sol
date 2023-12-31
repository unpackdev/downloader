// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IREAPERSGAMBIT {
    function transferOwnership(address newOwner) external;
    function CheatDeath(address account) external;
    function AcceptDeath(address account) external;
}

contract RGBurn is Ownable, ReentrancyGuard {
    IERC20 private tokenContract;
    IREAPERSGAMBIT private rgContract;

    constructor(address _tokenContractAddress, address _rgContractAddress) {
        tokenContract = IERC20(_tokenContractAddress);
        rgContract = IREAPERSGAMBIT(_rgContractAddress);
    }

    function burn(uint256 amount) public nonReentrant {
        require(amount > 0, "Amount cannot be zero");
        require(tokenContract.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(tokenContract.allowance(msg.sender, address(this)) >= amount, "RGBurn not approved to transfer requested burn amount");

        // immunity
        rgContract.CheatDeath(msg.sender);

        // burn
        require(tokenContract.transferFrom(msg.sender, address(0), amount), "Transfer failed");

        // remove immunity
        rgContract.AcceptDeath(msg.sender);
    }

    function proxyCheatDeath(address account) public onlyOwner {
        rgContract.CheatDeath(account);
    }

    function proxyAcceptDeath(address account) public onlyOwner {
        rgContract.AcceptDeath(account);
    }

    function transferRGOwnership(address newOwner) public onlyOwner {
        rgContract.transferOwnership(newOwner);
    }
}