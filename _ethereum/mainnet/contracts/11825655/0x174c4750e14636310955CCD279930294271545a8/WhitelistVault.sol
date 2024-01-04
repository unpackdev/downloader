// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./Initializable.sol";
import "./Ownable.sol";

contract WhitelistVault is Initializable, OwnableUpgradeSafe {

    /* solhint-disable var-name-mixedcase */
    uint8 public ENABLED = 1;
    uint8 public REQUESTED = 2;
    uint8 public DISABLED = 3;
    /* solhint-enabled var-name-mixedcase */

    mapping(address => uint8) private _allowed;

    event AddedToWhiteList(address _address);
    event PropossedToWhiteList(address _address);
    event RemoveFromWhiteList(address _address);

    function initialize() public {
        __Ownable_init();
    }

    function proposeToWhiteList(address proposed) public {
        require(proposed != address(0), "WhitelistVault: proposed is the zero address");
        _allowed[proposed] = REQUESTED;
        emit PropossedToWhiteList(proposed);
    }

    function addToWhitelist(address whitelisted) public onlyOwner {
        require(whitelisted != address(0), "WhitelistVault: whitelisted is the zero address");
        _allowed[whitelisted] = ENABLED;
        emit AddedToWhiteList(whitelisted);
    }

    function removeFromWhitelist(address blacklisted) public onlyOwner {
        require(blacklisted != address(0), "WhitelistVault: blacklisted is the zero address");
        if (_allowed[blacklisted] == ENABLED || _allowed[blacklisted] == REQUESTED){
          _allowed[blacklisted] = DISABLED;
          emit RemoveFromWhiteList(blacklisted);
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _allowed[_address] == ENABLED;
    }

    function isRequested(address _address) public view returns (bool) {
        return _allowed[_address] == REQUESTED;
    }
}
