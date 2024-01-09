// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetaLizards.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract Insect is ERC20, Ownable {
  uint256 public INSECT_RATE = 1 ether;
  uint256 public INSECT_RATE_GENESIS = 10 ether;
  uint256 private startTime;
  address private metalizardsAddress;

  mapping (uint => bool) public Genesis;
  mapping(address => uint256) public lastUpdate;

  MetaLizards private metalizardsContract;

  modifier onlyMetaLizardsAddress() {
    require(msg.sender == address(metalizardsContract), "Not metalizards address");
    _;
  }

  constructor() ERC20("Insect", "$INSECT") {
    startTime = 1643590800;
  }

  function updateTokens(address from, address to) external onlyMetaLizardsAddress {
    if (from != address(0)) {
      _mint(from, getPendingTokens(from));
      lastUpdate[from] = block.timestamp;
    }

    if (to != address(0)) {
      _mint(to, getPendingTokens(to));
      lastUpdate[to] = block.timestamp;
    }
  }

  function getPendingTokens(address _user) public view returns (uint256) {
    uint256[] memory ownedMetaLizards = metalizardsContract.walletOfOwner(_user);
    uint lengthOwnedMetaLizards = ownedMetaLizards.length;
    uint genesisPending;
    for (uint256 i = 0; i < ownedMetaLizards.length; i++) {
      if (Genesis[ownedMetaLizards[i]]) {
        genesisPending = ((INSECT_RATE_GENESIS * (
          (block.timestamp -
            (lastUpdate[_user] >= startTime ? lastUpdate[_user] : startTime))
        )) / 86400) + genesisPending;
        lengthOwnedMetaLizards--;
      }
    }
    return
      ((lengthOwnedMetaLizards *
        INSECT_RATE *
        (
          (block.timestamp -
            (lastUpdate[_user] >= startTime ? lastUpdate[_user] : startTime))
        )) / 86400) + genesisPending;
  }

  function claimInsect() external {
    _mint(msg.sender, getPendingTokens(msg.sender));
    lastUpdate[msg.sender] = block.timestamp;
  }

  function giveAway(address _user, uint256 _amount) public onlyOwner {
    _mint(_user, _amount);
  }

  function burn(address _user, uint256 _amount) public onlyMetaLizardsAddress {
    _burn(_user, _amount);
  }

  function setMetaLizardsContract(address _metalizardsAddress) public onlyOwner {
    metalizardsContract = MetaLizards(_metalizardsAddress);
  }

  function setInsectRate(uint _newInsectRate) public onlyOwner {
    INSECT_RATE = _newInsectRate;
  }

  function setInsectRateGenesis(uint _newInsectRateGenesis) public onlyOwner {
    INSECT_RATE_GENESIS = _newInsectRateGenesis;
  }

  function setStartTime(uint _newStartTime) public onlyOwner {
    startTime = _newStartTime;
  }

  function addGenesis(uint[] memory _Genesis) public onlyOwner {
    for (uint256 i = 0; i < _Genesis.length; i++) {
      Genesis[_Genesis[i]] = true;
    }
  }

  function removeGenesis(uint[] memory _Genesis) public onlyOwner {
    for (uint256 i = 0; i < _Genesis.length; i++) {
      Genesis[_Genesis[i]] = true;
    }
  }
}