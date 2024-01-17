/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract AlgerSale is Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    uint256 public SaleStartTime = 1666972800; // 10/28 16:00 GMT
    uint256 public salePrice = 0.2 ether;

    address public whiteListAddress;
    mapping(address => bool) public addressPurchased; 

    constructor() {
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */
    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(tx.origin == msg.sender, "contract not allowed");
        require(block.timestamp > SaleStartTime, "Sale hasn't started");
        require(numberOfTokens == 1, "numberOfTokens can only be 1");
        require(addressPurchased[msg.sender] != true, "Each user can only be mint once");
        require (msg.sender == whiteListAddress, "not in the white list");
        require(msg.value >= numberOfTokens * salePrice, "send value incorrect");
        
        addressPurchased[msg.sender] = true;
    }


    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setSaleData(
        uint256 _saleStartTime,
        uint256 _salePrice
    ) external onlyOwner {
        SaleStartTime = _saleStartTime;
        salePrice = _salePrice;
    }

    function setWhiteListAddress(
        address _whiteListAddress
    ) external onlyOwner {
        whiteListAddress = _whiteListAddress;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "sent value failed");
    }
}