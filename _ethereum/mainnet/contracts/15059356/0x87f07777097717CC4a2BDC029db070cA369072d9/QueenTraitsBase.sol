// SPDX-License-Identifier: MIT

/// @title A base contract with implementation control

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

//import "./ERC165.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC165Storage.sol";

import "./RoyalLibrary.sol";
import "./IRoyalContractBase.sol";
import "./IQueenPalace.sol";

contract QueenTraitsBase is
    ERC165Storage,
    IRoyalContractBase,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    IQueenPalace internal queenPalace;

    /************************** vCONTROLLER REGION *************************************************** */

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external virtual onlyOwner whenPaused {
        _unpause();
    }

    /**
     *IN
     *_queenPalace: address of queen palace contract
     *OUT
     *newQueenPalace: new QueenPalace contract address
     */
    function setQueenPalace(IQueenPalace _queenPalace)
        external
        nonReentrant
        whenPaused
        onlyOwnerOrDAO
        onlyOnImplementationOrDAO
    {
        _setQueenPalace(_queenPalace);
    }

    /**
     *IN
     *_queenPalace: address of queen palace contract
     *OUT
     *newQueenPalace: new QueenPalace contract address
     */
    function _setQueenPalace(IQueenPalace _queenPalace) internal {
        queenPalace = _queenPalace;
    }

    /************************** ^vCONTROLLER REGION *************************************************** */

    /************************** vMODIFIERS REGION ***************************************************** */
    modifier onlyOwnerOrDeveloperOrDAO() {
        isOwnerOrDeveloperOrDAO();
        _;
    }
    modifier onlyOwnerOrChiefDeveloperOrDAO() {
        isOwnerOrChiefDeveloperOrDAO();
        _;
    }
    modifier onlyOwnerOrArtistOrDAO() {
        isOwnerOrArtistOrDAO();
        _;
    }
    modifier onlyOwnerOrChiefArtist() {
        isOwnerOrChiefArtist();
        _;
    }
    modifier onlyOwnerOrChiefArtistOrDAO() {
        isOwnerOrChiefArtistOrDAO();
        _;
    }
    modifier onlyOnImplementationOrDAO() {
        isOnImplementationOrDAO();
        _;
    }
    modifier onlyOwnerOrDAO() {
        isOwnerOrDAO();
        _;
    }
    modifier onlyOnImplementationOrPaused() {
        isOnImplementationOrPaused();
        _;
    }
    modifier onlyOnImplementation() {
        isOnImplementation();
        _;
    }

    /************************** ^MODIFIERS REGION ***************************************************** */

    /**
     *IN
     *OUT
     *if given address is owner
     */
    function isOwner(address _address) external view override returns (bool) {
        return owner() == _address;
    }

    function isOwnerOrChiefArtist() internal view {
        require(
            msg.sender == owner() || msg.sender == queenPalace.artist(),
            "Not Owner, Chief Artist"
        );
    }

    function isOwnerOrChiefArtistOrDAO() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == queenPalace.artist() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Artist, DAO"
        );
    }

    function isOwnerOrChiefDeveloperOrDAO() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == queenPalace.developer() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Chief Developer, DAO"
        );
    }

    function isOwnerOrArtistOrDAO() internal view {
        require(
            msg.sender == owner() ||
                queenPalace.isArtist(msg.sender) ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Artist, DAO"
        );
    }

    function isOnImplementationOrDAO() internal view {
        require(
            queenPalace.isOnImplementation() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not On Implementation sender not DAO"
        );
    }

    function isOnImplementation() internal view {
        require(queenPalace.isOnImplementation(), "Not On Implementation");
    }

    function isOnImplementationOrPaused() internal view {
        require(
            queenPalace.isOnImplementation() || paused(),
            "Not On Implementation,Paused"
        );
    }

    function isOwnerOrDAO() internal view {
        require(
            msg.sender == owner() || msg.sender == queenPalace.daoExecutor(),
            "Not Owner, DAO"
        );
    }

    function isOwnerOrDeveloperOrDAO() internal view {
        require(
            msg.sender == owner() ||
                queenPalace.isDeveloper(msg.sender) ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Developer, DAO"
        );
    }
}
