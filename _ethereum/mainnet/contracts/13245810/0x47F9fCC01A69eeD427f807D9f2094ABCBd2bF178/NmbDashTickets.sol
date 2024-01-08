// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC1155Supply.sol";

interface ICamel {
    function balanceOf(address wallet) external view returns (uint256);
}

contract NmbDashTickets is Ownable, ERC1155Supply {
  using SafeMath for uint256;
  using Strings for uint256;

  ICamel public camelContract;

  uint256 public currentSeason = 1;
  uint256 public currentTicketPrice = 0.015 ether;
  uint256 public currentTicketLimit = 216;
  bool public saleActive = false;

  string private _imageURI;
  address private _withdrawalAddress;

  constructor(
    string memory imageURI,
    address withdrawalAddress,
    address camelContractAddress
  ) ERC1155("") {
    _imageURI = imageURI;
    _withdrawalAddress = withdrawalAddress;
    camelContract = ICamel(camelContractAddress);
  }

  function buyTickets(uint256 amount) public payable {
    require(saleActive, "Sale is not active");
    require(msg.value >= currentTicketPrice.mul(amount), "Insufficient payment");
    require(totalSupply(currentSeason) + amount <= currentTicketLimit, "Not enough tickets left");
    require(camelContract.balanceOf(msg.sender) >= (amount + balanceOf(msg.sender, currentSeason)), "Don't own enough camels");

    _mint(msg.sender, currentSeason, amount, "");
  }

  function startNewSeason() external onlyOwner {
    currentSeason += 1;
  }

  function setTicketPrice(uint newPrice) external onlyOwner {
    currentTicketPrice = newPrice;
  }

  function setTicketLimit(uint newLimit) external onlyOwner {
    currentTicketLimit = newLimit;
  }

  function toggleSaleActive() external onlyOwner {
    saleActive = !saleActive;
  }

  function updateImageURI(string memory newImageURI) external onlyOwner {
    _imageURI = newImageURI;
  }

  function updateWithdrawalAddress(address newAddress) external onlyOwner {
    _withdrawalAddress = newAddress;
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw.");
    
    (bool success, ) = _withdrawalAddress.call{value: address(this).balance}("");
    require(success, "Withdrawal failed.");
  }

  function uri(uint256 season)
    public
    view                
    override
    returns (string memory)
  {
    require(season > 0 && season <= currentSeason, "URI requested for invalid racing season");

    string memory json = string(abi.encodePacked('{"name": "NMB Dash Race Ticket - Season ', season.toString(), '", "description": "NMB Dash will have Arabian Camels, the Monsters Rehab gang, and Baby Camels teaming up to race to the podium. On your marks racers...", "image": "', _imageURI, '"}'));
    
    string memory output = string(abi.encodePacked('data:application/json;utf8,', json));

    return output;
  }
}