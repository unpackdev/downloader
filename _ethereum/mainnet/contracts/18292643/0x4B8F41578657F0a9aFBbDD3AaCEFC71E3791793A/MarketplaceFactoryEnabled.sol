//SPDX-License-Identifier: MIT
/**
 * @title MarketplaceFactoryEnabled
 * @dev @brougkr
 * note: This Contract Is Used To Enable Marketplace Contracts To Purchase Tokens From Your Contract
 * note: This Contract Should Be Imported and Included In The `is` Portion Of The Contract Declaration, ex. `contract NFT is Ownable, MarketplaceFactoryEnabled`
 * note: You Can Copy Or Modify The Example Functions Below To Implement The Two Functions In Your Contract Required By MarketplaceFactoryEnabled
 */
pragma solidity 0.8.19;
abstract contract MarketplaceFactoryEnabled
{
    /**
     * @dev Marketplace Mint
     * note: Should Be Implemented With onlyMarketplace Access Modifier
     */
    // function _MintToFactory(uint MintPassProjectID, address Recipient, uint Amount) external virtual;
    // EXAMPLE:
    // function _MintToFactory(uint MintPassProjectID, address Recipient, uint Amount) override virtual external onlyMarketplace
    // {
    //     require(totalSupply() + Amount <= 100, "MP: Max Supply Reached");
    //     _mint(MintPassProjectID, Recipient, Amount); 
    // }

    /**
     * @dev Marketplace Factory Simple Mint
     * note: Should Be Implemented With onlyMarketplace Access Modifier
     * note: Should Return The TokenID Being Transferred To The Recipient
     */
    function _MintToFactory(uint MintPassProjectID, address Recipient, uint Amount) external virtual;
    // EXAMPLE:
    // function _MintToFactory(uint MintPassProjectID, address Recipient, uint Amount) override virtual external onlyMarketplace
    // {
    //     require(totalSupply() + Amount <= 100, "MP: Max Supply Reached");
    //     _mint(MintPassProjectID, Recipient, Amount); 
    // }

    /**
     * @dev ChangeMarketplaceAddress Changes The Marketplace Address | note: Should Be Implemented To Include onlyOwner Or Similar Access Modifier
     */
    function __ChangeMarketplaceAddress(address NewAddress) external virtual;
    // EXAMPLE: 
    // function __ChangeMarketplaceAddress(address NewAddress) override virtual external onlyOwner { _MARKETPLACE = NewAddress; }

    /**
     * @dev Marketplace Address
     */
    address _MARKETPLACE_ADDRESS = 0x2923A537546443AdcF47c7351b51Da6E423d3e58; // MAINNET

    /**
     * @dev Access Modifier For Marketplace
     */
    modifier onlyMarketplace
    {
        require(msg.sender == _MARKETPLACE_ADDRESS, "onlyMarketplace: `msg.sender` Is Not The Marketplace Contract");
        _;
    }
}