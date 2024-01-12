// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract BrewlabsFactoryVerification is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    constructor() ERC721("Brewlabs Factory Verification", "BFV") {}

    function verifyTo(address recipient) public onlyOwner returns (uint256) {
        require(IERC20(recipient).totalSupply() >= 0, "BFV: Not ERC20 Token");
        require(balanceOf(recipient) == 0, "BFV: Already verified");

        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _mint(recipient, newItemId);

        return newItemId;
    }
}
