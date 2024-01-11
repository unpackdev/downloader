// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./StakeBaseUpgradeable.sol";
import "./IERC721Receiver.sol";

/**
@title Bibiz Upgradeable Staking Contract
@author @KfishNFT
@notice Based on the Habibiz upgradeable staking contract using UUPSUpgradeable Proxy
*/
contract BibizStakeUpgradeable is StakeBaseUpgradeable, IERC721Receiver {
    /**
    @notice Initializer function
    @param stakingContract_ The contract that Bibiz will be staked in
    @param tokenContract_ The Bibiz contract
    @param oilContract_ The $OIL contract
    */
    function initialize(
        address stakingContract_,
        address tokenContract_,
        address oilContract_
    ) public initializer {
        address _stakingContract = stakingContract_ == address(0) ? address(this) : stakingContract_;
        __StakeBaseUpgradeable_init(_stakingContract, tokenContract_, oilContract_);
    }

    /**
    @notice List of tokenIds staked by an address
    @param owner_ The owner of the tokens
    @return Array of tokenIds
    */
    function tokensOf(address owner_) external view returns (uint256[] memory) {
        return tokensOfOwner[owner_];
    }

    /**
    @notice Find the owner of a staked token
    @param tokenId_ The token's id
    @return Address of owner
    */
    function ownerOf(uint256 tokenId_) external view returns (address) {
        return tokenOwner[tokenId_];
    }

    /**
    @notice Retrieve timestamps of when tokens were staked
    @param tokenIds_ The token ids to retrieve staked timestamps for
    @return Array of timestamps
    */
    function stakedTimeOf(uint256[] calldata tokenIds_) external view returns (uint256[] memory) {
        uint256[] memory stakedTimes = new uint256[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            stakedTimes[i] = tokenStakedTime[tokenIds_[i]];
        }
        return stakedTimes;
    }

    /**
    @notice Retrieve the time a token has been staked in seconds
    @param tokenIds_ The token ids to retrieve seconds staked for
    @return Array of seconds staked
    */
    function secondsStakedOf(uint256[] calldata tokenIds_) external view returns (uint256[] memory) {
        uint256[] memory secondsStaked = new uint256[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            secondsStaked[i] = block.timestamp - tokenStakedTime[tokenIds_[i]];
        }
        return secondsStaked;
    }

    /**
    @notice IERC721Receiver implementation in order to allow transfers to the contract
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
