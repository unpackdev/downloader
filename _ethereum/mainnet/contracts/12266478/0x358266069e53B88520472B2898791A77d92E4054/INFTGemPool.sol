// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface INFTGemPool {

    /**
     * @dev Event generated when an NFT claim is created using ETH
     */
    event NFTGemClaimCreated(address account, address pool, uint256 claimHash, uint256 length, uint256 quantity, uint256 amountPaid);

    /**
     * @dev Event generated when an NFT claim is created using ERC20 tokens
     */
    event NFTGemERC20ClaimCreated(
        address account,
        address pool,
        uint256 claimHash,
        uint256 length,
        address token,
        uint256 quantity,
        uint256 conversionRate
    );

    /**
     * @dev Event generated when an NFT claim is redeemed
     */
    event NFTGemClaimRedeemed(
        address account,
        address pool,
        uint256 claimHash,
        uint256 amountPaid,
        uint256 feeAssessed
    );

    /**
     * @dev Event generated when an NFT claim is redeemed
     */
    event NFTGemERC20ClaimRedeemed(
        address account,
        address pool,
        uint256 claimHash,
        address token,
        uint256 ethPrice,
        uint256 tokenAmount,
        uint256 feeAssessed
    );

    /**
     * @dev Event generated when a gem is created
     */
    event NFTGemCreated(address account, address pool, uint256 claimHash, uint256 gemHash, uint256 quantity);

    function setMultiToken(address token) external;

    function setGovernor(address addr) external;

    function setFeeTracker(address addr) external;

    function setSwapHelper(address addr) external;

    function mintGenesisGems(address creator, address funder) external;

    function createClaim(uint256 timeframe) external payable;

    function createClaims(uint256 timeframe, uint256 count) external payable;

    function createERC20Claim(address erc20token, uint256 tokenAmount) external;

    function createERC20Claims(address erc20token, uint256 tokenAmount, uint256 count) external;

    function collectClaim(uint256 claimHash) external;

    function initialize(
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external;
}
