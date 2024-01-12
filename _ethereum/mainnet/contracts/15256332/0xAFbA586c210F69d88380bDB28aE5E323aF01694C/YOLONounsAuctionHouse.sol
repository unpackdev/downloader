// SPDX-License-Identifier: GPL-3.0

/// @title The YOLO Nouns auction house

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// YOLONounsAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by YOLO and Nounders DAO.

pragma solidity ^0.8.6;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IYOLONounsAuctionHouse.sol";
//import "./IYOLONounsToken.sol";
import "./YOLONounsToken.sol";
import "./NounsAuctionHouse.sol";

contract YOLONounsAuctionHouse is IYOLONounsAuctionHouse, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // The YOLO Nouns ERC721 token contract
    //IYOLONounsToken public nouns;
    address public nouns;

    // The address of the deployed Nouns Auction House contract
    address public deployedAuction;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    uint256 public lastBlockNumber;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        address _nouns,
        address _deployedAuction,
        uint256 _reservePrice
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        nouns = _nouns;
        deployedAuction = _deployedAuction;
        reservePrice = _reservePrice;
    }

    function auction() external view override returns (uint256, uint256, uint256, bool) {
    	return (YOLONounsToken(nouns).totalSupply(), reservePrice, lastBlockNumber, paused());
    }

    function mintNoun() external payable override whenNotPaused {    
        require(msg.value == reservePrice, 'YOLO: Incorrect ETH amount');
        require(lastBlockNumber < block.number, 'YOLO: Block already minted');

    	(uint256 _deployedNounId, , , , , ) = NounsAuctionHouse(deployedAuction).auction();
		        
        lastBlockNumber = block.number;
        YOLONounsToken(nouns).mint(msg.sender, ++_deployedNounId);
    }

    /**
     * @notice Pause the Nouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Nouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused.
     */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;
    }
    
    function withdraw(address to, uint amount) external override onlyOwner {
        payable(to).transfer(amount);
    }    

    /**
     * @notice Set the deployed auction address.
     * @dev Only callable by the owner.
     */
    function setDeployedAuction(address _deployedAuction) external override onlyOwner {
        deployedAuction = _deployedAuction;
    }
}