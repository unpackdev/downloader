// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

contract EthcreaturesGen2 {
    error MintNotOpened();
    error MintClosed();
    error NotEnoughEther();
    error NotDeployer();

    address public projectCreator = msg.sender;

    // esip3StartBlock 18130000, esip3EndBlock 18137200
    // genesis start   18135000, genesis end   18140000
    uint256 public constant mintOpenBlock = 18144000;
    uint256 public constant mintCloseBlock = 18160000; // ~53 hours, 16000 blocks

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );

    function ethscribe(string memory dataURI) public payable {
        if (block.number < mintOpenBlock) {
            revert MintNotOpened();
        }
        if (block.number > mintCloseBlock) {
            revert MintClosed();
        }
        if (msg.sender != address(projectCreator) && msg.value < 0.001 ether) {
            revert NotEnoughEther();
        }

        emit ethscriptions_protocol_CreateEthscription(msg.sender, string(abi.encodePacked(dataURI)));
    }

    function withdraw(uint256 amount, address to) public {
        if (msg.sender != projectCreator) {
            revert NotDeployer();
        }

        payable(to).transfer(amount == 0 ? address(this).balance : amount);
    }
}
