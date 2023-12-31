// SPDX-License-Identifier: MIT
// Your Personalized, Sovereign AI in the Web 3.0 Era https://tgpt.guru

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


contract TruthGPT is ERC20, Ownable {
    using SafeMath for uint256;

    // treasury wallet
    address payable public treasury;

    // maximum transaction amount
    uint256 public maxTxAmount;

    string public _1_x;
    string public _2_telegram;
    string public _3_website;

    constructor() ERC20("TruthGPT", "TGPT") {
        // Set the treasury wallet to the contract owner
        treasury = payable(msg.sender);

        uint256 initialSupply = 69420000000 * (10 ** uint256(decimals()));
        _mint(msg.sender, initialSupply);
    }

    function setTreasury(address payable _treasury) public onlyOwner {
        require(_treasury != address(0), "Treasury cannot be the zero address");
        require(address(this)!= _treasury, "Treasury wallet cannot be the contract address");
        treasury = _treasury;
    }

    function set_1_x(string memory _1_x_) public onlyOwner {
        _1_x = _1_x_;
    }

    function set_2_telegram(string memory _2_telegram_) public onlyOwner {
        _2_telegram = _2_telegram_;
    }

    function set_3_website(string memory _3_website_) public onlyOwner {
        _3_website = _3_website_;
    }


    function setMaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        maxTxAmount = _maxTxAmount;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {

        if (sender != treasury && recipient != treasury) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }


        super._transfer(sender, recipient, amount);

        // The implementation of a 1% treasury minting on large transactions (those amounting to 6942000 or more) is a purposeful and strategic financial decision designed to safeguard the project's sustainability and foster long-term growth. This automatic funding mechanism provides a steady stream of resources for the treasury, enabling reinvestment into crucial areas such as project development, marketing, and community incentives.
        // Additionally, the 1% minting policy serves as a deterrent against excessively large transactions that could destabilize the token price or leave the system vulnerable to market manipulation. In this way, we align the interests of all stakeholders, ensuring the project's stability and fostering an environment conducive to continual innovation and improvement. This is not merely a measure to increase funds; it's a strategy for ensuring the project's resilience, longevity, and success in the dynamic and competitive landscape of blockchain technologies.
        if (amount >= 6942000 * (10 ** uint256(decimals()))) {
            uint256 mintAmount = amount.div(100);  // 1%
            _mint(treasury, mintAmount);
        }
    }

    // Emergency function to withdraw all ETH from the contract
    function emergencyETHWithdraw() external {
        require(msg.sender == treasury, "Only the treasury can withdraw ETH");
        treasury.transfer(address(this).balance);
    }

    // Emergency function to withdraw any ERC20 token from the contract
    function emergencyERC20Withdraw(IERC20 token) external {
        require(msg.sender == treasury, "Only the treasury can withdraw ERC20 tokens");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(treasury, balance);
    }
}