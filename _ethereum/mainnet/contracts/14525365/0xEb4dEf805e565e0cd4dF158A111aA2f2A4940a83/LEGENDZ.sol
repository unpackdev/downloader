// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./Ownable.sol";

error OnlyAuthorizedOperators();
error OwnerAuthorizationLocked();

contract LEGENDZ is ERC20, Ownable {

    // mapping from address to whether or not it can mint / burn
    mapping(address => bool) proxies;

    constructor() ERC20("Legendz", "$LEGENDZ") {
        proxies[_msgSender()] = true;
    }

    /**
     * mints $LEGENDZ to a recipient
     * @param to the recipient of the $LEGENDZ
     * @param amount the amount of $LEGENDZ to mint
     */
    function mint(address to, uint256 amount) external {
        if (!proxies[_msgSender()]) revert OnlyAuthorizedOperators();
        _mint(to, amount);
    }

    /**
     * burns $LEGENDZ of a holder
     * @param from the holder of the $LEGENDZ
     * @param amount the amount of $LEGENDZ to burn
     */
    function burn(address from, uint256 amount) external {
        if (!proxies[_msgSender()]) revert OnlyAuthorizedOperators();
        _burn(from, amount);
    }

    /**
     * sets a proxy's authorization
     * @param proxyAddress address of the proxy
     * @param authorized the new authorization value
     */
    function setProxy(address proxyAddress, bool authorized) public onlyOwner {
        if (proxyAddress == owner()) revert OwnerAuthorizationLocked();
        proxies[proxyAddress] = authorized;
    }
}
