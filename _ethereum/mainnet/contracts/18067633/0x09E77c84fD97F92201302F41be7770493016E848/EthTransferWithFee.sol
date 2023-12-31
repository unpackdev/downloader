// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Interface for the ERC721 contract
interface ERC721 {
    function balanceOf(address owner) external view returns (uint256);
}
contract EthTransferWithFee {

    // address payable public receiver;
    address payable public owner;
    uint256 public feePercentage = 10;
    uint256 public groupFeePercentage = 10;
    ERC721 erc721;


    // Event for logging transfer details
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fee
    );


    constructor(address contractAddress) {
        owner = payable(msg.sender);
        erc721 = ERC721(contractAddress);
    }

    function getOwner() public view returns (address) {
    return owner;
    }


    function updateNFTContractAddress(address _newContract) external onlyOwner {
        erc721 = ERC721(_newContract);
    }


    function getERC721Balance(address user) public view returns (bool) {
        return erc721.balanceOf(user) > 0;
    }

    function singleTransfer(address payable receiver) external payable {
        require(msg.value > 0, "Invalid amount");
        if (getERC721Balance(msg.sender)) {
            emit Transfer(msg.sender, receiver, msg.value, 0);
            (bool withoutFee, ) = receiver.call{value: msg.value}("");
            require(withoutFee, "Transfer to receiver failed");
            return;
        }
        uint256 feeAmount = (msg.value * feePercentage) / 100;
        uint256 transferAmount = msg.value - feeAmount;
        // Emit event
        emit Transfer(msg.sender, receiver, transferAmount, feeAmount);
        // Transfer ETH to receiver
        (bool success, ) = receiver.call{value: transferAmount}("");
        require(success, "Transfer to receiver failed");
        // Transfer fee to contract owner
        (success, ) = owner.call{value: feeAmount}("");
        require(success, "Transfer of fee failed");
    }


    // Function to receive Ether and apply fee
    function transferWithFee(
        address payable receiver,
        uint256 amount
    ) internal {
        require(amount > 0, "Invalid amount");
        if (getERC721Balance(msg.sender)) {
            (bool withoutFee, ) = receiver.call{value: amount}("");
            require(withoutFee, "Transfer to receiver failed");
            emit Transfer(msg.sender, receiver, amount, 0);
            return;
        }
        uint256 feeAmount = (amount * groupFeePercentage) / 100;
        uint256 transferAmount = amount - feeAmount;
        // Transfer ETH to receiver
        (bool success, ) = receiver.call{value: transferAmount}("");
        require(success, "Transfer to receiver failed");
        // Transfer fee to contract owner
        (success, ) = owner.call{value: feeAmount}("");
        require(success, "Transfer of fee failed");
        // Emit event
        emit Transfer(msg.sender, receiver, transferAmount, feeAmount);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can change");
        _;
    }


    // Function to change the receiver address
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }


    // Function to change the fee percentage
    function changeFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Invalid fee percentage");
        feePercentage = _newFeePercentage;
    }


    function changeGroupFeePercentage(
        uint256 _newGroupFeePercentage
    ) external onlyOwner {
        require(_newGroupFeePercentage <= 100, "Invalid fee percentage");
        groupFeePercentage = _newGroupFeePercentage;
    }


    function groupTransferWithSeperateAmount(
        address payable[] memory recipients,
        uint256[] memory amounts
    ) external payable {
        require(
            msg.value == getTotalAmount(amounts),
            "Incorrect ETH value sent"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            transferWithFee(recipients[i], amounts[i]);
        }
    }


    function groupTransferWithSameAmount(
        address payable[] memory recipients
    ) external payable {
        require(msg.value > 0, "Invalid amount");
        uint256 splitAmount = msg.value / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            transferWithFee(recipients[i], splitAmount);
        }
    }


    function getTotalAmount(
        uint256[] memory amounts
    ) private pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }
}