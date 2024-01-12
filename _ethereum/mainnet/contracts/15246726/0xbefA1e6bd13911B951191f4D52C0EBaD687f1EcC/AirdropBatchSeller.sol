// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "Ownable.sol";
import "ISimpleAirdropper.sol";
import "IArrayAirdropper.sol";

contract AirdropBatchSeller is Ownable {
    address public constant ukraineAddress = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    address internal immutable firstDrop;
    address internal immutable secondDrop;

    uint256 public immutable tokenPrice;

    constructor(address firstDrop_, address secondDrop_, uint256 tokenPrice_) {
        firstDrop = firstDrop_;
        secondDrop = secondDrop_;
        tokenPrice = tokenPrice_;
    }

    modifier enoughETH(uint256 amount) {
        require(msg.value >= amount * tokenPrice, "Not enough ETH");
        _;
    }

    function returnOwnerships() external onlyOwner {
        if(Ownable(firstDrop).owner() == address(this)) Ownable(firstDrop).transferOwnership(owner());
        if(Ownable(secondDrop).owner() == address(this)) Ownable(secondDrop).transferOwnership(owner());
    }

    function buyFirstDropTokens(uint256 amount) payable external enoughETH(amount) returns (uint256) {
        address[] memory addresses = new address[](1);
        addresses[0] = msg.sender;
        return IArrayAirdropper(firstDrop).airdrop(addresses, amount);
    }

    function buySecondDropTokens(uint256 amount) payable external enoughETH(amount) returns (uint256) {
        return ISimpleAirdropper(secondDrop).airdrop(amount, msg.sender);
    }
}
