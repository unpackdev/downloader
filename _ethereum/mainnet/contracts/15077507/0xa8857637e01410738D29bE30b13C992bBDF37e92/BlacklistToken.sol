// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SnapshotToken.sol";
import "./IBlacklist.sol";


contract BlacklistToken is SnapshotToken {

    address public blacklist;
    
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    // /**
    //  * @dev Initializes the contract setting the deployer as the initial owner.
    //  */
    // function __BlacklistToken_init(string memory name_, string memory symbol_, address _blacklist) internal onlyInitializing {
    //     __SnapshotToken_init( name_, symbol_);
    //     blacklist = _blacklist;
    // }

     constructor(string memory name_, string memory symbol_, address _blacklist)
    SnapshotToken( name_, symbol_){
        blacklist = _blacklist;
    }

    modifier isNotBlacklisted(address _account) {
        bool isBlacklisted = IBlacklist(blacklist).isBlacklisted(_account);
        require(!isBlacklisted  , 'isNotBlacklisted: this account is blacklisted');
        _;
    }

    function destroyBlackFunds (address _account, uint256 amount) public onlyOwner {
        require(IBlacklist(blacklist).isBlacklisted(_account),'destroyBlackFunds: user must be blacklisted');
       bool success = IBlacklist(blacklist).remove(_account);
       require(success, 'destroyBlackFunds: remove failed');
        _burn(_account, amount);
        IBlacklist(blacklist).add(_account);

        emit DestroyedBlackFunds(_account, amount);
    }

    function _beforeTokenTransfer(  address from,
        address to,
        uint256 amount
    ) internal  override isNotBlacklisted(from) isNotBlacklisted(to) {
        super._beforeTokenTransfer(from, to, amount);
    }

  
}