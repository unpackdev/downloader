// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Essence is ERC20, Ownable {

    uint256 public constant TREASURY_SUPPLY = 1000000000 * 1e18;
    uint256 public constant TOTAL_SUPPLY = 8000000000 * 1e18;

    address public dracoAddress;

    modifier onlyDracoAddress() {
        require(msg.sender == dracoAddress, "Not draco address");
        _;
    }
    
    constructor() ERC20("Essence", "DRA") {
        _mint(msg.sender, TREASURY_SUPPLY);
    }

    function setDracoAddress(address _dracoAddress) public onlyOwner {
        dracoAddress = _dracoAddress;
    }

    function mintToken(address _claimer, uint256 _amount) public onlyDracoAddress {
        require(_amount + totalSupply() <= TOTAL_SUPPLY, 'Token cap limit');
        _mint(_claimer, _amount);
    }
}