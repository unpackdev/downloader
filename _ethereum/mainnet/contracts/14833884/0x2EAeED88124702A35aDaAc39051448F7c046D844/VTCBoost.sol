// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./IERC1155.sol";


//██╗░░░██╗████████╗░█████╗░
//██║░░░██║╚══██╔══╝██╔══██╗
//╚██╗░██╔╝░░░██║░░░██║░░╚═╝
//░╚████╔╝░░░░██║░░░██║░░██╗
//░░╚██╔╝░░░░░██║░░░╚█████╔╝
//░░░╚═╝░░░░░░╚═╝░░░░╚════╝░


contract VTCBoost is ERC1155, Ownable {
     uint256 public constant tokenPrice = 1000000000000000000; //1 eth
    
    constructor() ERC1155("") {}
    

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }


    function mint(uint256 id, uint256 amount)
        public
        payable
    {
    require(id == 1,"only one id");
    require(msg.value >= amount * tokenPrice, "Invalid Etherum format");
        _mint(msg.sender, id, amount, "");
    }

    function boostOwner(address _owner)
        external
        view
        returns (uint256[] memory)
      {
        uint256 tokenCount = balanceOf(_owner,1);
        if (tokenCount == 0) {
          return new uint256[](0);
        } else {
        return new uint256[](1);
          }
        }

    function withdraw() public onlyOwner{
        require(address(this).balance > 0, "balance 0");
        payable(owner()).transfer(address(this).balance);
    }
}
