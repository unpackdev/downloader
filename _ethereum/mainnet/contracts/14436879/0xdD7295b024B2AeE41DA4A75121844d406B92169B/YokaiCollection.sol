// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
ooooo  oooo ooooooo  oooo   oooo      o      ooooo
  888  88 o888   888o 888  o88       888      888
    888   888     888 888888        8  88     888
    888   888o   o888 888  88o     8oooo88    888
   o888o    88ooo88  o888o o888o o88o  o888o o888o
*/


import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";

contract YokaiCollection is ERC1155Supply, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256[] public tokens = [4000];
    uint256[] public tokenPrice = [888 ether];

    bool public paused = true;

    address public yohContract;

    constructor() ERC1155("") {
      yohContract = 0x88a07dE49B1E97FdfeaCF76b42463453d48C17cD;
    }

    function mintAsOwner(uint256 id, uint256 amount) external onlyOwner{
      require(id <= tokens.length && id > 0, "YokaiCollection::mint: Token does not exist");
      _mint(msg.sender, id, amount, "");
    }

    function addNewToken(uint256 amount, uint256 price) external onlyOwner {
      tokens.push(amount);
      tokenPrice.push(price);
    }

    function setYohContract(address _yohContract) external onlyOwner {
      yohContract = _yohContract;
    }

    function setURI(string memory newuri) external onlyOwner {
      _setURI(newuri);
    }

    function withdrawBalance() external onlyOwner {
      uint256 currentBalance = IYohToken(yohContract).balanceOf(address(this));
      IYohToken(yohContract).transfer(msg.sender, currentBalance);
    }

    function setPaused(bool _paused) external onlyOwner {
      paused = _paused;
    }

    function mint(address account, uint256 id, uint256 amount) external {
      require(paused == false, "YokaiCollection::mint: Cannot mint when paused");
      require(!account.isContract(), "YokaiCollection::mint: Cannot mint as contract");
      require(id <= tokens.length && id > 0, "YokaiCollection::mint: Token does not exist");

      uint256 totSupply = totalSupply(id);
      uint256 maxSupply = tokens[id - 1];
      require(totSupply < maxSupply, "YokaiCollection::mint: Token minted out");

      //amount = totSupply.sub(maxSupply);
      if(totSupply.add(amount) > maxSupply)
        amount = maxSupply.sub(totSupply);


      uint256 totalPaid = amount.mul(tokenPrice[id - 1]);

      require(IYohToken(yohContract).transferFrom(msg.sender, address(this), totalPaid), "YokaiCollection::mint: Not enough yoh?");

      _mint(account, id, amount, "");
    }

}


interface IYohToken {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external returns (uint256);
}
