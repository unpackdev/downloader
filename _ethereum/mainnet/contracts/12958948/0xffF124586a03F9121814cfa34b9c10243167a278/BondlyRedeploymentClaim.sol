// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";


contract BondlyRedeploymentClaim is Ownable{
  using Address for address;

  event AddClaim(address indexed _address, uint256 _claim);
  event BatchAddClaim(address[] _addresses, uint256[] _claims);
  event RemoveClaim(address indexed _address, uint256 _claim);
  event BatchRemoveClaim(address[] _addresses, uint256[] _claims);
  event WithdrawClaim(address indexed _address, uint256 _claim);

  mapping(address => uint256) public claims;

  address public distributorAddress;
  address public bondlyAddress;

  constructor(address _distributorAddress, address _bondlyAddress){
    distributorAddress = _distributorAddress;
    bondlyAddress = _bondlyAddress;
  }

  function claim() external{
    address addr = msg.sender;
    IERC20 bondly = IERC20(bondlyAddress);
    uint256 claimAmount = claims[addr];
    require(bondly.allowance(distributorAddress, address(this)) >= claimAmount, "Distributor allowance too low, contact Bondly");
    require(bondly.balanceOf(distributorAddress) >= claimAmount, "Distributor out of funds, contact Bondly");
    claims[addr] = 0;
    bondly.transferFrom(distributorAddress, addr, claimAmount);
    emit WithdrawClaim(addr,claims[addr]);
  }

  function addClaim(address addr, uint256 claimAmount) external onlyOwner{
    claims[addr] += claimAmount;
    emit AddClaim(addr,claimAmount);
  }

  function batchAddClaim(address[] calldata addrs, uint256[] calldata claimAmounts) external onlyOwner{
    require(addrs.length == claimAmounts.length, "Input arrays length mismatch");
    
    for(uint256 i = 0; i < addrs.length; i++){
      claims[addrs[i]] += claimAmounts[i];
    }
    emit BatchAddClaim(addrs,claimAmounts);
  }

  function removeClaim(address addr, uint256 claimAmount) external onlyOwner{
    claims[addr] -= claimAmount;
    emit RemoveClaim(addr, claimAmount);
  }

  function batchRemoveClaim(address[] calldata addrs, uint256[] calldata claimAmounts) external onlyOwner{
    require(addrs.length == claimAmounts.length, "Input arrays length mismatch");
    
    for(uint256 i = 0; i < addrs.length; i++){
      claims[addrs[i]] -= claimAmounts[i];
    }
    emit BatchRemoveClaim(addrs,claimAmounts);
  }

  function setDistributor(address addr) external onlyOwner{
    distributorAddress = addr;
  }

}
