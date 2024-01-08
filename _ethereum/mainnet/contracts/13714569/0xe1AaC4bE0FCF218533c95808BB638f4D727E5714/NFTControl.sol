// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";

/**
@title BadgerDAO NFT Control
@author @swoledoteth
@notice NFTControl is the on chain source of truth for the Boost NFT Weights.
The parameter exposed by NFT Control: 
- NFT Weight
@dev All operations must be conducted by an nft control manager.
The deployer is the original manager and can add or remove managers as needed.
*/
contract NFTControl is Ownable {
  event NFTWeightChanged(address indexed _nft, uint256 indexed _id, uint256 indexed _weight, uint256 _timestamp);

  mapping(address => bool) public manager;
  struct NFTWeightSchedule {
   address addr;
   uint256 id;
   uint256 weight;
   uint256 start;
  }

  NFTWeightSchedule[] public nftWeightSchedules;

  modifier onlyManager() {
    require(manager[msg.sender], "!manager");
    _;
  }

  /// @param _manager address to add as manager
  function addManager(address _manager) external onlyOwner {
    manager[_manager] = true;
  }

  /// @param _manager address to remove as manager
  function removeManager(address _manager) external onlyOwner {
    manager[_manager] = false;
  }

  constructor(address _owner) {
    manager[msg.sender] = true;
    // Honeypot 1
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 97, 10 ether, block.timestamp));
    // Honeypot 2
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 98, 10 ether, block.timestamp));
    // Honeypot 3
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 99, 50 ether, block.timestamp));
    // Honeypot 4
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 100, 50 ether, block.timestamp));
    // Honeypot 5
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 101, 500 ether, block.timestamp));
    // Honeypot 6
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 102, 500 ether, block.timestamp));

    // Diamond Hands 1
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 205, 50 ether, block.timestamp));
    // Diamond Hands 2
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 206, 200 ether, block.timestamp));
    // Diamond Hands 3
    nftWeightSchedules.push(NFTWeightSchedule(0xe4605d46Fd0B3f8329d936a8b258D69276cBa264, 206, 1000 ether, block.timestamp));

    // Jersey
    nftWeightSchedules.push(NFTWeightSchedule(0xe1e546e25A5eD890DFf8b8D005537c0d373497F8, 1, 200 ether, block.timestamp));

    manager[_owner] = true;

    transferOwnership(_owner);
    
  }



  /// @param _nft address of nft to set weight
  /// @param _id id of nft to set weight
  /// @param _weight weight to set in wei formatr
  /// @param _timestamp timestamp of when to activate nft weight schedule


  function addNftWeightSchedule(address _nft, uint256 _id, uint256 _weight, uint256 _timestamp)
    external
    onlyManager
  {
    NFTWeightSchedule memory nftWeightSchedule = NFTWeightSchedule(_nft, _id, _weight, _timestamp);
    nftWeightSchedules.push(nftWeightSchedule);
    emit NFTWeightChanged(_nft, _id, _weight, _timestamp);
  }
  function getNftWeightSchedules() external view returns(NFTWeightSchedule[] memory) {
    return nftWeightSchedules;
  }

}