// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract WeedERC20 is ERC20, Ownable {

    mapping(address => bool) public authorizedAddresses;
    uint public maxSupply = 420_000_000 * 10**18;

    // constructor

    constructor() ERC20("WEED WARS", "WEED") Ownable() {}

    // modifier

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "WEED: unauthorized");
        _;
    }

    // only owner

    function setAuthorizedAddresses(
        address[] calldata _addresses,
        bool _isAuthorized
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            authorizedAddresses[_addresses[i]] = _isAuthorized;
        }
    }

    // only authorized

    function mint(address _address, uint256 _amount) external onlyAuthorized {
        _mint(_address, _amount);
        require(totalSupply() <= maxSupply, "Weed: exceeded max supply");
    }

    // user

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
