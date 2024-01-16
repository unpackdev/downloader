// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IAirdrop.sol";
import "./IForgeV1.sol";

// This contract is a migration contract to move contributor assets from claimable airdop contract to the new forges
contract RolloverForgeV1 is AccessControl {
    bytes32 public constant ROLLOVER_ADMIN = keccak256(abi.encode("ROLLOVER_ADMIN"));

    event RolledOver(address indexed contributor, address indexed forge, uint256 indexed forgeId, uint256 amount);
        
    constructor() {
        _setupRole(ROLLOVER_ADMIN, msg.sender);
    }

    // internal functions
    function getContributionToken(address forge, uint256 forgeId) internal view returns (address) {
        address forgeToken;
        (,forgeToken,,,,,,,,,) = IForgeV1(forge).forgeInfo(forgeId);
        return forgeToken;
    }
    
    function validateInput(address claimContract, address forge, uint256 forgeId) 
      internal view 
      returns (address contributionToken) 
    {
        require(claimContract != address(0) && forge != address(0), 'ERR_ADDRESS_ZERO');
        address claimToken = IAirdrop(claimContract).sdaoToken();
        address forgeToken = getContributionToken(forge, forgeId);
        require(claimToken == forgeToken, 'ERR_CONTRIBUTION_TOKEN');
        contributionToken = claimToken;
    }
    
    function createBatchToProcess(address claimContract, address[] calldata contributors, uint256 batchSize) 
        internal view
        returns (address[] memory batchContributors, 
                 uint256[] memory batchAmounts, 
                 uint256 amountToWithdraw, 
                 uint256 batchIndex)
    {
        batchContributors = new address[](batchSize);
        batchAmounts = new uint256[](batchSize);
        amountToWithdraw = 0;
        batchIndex = 0;
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            require(contributor != address(0), 'ERR_CONTRIBUTOR_ZERO');
            uint256 amountToBeRolledOver = IAirdrop(claimContract).airdropUsers(contributor);
            if (amountToBeRolledOver > 0) {
                batchContributors[batchIndex] = contributor;
                batchAmounts[batchIndex] = amountToBeRolledOver;
                amountToWithdraw += amountToBeRolledOver;
                batchIndex++;
                if (batchIndex == batchSize) break;
            }
        }
    }
    
    function withdrawContributionTokens(address claimContract, address forge, 
                                        address contributionToken, uint256 amountToWithdraw) internal 
    {
        uint256 claimContractBalance = IERC20(contributionToken).balanceOf(claimContract);
        require(claimContractBalance >= amountToWithdraw, "ERR_CLAIM_DEFICIT");
        IAirdrop(claimContract).withdrawToken(amountToWithdraw);
        uint256 allowance = IERC20(contributionToken).allowance(address(this), forge);
        if (allowance == 0) {
            IERC20(contributionToken).approve(forge, type(uint256).max);
        }
    }

    function depositContributionTokens(address forge, uint256 forgeId, uint256 nrOfContributors, 
                                       address[] memory batchContributors, uint256[] memory batchAmounts) internal {
        for (uint256 i = 0; i < nrOfContributors; i++) {
            address contributor = batchContributors[i];
            if (contributor == address(0)) break;
            uint256 amountToBeRolledOver = batchAmounts[i];
            IForgeV1(forge).deposit(forgeId, amountToBeRolledOver, contributor);
            emit RolledOver(contributor, forge, forgeId, amountToBeRolledOver);
        }
    }
    
    // external functions
    function rollover(address claimContract, address forge, uint256 forgeId, 
                      address[] calldata contributors, uint256 batchSize) external onlyRole(ROLLOVER_ADMIN)
    {

        // validate input
        address contributionToken = validateInput(claimContract, forge, forgeId);

        // create batch to process
        address[] memory batchContributors;
        uint256[] memory batchAmounts;
        uint256 amountToWithdraw;
        uint256 batchIndex;
        (batchContributors, batchAmounts, amountToWithdraw, batchIndex) 
         = createBatchToProcess(claimContract, contributors, batchSize);

        // withdraw contribution tokens
        if (amountToWithdraw == 0) return;
        withdrawContributionTokens(claimContract, forge, contributionToken, amountToWithdraw);

        // deposit contribution tokens
        depositContributionTokens(forge, forgeId, batchIndex, batchContributors, batchAmounts);

        // Remove rolled over contributions from claim contract
        IAirdrop(claimContract).removeAddresses(batchContributors);
    }

    // governance    
    function transferClaimContractOwnership(address claimContract, address newOwner) external onlyRole(ROLLOVER_ADMIN) {
        require(claimContract != address(0) && newOwner != address(0), 'ERR_ADDRESS_ZERO');
        Ownable(claimContract).transferOwnership(newOwner);
    }

}