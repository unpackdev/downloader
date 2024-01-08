// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC20.sol";

/// @author Medici
/// @title Treasury contract for Abacus
contract ABCTreasury{
    
    uint public nftsPriced;
    uint public profitGenerated;
    uint public tokensClaimed;
    address public auction;
    address public pricingSessionFactory;
    address public admin;
    address public ABCToken;

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setABCTokenAddress(address _ABCToken) onlyAdmin external {
        require(ABCToken == address(0));
        ABCToken = _ABCToken;
    }

    function withdraw(uint _amount) onlyAdmin external {
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function setAdmin(address _newAdmin) onlyAdmin external {
        admin = _newAdmin;
    }

    function setPricingFactory(address _pricingFactory) onlyAdmin external {
        pricingSessionFactory = _pricingFactory;
    }

    function setAuction(address _auction) onlyAdmin external {
        auction = _auction;
    }

    function getAuction() view external returns(address) {
        return auction;
    }

    /* ======== CHILD FUNCTIONS ======== */
    
    function sendABCToken(address recipient, uint _amount) external {
        require(msg.sender == pricingSessionFactory || msg.sender == admin || msg.sender == auction);
        IERC20(ABCToken).transfer(recipient, _amount);
        tokensClaimed += _amount;
    }

    /// @notice Allows Factory contract to update the profit generated value
    function updateProfitGenerated(
        uint _amount 
    ) isFactory external { 
        profitGenerated += _amount;
    }
    
    /// @notice Allows Factory contract to update the amount of NFTs that have been priced
    function updateNftPriced() isFactory external {
        nftsPriced++;
    }

    /* ======== FALLBACKS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    modifier onlyAdmin() {
        require(admin == msg.sender, "not admin");
        _;
    }
    
    modifier isFactory() {
        require(msg.sender == pricingSessionFactory, "not factory");
        _;
    }
}
