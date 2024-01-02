// SPDX-License-Identifier: MIT
// File: /contracts/EYEToken.sol
pragma solidity 0.8.9;
import "./ERC20.sol";

/// @title EYE Smart Chain Token - ERC20 implementation
/// @notice Simple implementation of a {ERC20} token to be used as
// EYE Smart Chain Token (ESC)
contract ESCToken is ERC20 {

    /**
    * @dev  Allocation to each channel
    */
    constructor(address Airdrop,
                address LPDividends,
                address MarketMakers,
                address GameOperations,
                address Foundation,
                address CommunityRewards,
                address LiquidityMining,
                address PrivateSale) ERC20('ESC Token', 'ESC'){
        _mint(Airdrop, 3500000 * 10 ** decimals());
        _mint(LPDividends, 2500000 * 10 ** decimals());
        _mint(MarketMakers, 2500000 * 10 ** decimals());
        _mint(GameOperations, 19000000 * 10 ** decimals());
        _mint(Foundation, 4000000 * 10 ** decimals());
        _mint(CommunityRewards, 3000000 * 10 ** decimals());
        _mint(LiquidityMining, 135000000 * 10 ** decimals());
        _mint(PrivateSale, 20000000 * 10 ** decimals());
    }
}
