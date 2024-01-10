// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";

import "./AthleteLib.sol";
import "./DbToOnChainMapping.sol";

contract AthleteMap {
    uint256 m_athlete_id;
    mapping(uint256 => AthleteLib.Athlete) internal m_id_to_athlete;
    DbToOnChainMapping m_athlete_db_to_chain_id;

    constructor() {
        m_athlete_id = 0;
        m_athlete_db_to_chain_id = new DbToOnChainMapping();
    }

    modifier isValidAthleteId(uint256 _athlete_id) {
        require(_athlete_id > 0, "bad ath id");
        require(
            m_id_to_athlete[_athlete_id].sport != AthleteLib.Sport.None,
            "ath id dne"
        );
        _;
    }

    function getAthleteDbIdFromChainId(uint256 _chain_id)
        external
        view
        returns (uint256)
    {
        return m_athlete_db_to_chain_id.getDbIdFromChainId(_chain_id);
    }

    function getAthleteIdFromDbId(uint256 _db_id)
        public
        view
        returns (uint256)
    {
        return m_athlete_db_to_chain_id.getChainId(_db_id);
    }

    function dbAthleteExistsOnChain(uint256 _db_id) public view returns (bool) {
        return m_athlete_db_to_chain_id.dbExistsOnChain(_db_id);
    }

    function addAthlete(
        uint256 _db_id,
        bytes32 _name,
        AthleteLib.Sport _sport,
        uint8 _player_number,
        AthleteLib.PlayerPosition _player_position
    ) public returns (uint256) {
        require(
            !dbAthleteExistsOnChain(_db_id),
            "on-chain entry exists for db id"
        );

        m_athlete_id++;

        // update mappings: map1: db id to chain id
        m_athlete_db_to_chain_id.addDbToOnChainMapping(_db_id, m_athlete_id);

        // update mappings: map2: chain id to athlete on-chain identity
        m_id_to_athlete[m_athlete_id] = AthleteLib.Athlete({
            player_name: _name,
            sport: _sport,
            player_number: _player_number,
            player_position: _player_position
        });

        return m_athlete_id;
    }

    function getAthleteCount() public view returns (uint256) {
        return m_athlete_id;
    }

    function getAthlete(uint256 _on_chain_id)
        external
        view
        isValidAthleteId(_on_chain_id)
        returns (AthleteLib.Athlete memory)
    {
        return m_id_to_athlete[_on_chain_id];
    }
}
