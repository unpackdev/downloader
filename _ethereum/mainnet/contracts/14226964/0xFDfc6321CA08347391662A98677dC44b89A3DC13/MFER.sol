// SPDX-License-Identifier: UNLICENSED


/***

███╗░░░███╗███████╗███████╗██████╗░░██████╗  ██████╗░░█████╗░░█████╗░██╗░░██╗██╗
████╗░████║██╔════╝██╔════╝██╔══██╗██╔════╝  ██╔══██╗██╔══██╗██╔══██╗██║░██╔╝██║
██╔████╔██║█████╗░░█████╗░░██████╔╝╚█████╗░  ██████╔╝██║░░██║██║░░╚═╝█████═╝░██║
██║╚██╔╝██║██╔══╝░░██╔══╝░░██╔══██╗░╚═══██╗  ██╔══██╗██║░░██║██║░░██╗██╔═██╗░╚═╝
██║░╚═╝░██║██║░░░░░███████╗██║░░██║██████╔╝  ██║░░██║╚█████╔╝╚█████╔╝██║░╚██╗██╗
╚═╝░░░░░╚═╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░  ╚═╝░░╚═╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚═╝
***/

pragma solidity 0.8.6;

import "./ERC20.sol";
import "./IERC721.sol";

contract MFER is ERC20 {

    mapping (uint256 => bool) public claimed;
    address public mferContract = 0x79FCDEF22feeD20eDDacbB2587640e45491b757f;
    uint256 public mferBase = 100000e18; // each mfer can claim 80% of this

    constructor() ERC20("MFER", "MFER") {
        uint256 nftSupply = 10021;
        uint256 initialSupply = nftSupply * mferBase;
        _mint(address(this), initialSupply * 80 / 100);
        _mint(msg.sender, initialSupply * 20 / 100);
    }

    function claim(uint256 mfer) external {
      require(!claimed[mfer], "You already claimed, mfer!");
      require(IERC721(mferContract).ownerOf(mfer) == msg.sender, "You don't own this, mfer!");
      claimed[mfer] = true;
      transfer(msg.sender, mferBase * 80 / 100);
    }
}
