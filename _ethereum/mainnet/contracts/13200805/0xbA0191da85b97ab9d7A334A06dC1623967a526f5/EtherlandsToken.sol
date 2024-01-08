// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./IEtherlandsToken.sol";

contract EtherlandsToken is IEtherlandsToken, ERC20Upgradeable, OwnableUpgradeable {

    bool public paused;

    function initialize(string memory _name, string memory _symbol) public override initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        _mint(0x958892b4a0512b28AaAC890FC938868BBD42f064, 100*1000000*1e18); // 100 million tokens
        paused = true;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        if(from != OwnableUpgradeable.owner()){
            require(paused != true, "transfers are currently paused");
        }
    }

    function adminMint(address to, uint256 amount) external override onlyOwner{
        ERC20Upgradeable._mint(to,amount);
    }

    function adminBurn(address from, uint256 amount) external override onlyOwner{
        ERC20Upgradeable._burn(from,amount);
    }

    function setPaused(bool pause) external override onlyOwner{
        paused = pause;
    }

}
