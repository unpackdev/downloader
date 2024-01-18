// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IBeepBoop.sol";

contract BeepBoopAmmo is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice $BeepBoop
    IBeepBoop public beepBoop;

    /// @notice Token Ids
    uint256 gameMintPrice = 50000e18;

    /// @notice Round => Tokens
    mapping(uint256 => EnumerableSet.UintSet) private _tokensWithAmmoForRound;

    constructor(address beepBoop_) {
        beepBoop = IBeepBoop(beepBoop_);
    }

    /**
     * @notice Purchase a battery (limited using in-game)
     */
    function purchaseAmmo(uint256 round, uint256[] calldata tokenIds) public {
        uint256 cost = tokenIds.length * gameMintPrice;
        IBeepBoop(beepBoop).spendBeepBoop(msg.sender, cost);
        for (uint256 t; t < tokenIds.length; ++t) {
            _tokensWithAmmoForRound[round].add(tokenIds[t]);
        }
    }

    /**
     * @notice Return the token ids with ammo
     */
    function getTokensWithAmmo(uint256 roundFrom, uint256 roundTo)
        public
        view
        returns (uint256[] memory)
    {
        require(roundFrom <= roundTo);
        uint256 tokenLength;
        for (uint256 r = roundFrom; r <= roundTo; r++) {
            tokenLength += _tokensWithAmmoForRound[r].length();
        }
        uint256 tokenIdx;
        uint256[] memory tokenIds = new uint256[](tokenLength);
        for (uint256 r = roundFrom; r <= roundTo; r++) {
            for (uint256 t; t < _tokensWithAmmoForRound[r].length(); ++t) {
                tokenIds[tokenIdx++] = _tokensWithAmmoForRound[r].at(t);
            }
        }
        return tokenIds;
    }

    /**
     * @notice Change the boop contract
     */
    function changeBeepBoopContract(address contract_) public onlyOwner {
        beepBoop = IBeepBoop(contract_);
    }

    /**
     * @notice Modify price
     */
    function setGameMintPrice(uint256 price) public onlyOwner {
        gameMintPrice = price;
    }
}
