// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface RoyaltyRegistrar {
    
    event RoyaltyClaimed(address indexed hostContract, address currency, address owner, uint256 percentage, address token);
    event RoyaltySplit(address hostContract, address currency, address[] addresses, uint256[] weights);
    event NewPercentage(address hostContract, uint256 newPercentage);
    event Withdraw(address recipient, address hostContract, address currency, uint256 amount);
    event RoyaltiesUpdated(address hostContract, address currency, uint256 amount);
    event RoyaltiesDeposited(address hostContract, address currency, uint256 amount);

    function claimRoyaltyForRevoked(address _hostContract, uint256 _percentage, address recipient) external;
    function claimRoyalty(address _hostContract, uint256 _percentage) external;
    function mintRoyaltyToken(address _hostContract, address currency) external;
    function split(address hostContract, address currency, address[] calldata addresses, uint256[] calldata weights) external;
    function setPercentage(address hostContract, uint256 _newPercentage) external;
    function withdraw(address recipient, address hostContract, address currency) external;
    function getRoyaltyPercentage(address _hostContract) external view returns (uint256);
    function depositRoyalties(address hostContract, address currency, uint256 amount) external payable;
    function updateRoyalties(address hostContract, address currency, uint256 amount) external;
    function getRoyaltyBalance(address hostContract, address currency) external view returns(uint256);
    function getRoyaltyBalance(address[] calldata hostContracts, address[] calldata currencies) external view returns(uint256[] memory);
    function getWithdrawn(address hostContract, address currency) external view returns(uint256);
    function getWithdrawn(address[] calldata hostContracts, address[] calldata currencies) external view returns(uint256[] memory);
    function getClaimed(address hostContract) external view returns(address);
    function getHostContractRoyaltyToken(address hostContract, address currency) external view returns(address); 
}