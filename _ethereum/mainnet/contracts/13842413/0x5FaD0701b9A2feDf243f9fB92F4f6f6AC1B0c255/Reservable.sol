// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Revealable.sol";

contract Reserveable is Revealable {
    uint256 public reservedTokens; // amount of tokens reserved, that is tokens that won't be sold
    uint256 public reserveTokenCounter; // counter for tokens that have been transfered

    /**
     * @dev set tokens that needs to be reserved, it sets new value, does not add value to previous value
     * @param _reserveTokens new number of tokens to be reserved
     */
    function reserveTokens(uint256 _reserveTokens) external onlyOwner {
        require(tokensCount == 0, "RS:001");
        require(
            _reserveTokens + presaleReservedTokens < maximumTokens,
            "RS:002"
        );
        reservedTokens = _reserveTokens;
        startingTokenIndex = _reserveTokens;
    }

    /**
     * @dev transfer the one reserve tokens to a receiver
     * @param _receiver receiver address of reserved token
     */
    function transferReservedToken(address _receiver) external onlyOwner {
        uint256 currentTokenId = reserveTokenCounter;
        require(currentTokenId < reservedTokens, "RS:001");
        reserveTokenCounter++;
        _safeMint(_receiver, currentTokenId + 1);
    }
}
