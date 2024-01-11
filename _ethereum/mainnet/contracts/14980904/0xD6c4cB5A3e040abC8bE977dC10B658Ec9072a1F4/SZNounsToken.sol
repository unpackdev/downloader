// SPDX-License-Identifier: GPL-3.0

/// @title The SZNouns ERC-721 token

/********************************************************************************
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@               @@@@@@@@@@@@@@               @@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@     \\\\@@@@@      @@@@@@@@@     \\\\@@@@      @@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@     \\\\\\@@@@@@@     @@@@@@     \\\\\\@@@@@@@     @@@@@@@@@@@@@@@@@ *
 * @@@@@@     \\\\\\\@@@@@@@@              \\\\\\\@@@@@@@@                  @@@ *
 * @@@@@@    \\\\\\\\@@@@@@@@@    @@@@    \\\\\\\\@@@@@@@@@    @@@@@@@@     @@@ *
 * @@@@@@@    \\\\\\\@@@@@@@@     @@@@     \\\\\\\@@@@@@@@     @@@@@@@@     @@@ *
 * @@@@@@@@    \\\\\\@@@@@@@     @@@@@@     \\\\\\@@@@@@@     @@@@@@@@@     @@@ *
 * @@@@@@@@@      \\\@@@@      @@@@@@@@@@      \\\@@@@      @@@@@@@@@@@     @@@ *
 * @@@@@@@@@@@@              @@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *
 ********************************************************************************/

pragma solidity ^0.8.6;

import "./INounsDescriptor.sol";
import "./INounsSeeder.sol";
import "./IProxyRegistry.sol";

import "./NounsToken.sol";

contract SZNounsToken is NounsToken {
    // The sznounders DAO address (creators org)
    address public sznoundersDAO;
    address public nounsDAO;

    uint256 private _currentNounId;

    event NounsDAOUpdated(address nounsDAO);

    constructor(
        address _sznoundersDAO,
        address _minter,
        INounsDescriptor _descriptor,
        INounsSeeder _seeder,
        IProxyRegistry _proxyRegistry,
        address _nounsDAO
    ) NounsToken(_sznoundersDAO, _minter, _descriptor, _seeder, _proxyRegistry) {
        sznoundersDAO = _sznoundersDAO;
        nounsDAO = _nounsDAO;
    }

    /**
     * @notice Require that the sender is the SZNounders DAO.
     */
    modifier onlySZNoundersDAO() {
        require(msg.sender == sznoundersDAO, 'Sender is not the sznounders DAO');
        _;
    }

    /**
     * @notice Set the NounsDAO <> SZNounders shared 1/2 multisig.
     * @dev Only callable by the sznounders DAO when not locked.
     */
    function setNounsDAO(address _nounsDAO) external onlySZNoundersDAO {
        nounsDAO = _nounsDAO;

        emit NounsDAOUpdated(_nounsDAO);
    }

    /**
     * @notice Mint a SZNoun to the minter, along with a possible
     * reward for:
     *   - SZNounders' reward (one per 20 minted)
     *   - NounsDAO reward (one per 20 minted), sent to a shared NounsDAO <> SZNounders shared 1/2 multisig
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        // 4121 is the total number of sznouns minted across first 5 years
        if (_currentNounId <= 4121 && _currentNounId % 20 == 0) {
            _mintTo(sznoundersDAO, _currentNounId++);
            _mintTo(nounsDAO, _currentNounId++);
        }
        return _mintTo(minter, _currentNounId++);
    }
}
