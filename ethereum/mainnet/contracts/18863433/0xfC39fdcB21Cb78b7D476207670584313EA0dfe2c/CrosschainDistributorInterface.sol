// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
contract CrosschainDistributorInterface {

    address public minter;
    address public voter;
    address public solidBridge; // The SOLID Bridge contract
    address public nftBridge; // The Solidly NFT Bridge contract
    address public base; // Solid
    mapping (uint256 => uint256) public periodEmissions; // period -> totalEmissions
    mapping (uint256 => uint256) public accruedEmissions; // chainId -> accruedEmissions 
    //mapping (uint256 => mapping(uint256 => bool)) public updated; // ActivePeriod -> ChainId -> updated?

    event KickedEmissions(uint256 indexed chainId, uint256 indexed activePeriod, uint256 amount);

    function initialize(
        address _base,
        address _voter,
        address _solidBridge,
        address _nftBridge,  
        address _minter
    ) public {}

    // Called by voter, allocates peroiod solid by chain nft balances.
    function notifyRewardAmount(address _token, uint256 _amount) external {}

    //function kickAll(uint256[][] calldata _feeInEther) external payable {}
  
    // Helper to kick multiple chains at once
    function kickMultiple(uint256[] calldata _chainIds, uint256[][] calldata _feeInEther) external payable {}

    // Kick down solid rewards to child chain reward distributor
    function kick(uint256 _chainId, uint256[] calldata _feeInEther) external payable {}
    
    function setSolidBridge(address _solidBridge) external {}

    function setNftBridge(address _nftBridge) external {}
}