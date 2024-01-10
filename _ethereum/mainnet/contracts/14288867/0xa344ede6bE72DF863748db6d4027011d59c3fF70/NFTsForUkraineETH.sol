// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC1155.sol";

contract NFTsForUkraine is ERC1155, Ownable {

    uint256 public minimumDonation;
    bool public donationActive;
    address public beneficiary;

    constructor() ERC1155("NFTs For Ukraine") {
        minimumDonation = 0.04 ether;
        donationActive = false;
        beneficiary = 0xf2ff66656200cc0C2e29a311B3EA731549033F87;
    }

    fallback() external payable {}

    receive() external payable {}

    function mint()
        public
        payable
    {
        require(msg.value >= minimumDonation, "mint: Must donate at least 0.04 ether");
        require(donationActive, "mint: Donation must be active");
        _mint(msg.sender, 1, 1, "");
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(balance>0, "withdraw: no balance");
        require(payable(beneficiary).send(balance));
    }

    function toggleDonationActive() public onlyOwner() {
        donationActive = !donationActive;
    }

    function setURI(string memory newuri) public onlyOwner() {
        _setURI(newuri);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

