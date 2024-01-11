// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract HYFI_Whitelist is Initializable, OwnableUpgradeable {
    mapping(address => bool) discountWhitelist;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    function initialize() public payable initializer {
        __Ownable_init();
    }

    function addToWhitelist(address _address) public onlyOwner {
        discountWhitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function addMultipleToWhitelist(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 addr = 0; addr < _addresses.length; addr++) {
            addToWhitelist(_addresses[addr]);
        }
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        discountWhitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return discountWhitelist[_address];
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }
}
