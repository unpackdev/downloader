// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";

interface IBadBoysWeb3 {
    function publicMint(uint amount, address recipient) external payable;
    function mintPrice() external view returns (uint256);
}

contract BadBoysMinter is AccessControl {
    IBadBoysWeb3 public badBoysContract;
    address public crossmintAddress;

    constructor(address _badBoysAddress) {
        badBoysContract = IBadBoysWeb3(_badBoysAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setCrossmintAddress(address _crossmintAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        crossmintAddress = _crossmintAddress;
    }

    function crossmintMint(uint amount, address recipient) public payable {
        require(msg.sender == crossmintAddress, "Caller is not Crossmint");
        
        uint256 totalMintAmount = calculateTotalMintAmount(amount);
        require(msg.value == 0, "Crossmint should not send ETH");
        
        badBoysContract.publicMint{value: msg.value}(totalMintAmount, recipient);
    }

    function publicMint(uint amount, address recipient) public payable {
        uint256 currentPrice = badBoysContract.mintPrice();
        uint256 totalMintAmount = calculateTotalMintAmount(amount);

        require(msg.value >= amount * currentPrice, "Insufficient ETH sent");

        badBoysContract.publicMint{value: msg.value}(totalMintAmount, recipient);
    }

    function calculateTotalMintAmount(uint256 amount) public pure returns (uint256) {
        uint256 freeMints = amount / 2;
        return amount + freeMints;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

}
