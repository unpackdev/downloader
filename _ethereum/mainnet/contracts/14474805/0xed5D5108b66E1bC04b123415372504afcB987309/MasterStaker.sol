// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./IPytheas.sol";
import "./IOrbitalBlockade.sol";
import "./IMasterStaker.sol";

contract MasterStaker is IMasterStaker, Pausable {
    address public auth;

    mapping(address => bool) private admins;

    // reference to Pytheas for stake of colonist
    IPytheas public pytheas;

    //reference to the oribitalBlockade for stake of pirates
    IOrbitalBlockade public orbital;

    constructor() {
        auth = msg.sender;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            msg.sender == tx.origin && size == 0,
            "you're trying to cheat!"
        );
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(pytheas) != address(0) && address(orbital) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(address _pytheas, address _orbital)
        external
        onlyOwner
    {
        pytheas = IPytheas(_pytheas);
        orbital = IOrbitalBlockade(_orbital);
    }

    function masterStake(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external whenNotPaused noCheaters {
        uint16[] memory colonistIds = uint16[](colonistTokenIds);
        uint16[] memory pirateIds = uint16[](pirateTokenIds);
        pytheas.addColonistToPytheas(msg.sender, colonistIds);
        orbital.addPiratesToCrew(msg.sender, pirateIds);
    }

    function masterUnstake(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external whenNotPaused noCheaters {
        uint16[] memory colonistIds = uint16[](colonistTokenIds);
        uint16[] memory pirateIds = uint16[](pirateTokenIds);
        pytheas.claimColonistFromPytheas(msg.sender, colonistIds, true);
        orbital.claimPiratesFromCrew(msg.sender, pirateIds, true);
    }

    function masterClaim(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external whenNotPaused noCheaters {
        uint16[] memory colonistIds = uint16[](colonistTokenIds);
        uint16[] memory pirateIds = uint16[](pirateTokenIds);
        pytheas.claimColonistFromPytheas(msg.sender, colonistIds, false);
        orbital.claimPiratesFromCrew(msg.sender, pirateIds, false);
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function transferOwnership(address newOwner) external onlyOwner {
        auth = newOwner;
    }
}
