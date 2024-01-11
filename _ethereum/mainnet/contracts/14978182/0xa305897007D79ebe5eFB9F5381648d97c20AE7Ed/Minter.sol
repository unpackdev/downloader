// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IToken.sol";

contract Minter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public maxTokens;

    // ======== External Storage Contract =========
    IToken public immutable token;

    // ======== Constructor =========
    constructor(address contractAddress,
                uint256 tokenSupply) {
        token = IToken(contractAddress);
        maxTokens = tokenSupply;
    }

    // ======== Modifier Checks =========    
    modifier isSupplyAvailable(uint256 numberOfTokens) {
        uint256 supply = token.tokenCount();
        require(supply + numberOfTokens <= maxTokens, "Exceeds max token supply!");
        _;
    }

    // ======== Mint Functions =========
    function mint(address _to, uint256 _reserveAmount) public 
        onlyOwner 
        isSupplyAvailable(_reserveAmount) {
            token.mint(_reserveAmount, _to);
    }
    
    function decreaseTokenSupply(uint256 newMaxTokenSupply) external onlyOwner {
        require(maxTokens > newMaxTokenSupply, "Max token supply can only be decreased!");
        maxTokens = newMaxTokenSupply;
    }
}
