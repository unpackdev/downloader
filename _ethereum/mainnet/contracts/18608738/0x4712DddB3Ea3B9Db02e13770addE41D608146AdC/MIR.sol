// SPDX-License-Identifier: MIT

/*
##########################################################
#                                                        #
#    twitter:  https://twitter.com/MakeItRainERC         #
#    website:  https://makeethrain.today                 #
#    telegram: https://t.me/mirtokenportal               #
#                                                        #
##########################################################
*/

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

contract MIR is ERC20, ERC20Permit, Ownable {
    mapping(address => bool) public whitelist;
    address public UNISWAP_PAIR;
    bool public whitelisted = true;

    uint256 public LimitBuy = 15; // 1.5% of the supply
    uint256 public initialSupply = 100_000_000; // token supply

    constructor() ERC20("Make It Rain", "MIR") ERC20Permit("Make It Rain") {
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function setPair(address pair) public onlyOwner {
        require(pair != address(0), "Invalid Address");
        UNISWAP_PAIR = pair;
        whitelisted = true;
    }

    function activatePublicSale() public onlyOwner {
        whitelisted = false;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (whitelisted && recipient != owner() && msg.sender != owner()) {
            require(whitelist[recipient], "Recipient is not whitelisted");
            require(UNISWAP_PAIR != address(0), "trade is not enabled yet");
            if (msg.sender == UNISWAP_PAIR) {
                require(
                    super.balanceOf(recipient) + amount <=
                        (totalSupply() * LimitBuy) / 1000,
                    "Forbid, You Can't hold more than 1.5% of the supply"
                );
            }
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (whitelisted && recipient != owner() && sender != owner()) {
            require(whitelist[recipient], "Recipient is not whitelisted");
            require(UNISWAP_PAIR != address(0), "trade is not enabled yet");
            if (sender == UNISWAP_PAIR) {
                require(
                    super.balanceOf(recipient) + amount <=
                        (totalSupply() * LimitBuy) / 1000,
                    "Forbid, You Can't hold more than 1.5% of the supply"
                );
            }
        }
        return super.transferFrom(sender, recipient, amount);
    }
}
