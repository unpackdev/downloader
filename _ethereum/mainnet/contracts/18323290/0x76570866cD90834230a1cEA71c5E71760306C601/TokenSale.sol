// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract TokenSale is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 public amountPerEth;
    uint256 public minimumEth;
    uint256 public rate;
    IERC20 public token;

    event TokensPurchased(
        address indexed buyer,
        uint256 tokenAmount,
        uint256 ethAmount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        minimumEth = 10000000000000000; // 0.01 ETH
        rate = 39000000000000000000000; // 39,000 GROW per ETH
        token = IERC20(0x268B9A37DA0c781613d5DA23F847Fa18B7Cc795a);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setMinimalEth(uint256 amount) public onlyOwner {
        minimumEth = amount;
    }

    function setAmountPerEth(uint256 amount) public onlyOwner {
        amountPerEth = amount;
    }

    function buyTokens() external payable whenNotPaused {
        uint256 ethAmount = msg.value;

        // Ensure the buyer is sending enough ETH
        require(ethAmount >= minimumEth, "Not enough ETH sent");

        uint256 tokenAmount = (ethAmount * rate) / 1e18; // Convert ETH to tokens

        // Ensure the contract has enough tokens to sell
        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Not enough tokens in the contract"
        );

        // Transfer tokens to the buyer
        require(
            token.transfer(msg.sender, tokenAmount),
            "Token transfer failed"
        );

        emit TokensPurchased(msg.sender, tokenAmount, ethAmount);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
