// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";

contract KyokoVoteToken is ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, 
OwnableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable {

    struct UserInfo {
        address user;
        uint256 amount;
    }

    event MintArray(address msgSender, UserInfo[] array);

    // constructor() ERC20("KyokoVoteToken", "KVT") ERC20Permit("KyokoVoteToken") {}
    function initialize() public initializer {
        __ERC20_init("KyokoVoteToken", "KVT");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("KyokoVoteToken");
        __ERC20Votes_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintArray(UserInfo[] calldata array) public onlyOwner {
        uint256 arrayLen = array.length;
        require(arrayLen > 0, "data error");
        for(uint256 i = 0;i < arrayLen;i++) {
            UserInfo memory userInfo = array[i];
            mint(userInfo.user, userInfo.amount);
        }
        emit MintArray(msg.sender, array);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }
}