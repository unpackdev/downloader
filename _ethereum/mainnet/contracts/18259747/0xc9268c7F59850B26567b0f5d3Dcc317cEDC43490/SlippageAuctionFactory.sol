// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ====================== SlippageAuctionFactory ======================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

import "./ERC20.sol";
import "./SlippageAuction.sol";

contract SlippageAuctionFactory {
    /// @notice The auctions created by this factory
    address[] public auctions;

    /// @notice mapping of hashed constructor arguments to whether or not the auction has been created
    mapping(bytes32 _constructorHash => bool _isCreated) public constructorHashes;

    /// @notice mapping of auction addresses to whether or not the auction has been created
    mapping(address => bool) public isAuction;

    /// @notice The ```createAuction``` function is used to create a new auction
    /// @dev Tokens must be 18 decimals
    /// @param _buyToken The token that will be used to purchase tokens in the auction
    /// @param _sellToken The token that will be sold in the auction
    /// @return _auctionAddress The address of the new auction
    function createAuction(address _buyToken, address _sellToken) external returns (address _auctionAddress) {
        if (IERC20Metadata(_buyToken).decimals() != 18) {
            revert BuyTokenMustBe18Decimals();
        }
        if (IERC20Metadata(_sellToken).decimals() != 18) {
            revert SellTokenMustBe18Decimals();
        }

        // Ensure a single sender account can only create a single auction contract given two input tokens
        bytes32 _hash = keccak256(abi.encodePacked(_buyToken, _sellToken, msg.sender));
        if (constructorHashes[_hash]) {
            revert AuctionAlreadyExists();
        }
        constructorHashes[_hash] = true;

        // Deploy the auction
        SlippageAuction _auction = new SlippageAuction({
            _timelockAddress: msg.sender,
            _buyToken: _buyToken,
            _sellToken: _sellToken
        });

        // Set return variable
        _auctionAddress = address(_auction);

        // Add auction address to mapping
        isAuction[_auctionAddress] = true;

        // Add to auctions array
        auctions.push(_auctionAddress);

        emit AuctionCreated({ auction: _auctionAddress, buyToken: _buyToken, sellToken: _sellToken });
    }

    /// @notice The ```getAuctions``` function returns a list of all auctions deployed
    /// @return memory address[] The list of auctions
    function getAuctions() external view returns (address[] memory) {
        return auctions;
    }

    /// @notice The ```auctionsLength``` function returns the number of auctions deployed
    /// @return The length of the auctions array
    function auctionsLength() external view returns (uint256) {
        return auctions.length;
    }

    /// @notice The ```AuctionCreated``` event is emitted when a new auction is created
    /// @param auction The address of the new auction
    /// @param buyToken The token that will be used to purchase tokens in the auction
    /// @param sellToken The token that will be sold in the auction
    event AuctionCreated(address indexed auction, address indexed buyToken, address indexed sellToken);

    /// @notice The ```AuctionAlreadyExists``` error is thrown when an auction with the same sender and tokens has already been created
    error AuctionAlreadyExists();

    /// @notice The ```SellTokenMustBe18Decimals``` error is thrown when the sell token is not 18 decimals
    error SellTokenMustBe18Decimals();

    /// @notice The ```BuyTokenMustBe18Decimals``` error is thrown when the buy token is not 18 decimals
    error BuyTokenMustBe18Decimals();
}
