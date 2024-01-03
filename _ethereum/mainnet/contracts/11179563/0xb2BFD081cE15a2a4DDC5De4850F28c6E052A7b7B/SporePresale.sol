// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SporeToken.sol";

contract SporePresale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public ethSupply;
    uint256 public whitelistCount;
    address payable devAddress;
    uint256 public sporePrice = 25;
    uint256 public buyLimit = 3 * 1e18;
    bool public presaleStart = false;
    bool public onlyWhitelist = true;
    uint256 public presaleLastSupply = 15000 * 1e18;

    SporeToken public spore;

    event BuySporeSuccess(address account, uint256 ethAmount, uint256 sporeAmount);

    constructor(address payable devAddress_, SporeToken sporeToken_) public {
        devAddress = devAddress_;
        spore = sporeToken_;
    }

    function addToWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            require(whitelist[account] == false, "This account is already in whitelist.");
            whitelist[account] = true;
            whitelistCount = whitelistCount + 1;
        }
    }

    function removeFromWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            require(whitelist[account], "This account is not in whitelist.");
            whitelist[account] = false;
            whitelistCount = whitelistCount - 1;
        }
    }

    function getDevAddress() public view returns (address) {
        return address(devAddress);
    }
    function setDevAddress(address payable account) public onlyOwner {
        devAddress = account;
    }

    function startPresale() public onlyOwner {
        presaleStart = true;
    }

    function stopPresale() public onlyOwner {
        presaleStart = false;
    }

    function setSporePrice(uint256 newPrice) public onlyOwner {
        sporePrice = newPrice;
    }

    function setBuyLimit(uint256 newLimit) public onlyOwner {
        buyLimit = newLimit;
    }

    function changeToNotOnlyWhitelist() public onlyOwner {
        onlyWhitelist = false;
    }

    modifier needHaveLastSupply() {
        require(presaleLastSupply >= 0, "Oh you are so late.");
        _;
    }

    modifier presaleHasStarted() {
        require(presaleStart, "Presale has not been started.");
        _;
    }

    receive() external payable presaleHasStarted needHaveLastSupply {
        if (onlyWhitelist) {
            require(whitelist[msg.sender], "This time is only for people who are in whitelist.");
        }
        uint256 ethTotalAmount = ethSupply[msg.sender].add(msg.value);
        require(ethTotalAmount <= buyLimit, "Everyone should buy less than 3 eth.");
        uint256 sporeAmount = msg.value.mul(sporePrice);
        require(sporeAmount <= presaleLastSupply, "insufficient presale supply");
        presaleLastSupply = presaleLastSupply.sub(sporeAmount);
        spore.mint(msg.sender, sporeAmount);
        ethSupply[msg.sender] = ethTotalAmount;
        devAddress.transfer(msg.value);
        emit BuySporeSuccess(msg.sender, msg.value, sporeAmount);
    }
}
