pragma solidity ^0.8.9 <0.9.0;

import "./EthMonkeys.sol";
import "./Ownable.sol";


interface IERC721F is IERC721{
     function adminMint(address to, uint256 numberOfTokens) external;
     function transferOwnership(address newOwner) external;
}   

contract ETHMMinter is Ownable {
    mapping(address => bool) public hasClaimed;
    bool public freeMintActive ;
    IERC721F public monkeyContr;

    address private constant DEV = 0x11145Fc22221d317784BD5Fdc5dd429354aa0D9C;

      constructor() {
          monkeyContr = IERC721F(0xd67aAAa0aa436BAAd3EAd3Feebd00E19622419A0);
    }

    function mint(uint256 numberOfTokens) external payable {
          require(freeMintActive, "freeMint is not active yet");
          require(numberOfTokens > 0, "Atleast 1 token");

          if (hasClaimed[msg.sender]) {
                 require(((numberOfTokens) * 0.005 ether) <= msg.value, "Not enough ether");
          } else {
              require(((numberOfTokens  * 0.005 ether) - 0.005 ether) <= msg.value, "Not enough ether");
              hasClaimed[msg.sender] = true;
          }
          
          monkeyContr.adminMint(msg.sender, numberOfTokens);
          
    }

    function flipFreeMintActive() external onlyOwner {
        freeMintActive = !freeMintActive;
    }

    function transferMonkeyOwnership(address newOwner) external onlyOwner {
        monkeyContr.transferOwnership(newOwner);
    }

    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    // contract can recieve Ether
    receive() external payable { }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(DEV,(balance * 10) / 100);
        _withdraw(0x5409CfdF149d8BA163a58B25901C050d4DF8A122, (balance * 45) / 100);
        _withdraw(0x0b1B7DaAAD3912DDC1534f88ABE04679C51679c0, (balance * 45) / 100);
    }
}