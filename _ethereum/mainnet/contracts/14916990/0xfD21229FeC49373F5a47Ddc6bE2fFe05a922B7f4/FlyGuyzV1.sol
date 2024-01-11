// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";

import "./IFlyGuyzToken.sol";
//import "./SafeMath.sol";

contract Flyguyz is Initializable, ContextUpgradeable, OwnableUpgradeable { //, ERC20Upgradeable
    //using SafeMath for uint256;

    address public TokenAddress;
    IFlyGuyzToken private Token;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Context_init();
        __Ownable_init();
    }

    function setToken(address _tokenContract) public onlyOwner {
        TokenAddress = _tokenContract;
        Token = IFlyGuyzToken(_tokenContract);
    }
    function giveTokens(address to, uint256 amount) public onlyOwner {
        Token.transfer(to, amount * (10**uint256(18)));
    }
}