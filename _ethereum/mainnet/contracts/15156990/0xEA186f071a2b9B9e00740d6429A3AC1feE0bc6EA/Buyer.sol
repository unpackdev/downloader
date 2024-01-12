//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC721.sol";
import "./Ownable.sol";

import "./Mooresque.sol";

contract Buyer is Ownable {

    // Mooresque
    address public mooresque;

    // Errors
    string private constant WRONG_PRICE = "Wrong price";
    string private constant PAUSED = "Paused";

    // Pricing
    uint256 public currentPrice;
    uint256 public step;
    address public escrow;

    // Pausing
    bool public paused = true;

    /**
     * Constructor, no special features.
     */
    constructor(address _mooresque, address _escrow, uint256 _startingPrice, uint256 _step) {
        mooresque = _mooresque;
        escrow = _escrow;
        currentPrice = _startingPrice;
        step = _step;
    }

    /**
     * Buys a specific Mooresque. It will fail if it is not longer available.
     */
    function buy(uint256 tokenId) public payable {
        require(!paused, PAUSED);
        require(msg.value == currentPrice, WRONG_PRICE);
        currentPrice += step;
        Mooresque(mooresque).safeTransferFrom(escrow, msg.sender, tokenId);
    }

    /**
     * Pauses the buying process.
     */
    function pause(bool value) public onlyOwner {
        paused = value;
    }

    /**
     * Sends funds to the caller (only owner).
     */
    function drain(address _token, uint256 _amount) public onlyOwner {
        if (_token == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).transfer(msg.sender, _amount);
        }
    }
}

