//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

    Planktoons market contract
      https://planktoons.io

*/

import "./MerkleMarket.sol";
import "./MerkleAirdrop.sol";
import "./NFTStaking.sol";
import "./IERC721.sol";

contract PlanktoonsMarket is MerkleMarket {
    // ---
    // Errors
    // ---

    /// @notice A purchase was attempted by an account that does not own or have
    /// any staked Planktoons NFTs
    error NotAHolder();

    // ---
    // Storage
    // ---

    string public constant name = "PlanktoonsMarket";

    /// @notice The Planktoons nft contract
    IERC721 public immutable nft;

    /// @notice The Planktoons staking contract.
    NFTStaking public immutable staking;

    /// @notice The Planktoons airdrop contract.
    MerkleAirdrop public immutable airdrop;

    constructor(
        IERC721 nft_,
        NFTStaking staking_,
        MerkleAirdrop airdrop_
    ) {
        nft = nft_;
        staking = staking_;
        airdrop = airdrop_;
    }

    // ---
    // End user functionality
    // ---

    /// @notice Purchase items from the marketplace
    function purchase(Order[] calldata orders) public virtual override {
        _assertHasNfts();
        return MerkleMarket.purchase(orders);
    }

    /// @notice Convenience function to claim from airdrop and staking contracts
    /// before purchasing from the market to save holders a few transactions.
    function claimAllAndPurchase(
        Order[] calldata orders,
        uint256 airdropMaxClaimable,
        bytes32[] calldata airdropProof
    ) external {
        _assertHasNfts();

        // if nothing staked, nop is safe
        staking.claimFor(msg.sender);

        // only attempt airdrop claim if > 0, allows skipping by setting max
        // claimable to 0 and passing in an empty array as proof
        if (airdropMaxClaimable > 0) {
            airdrop.claimFor(msg.sender, airdropMaxClaimable, airdropProof);
        }

        purchase(orders);
    }

    function _assertHasNfts() internal view {
        uint256 owned = nft.balanceOf(msg.sender) +
            staking.getStakedBalance(msg.sender);
        if (owned == 0) {
            revert NotAHolder();
        }
    }
}
