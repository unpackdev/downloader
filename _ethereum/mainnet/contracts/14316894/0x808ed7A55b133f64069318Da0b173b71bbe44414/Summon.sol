// SPDX-License-Identifier: MIT

/// @title RaidParty Party Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Pausable.sol";
import "./IHero.sol";
import "./IHeroURIHandler.sol";
import "./IFighter.sol";
import "./IERC20Burnable.sol";
import "./IParty.sol";

contract Summon is AccessControlEnumerable, Pausable {
    uint256 private constant _cost = 100 * 10**18;

    IHero private immutable _hero;
    IFighter private immutable _fighter;
    IERC20Burnable private immutable _confetti;
    IParty private immutable _party;
    address private _team;

    constructor(
        address admin,
        IHero hero,
        IFighter fighter,
        IERC20Burnable confetti,
        IParty party
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _hero = hero;
        _fighter = fighter;
        _confetti = confetti;
        _team = admin;
        _party = party;
        _pause();
    }

    function getCost() external pure returns (uint256) {
        return _cost;
    }

    function getHero() external view returns (address) {
        return address(_hero);
    }

    function getFighter() external view returns (address) {
        return address(_fighter);
    }

    function getConfetti() external view returns (address) {
        return address(_confetti);
    }

    function getTeam() external view returns (address) {
        return _team;
    }

    function setTeam(address team) external {
        require(msg.sender == _team, "Summon::setTeam: caller not owner");
        _team = team;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mintFighter() external whenNotPaused {
        uint256 teamAmount = (_cost * 15) / 100;
        _confetti.transferFrom(msg.sender, _team, teamAmount);
        _confetti.burnFrom(msg.sender, _cost - teamAmount);
        _fighter.mint(msg.sender, 1);
    }

    function mintHero(uint256 proof, uint256[] calldata burnIds)
        external
        whenNotPaused
    {
        uint256 fighterCost;
        bool isGenesis;
        if (proof < 1111 && proof > 0) {
            require(
                _party.getUserHero(msg.sender) == proof ||
                    _hero.ownerOf(proof) == msg.sender,
                "Summon::mintHero: invalid proof"
            );
            isGenesis = true;
        }

        if (isGenesis) {
            fighterCost = 15;
        } else {
            fighterCost = 20;
        }

        require(
            burnIds.length == fighterCost,
            "Summon::mintHero: mismatched burn token array length"
        );

        for (uint256 i = 0; i < burnIds.length; i++) {
            _fighter.burn(burnIds[i]);
        }

        uint256 teamAmount = (_cost * 15) / 100;
        _confetti.transferFrom(msg.sender, _team, teamAmount);
        _confetti.burnFrom(msg.sender, _cost - teamAmount);
        _hero.mint(msg.sender, 1);
    }
}
