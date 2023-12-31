// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

contract Ethcreatures {
    // error MintNotOpened();
    error MintClosed();
    error NotEnoughEther();

    address public projectCreator = msg.sender;
    // uint256 public constant esip3StartBlock = 18130000;
    // uint256 public constant esip3EndBlock   = 18137200; // (24 hours / 12)
    // uint256 public constant mintClose =       18140000;
    // uint256 public constant mintOpen = 18135000; // collection Start Block

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );

    function ethscribe(string memory dataURI) public payable {
        if (block.number > 18140000) {
            revert MintClosed();
        }

        if (msg.value < 0.001 ether) {
            revert NotEnoughEther();
        }

        emit ethscriptions_protocol_CreateEthscription(msg.sender, string(abi.encodePacked(dataURI)));
    }

    function withdraw() public payable {
        payable(projectCreator).transfer(address(this).balance);
    }
}
