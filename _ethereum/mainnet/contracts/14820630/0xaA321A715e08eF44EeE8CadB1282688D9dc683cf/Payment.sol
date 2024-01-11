//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

//import "./console.sol";
//import "./Pausable.sol";
import "./Ownable.sol";

contract GooDeePayment is Ownable {
    event buyCoinsEvent(
        address sender, 
        uint256 discordId,
        uint256 amountPayed);
    address private constant TEAM =
        address(0xC41bfB693bB4a5C18920dFf539C3fB48B0fB2272);

    constructor() {}

    function mint(uint256 discordId) external payable {
        require(msg.value >= 0.033 ether);
        emit buyCoinsEvent(msg.sender, discordId, msg.value);
    }

    function withdraw() external onlyOwner {
        bool sent;
        uint256 balance = address(this).balance;
        (sent, ) = payable(TEAM).call{value: balance}("");
    }
}
