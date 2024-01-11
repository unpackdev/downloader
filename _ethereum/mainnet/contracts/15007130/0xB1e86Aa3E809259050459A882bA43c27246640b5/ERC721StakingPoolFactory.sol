// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import "./ERC721.sol";

import "./Ownable.sol";

import "./ERC721StakingPool.sol";
import "./ClonesWithCallData.sol";

/// @title StakingPoolFactory
/// @author zefram.eth
/// @notice Factory for deploying ERC20StakingPool and ERC721StakingPool contracts cheaply
contract ERC721StakingPoolFactory is Ownable {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using ClonesWithCallData for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event CreateERC721StakingPool(ERC721StakingPool stakingPool);

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The contract used as the template for all ERC721StakingPool contracts created
    ERC721StakingPool public immutable erc721StakingPoolImplementation;

    /// maintain a mapping stakeToken contract => staking contract
    mapping(ERC721 => ERC721StakingPool) public erc721StakingContractMap;

    constructor(ERC721StakingPool erc721StakingPoolImplementation_) {
        erc721StakingPoolImplementation = erc721StakingPoolImplementation_;
    }

    /// @notice Creates an ERC721StakingPool contract
    /// @dev Uses a modified minimal proxy contract that stores immutable parameters in code and
    /// passes them in through calldata. See ClonesWithCallData.
    /// @param rewardToken The token being rewarded to stakers
    /// @param stakeToken The token being staked in the pool
    /// @param DURATION The length of each reward period, in seconds
    /// @return stakingPool The created ERC721StakingPool contract
    function createERC721StakingPool(
        address rewardToken,
        ERC721 stakeToken,
        uint64 DURATION
    ) external onlyOwner returns (ERC721StakingPool stakingPool) {
        bytes memory ptr;
        ptr = new bytes(48);
        assembly {
            mstore(add(ptr, 0x20), shl(0x60, rewardToken))
            mstore(add(ptr, 0x34), shl(0x60, stakeToken))
            mstore(add(ptr, 0x48), shl(0xc0, DURATION))
        }

        stakingPool = ERC721StakingPool(address(erc721StakingPoolImplementation).cloneWithCallDataProvision(ptr));
        stakingPool.initialize(msg.sender);
        erc721StakingContractMap[stakeToken] = stakingPool;

        emit CreateERC721StakingPool(stakingPool);
    }
}
