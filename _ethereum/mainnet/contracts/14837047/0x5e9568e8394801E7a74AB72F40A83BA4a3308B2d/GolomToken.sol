// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @title Golom ERC20 governance token
/// @notice Explain to an end user what this does
/// @dev Implements ERC20, ERC20Votes and ERC20Permits from OpenZepellin

// Tokens are minted on the initial mint
// Additionally mint function is called to mint the tokens, only the reward distributor contract will be able to mint the token

import "./Ownable.sol";
import "./ERC20Votes.sol";

contract GolomToken is ERC20Votes, Ownable {
    address public minter;

    uint256 public minterEnableDate;
    address public pendingMinter;

    bool public isAirdropMinted;
    bool public isGenesisRewardMinted;

    modifier onlyMinter() {
        require(msg.sender == minter, 'GolomToken: only reward distributor can enable');
        _;
    }

    constructor(address _governance) ERC20('Golom', 'GOL') ERC20Permit('Golom') {
        _transferOwnership(_governance); // set the new owner
    }

    /// @notice Mints the tokens
    /// @dev only minter can mint the tokens, minter will be RewardDistributor.sol
    /// @param _account Address where the tokens will be minted
    /// @param _amount Number of tokens to be minted
    function mint(address _account, uint256 _amount) external onlyMinter {
        _mint(_account, _amount);
    }

    /// @notice Mints 150M for the airdrop
    /// @param _airdrop Airdrop contract
    function mintAirdrop(address _airdrop) external onlyOwner {
        require(!isAirdropMinted, 'already minted');
        _mint(_airdrop, 150_000_000 * 1e18);
        isAirdropMinted = true;
    }

    /// @notice Mint Genesis Reward
    /// @param _rewardDistributor Address of the rewardDistributor
    function mintGenesisReward(address _rewardDistributor) external onlyOwner {
        require(!isGenesisRewardMinted, 'already minted');
        _mint(_rewardDistributor, 50_000_000 * 1e18);
        isGenesisRewardMinted = true;
    }

    /// @notice sets the minter with timelock, once setup admin needs to call executeSetMinter()
    /// @param _minter Address of the new minter
    function setMinter(address _minter) external onlyOwner {
        pendingMinter = _minter;
        minterEnableDate = block.timestamp + 1 days;
    }

    /// @notice Executes the set minter function after the timelock
    /// @dev If being called first time, there won't be any timelock
    function executeSetMinter() external onlyOwner {
        if (minter == address(0)) {
            minter = pendingMinter;
        } else {
            require(minterEnableDate <= block.timestamp, 'GolomToken: wait for timelock');
            minter = pendingMinter;
        }
    }
}
