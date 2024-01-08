//  ____    _    _   _    _    _   _    _    ____
// | __ )  / \  | \ | |  / \  | \ | |  / \  / ___|
// |  _ \ / _ \ |  \| | / _ \ |  \| | / _ \ \___ \
// | |_) / ___ \| |\  |/ ___ \| |\  |/ ___ \ ___) |
// |____/_/   \_\_| \_/_/   \_\_| \_/_/   \_\____/
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Bananas is ERC20, Ownable {
    address public apeAddress;
    address public jungleAddress;

    mapping(address => bool) public allowedAddresses;

    constructor() ERC20("BANANAS", "BANANAS") {}

    function setApeAddress(address apeAddr) external onlyOwner {
        apeAddress = apeAddr;
    }

    function setJungleAddress(address jungleAddr) external onlyOwner {
        jungleAddress = jungleAddr;
    }

    function burn(address user, uint256 amount) external {
        require(msg.sender == jungleAddress || msg.sender == apeAddress, "Address not authorized");
        _burn(user, amount);
    }

    function mint(address to, uint256 value) external {
        require(msg.sender == jungleAddress || msg.sender == apeAddress, "Address not authorized");
        _mint(to, value);
    }
}