// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IBeepBoop.sol";
import "./IERC20.sol";

contract BeepBoopBattlePass is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice $BeepBoop
    IBeepBoop public beepBoop;

    /// @notice Token recipient
    address public tokenRecipient;

    /// @notice Token Ids
    uint256 price = 1000e18;

    /// @notice Round => Tokens
    mapping(uint256 => EnumerableSet.UintSet) private _tokensWithPassForRound;

    /// @notice Limit of passes
    uint256 battlePassLimit = 5000;
    uint256 mintedBattlePasses;

    constructor(address beepBoop_, address tokenRecipient_) {
        beepBoop = IBeepBoop(beepBoop_);
        tokenRecipient = tokenRecipient_;
    }

    /**
     * @notice Purchase a battery (limited using in-game)
     */
    function purchase(uint256 round, uint256[] calldata tokenIds) public {
        require(
            mintedBattlePasses + tokenIds.length <= battlePassLimit,
            "No longer available"
        );
        uint256 cost = tokenIds.length * price;
        IERC20(address(beepBoop)).transferFrom(
            msg.sender,
            tokenRecipient,
            cost
        );
        mintedBattlePasses += tokenIds.length;
        for (uint256 t; t < tokenIds.length; ++t) {
            _tokensWithPassForRound[round].add(tokenIds[t]);
        }
    }

    /**
     * @notice Return the token ids with battle pass
     */
    function getTokensWithPass(uint256 roundFrom, uint256 roundTo)
        public
        view
        returns (uint256[] memory)
    {
        require(roundFrom <= roundTo);
        uint256 tokenLength;
        for (uint256 r = roundFrom; r <= roundTo; r++) {
            tokenLength += _tokensWithPassForRound[r].length();
        }
        uint256 tokenIdx;
        uint256[] memory tokenIds = new uint256[](tokenLength);
        for (uint256 r = roundFrom; r <= roundTo; r++) {
            for (uint256 t; t < _tokensWithPassForRound[r].length(); ++t) {
                tokenIds[tokenIdx++] = _tokensWithPassForRound[r].at(t);
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
    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    /**
     * @notice Set token recipient
     */
    function setTokenRecipient(address address_) public onlyOwner {
        tokenRecipient = address_;
    }

    /**
     * @notice Set battle pass limit
     */
    function setBattlePassLimit(uint256 limit_) public onlyOwner {
        battlePassLimit = limit_;
    }
}
