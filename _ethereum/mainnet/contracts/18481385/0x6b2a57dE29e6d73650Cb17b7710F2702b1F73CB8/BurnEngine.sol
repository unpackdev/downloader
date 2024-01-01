// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.21;

import "./OwnableMaster.sol";
import "./IVerseToken.sol";
import "./TransferHelper.sol";

error NoTokens();
error InvalidValue();

contract BurnEngine is OwnableMaster, TransferHelper {

    uint256 public burnCost;
    IVerseToken public immutable VERSE_TOKEN;

    event TokensBurned(
        address indexed burner,
        uint256 amount
    );

    event BurnCostUpdated(
        address indexed manager,
        uint256 newBurnCost
    );

    constructor(
        uint256 _burnCost,
        IVerseToken _verseToken
    )
        OwnableMaster(
            msg.sender
        )
    {
        burnCost = _burnCost;
        VERSE_TOKEN = _verseToken;
    }

    function adminBurn()
        external
        onlyMaster
    {
        _burn();
    }

    function userBurn()
        external
    {
        _safeTransferFrom(
            address(VERSE_TOKEN),
            msg.sender,
            address(this),
            burnCost
        );

        _burn();
    }

    function _burn()
        private
    {
        uint256 balance = VERSE_TOKEN.balanceOf(
            address(this)
        );

        if (balance == 0) {
            revert NoTokens();
        }

        VERSE_TOKEN.burn(
            balance
        );

        emit TokensBurned(
            msg.sender,
            balance
        );
    }

    function setBurnCost(
        uint256 _newBurnCost
    )
        external
        onlyMaster
    {
        if (_newBurnCost == 0) {
            revert InvalidValue();
        }

        burnCost = _newBurnCost;

        emit BurnCostUpdated(
            msg.sender,
            _newBurnCost
        );
    }
}
