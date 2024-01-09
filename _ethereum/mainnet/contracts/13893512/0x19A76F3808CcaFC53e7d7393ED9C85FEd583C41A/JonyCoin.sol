// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";

contract JonyCoin is ERC20, Ownable {
    uint256 lockDate = 1672531199;

    constructor() ERC20("JonyCoin", "JOSC") {
        _mint(msg.sender, 180000000 * 10**decimals());
    }

    function isOwner() private view returns (bool) {
        return _msgSender() == owner();
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(
            isOwner() || block.timestamp >= lockDate,
            "JOSC: Transfer restricted until 1/01/2023"
        );

        _transfer(_msgSender(), recipient, amount);

        return true;
    }
}
