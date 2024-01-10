// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract DbToOnChainMapping {
    mapping(uint256 => uint256) internal m_db_to_chain_id;
    mapping(uint256 => uint256) internal m_chain_to_db_id;

    modifier isValidDbId(uint256 _db_id) {
        require(_db_id > 0, "invalid db id");
        _;
    }

    function dbExistsOnChain(uint256 _db_id)
        public
        view
        isValidDbId(_db_id)
        returns (bool)
    {
        return m_db_to_chain_id[_db_id] > 0;
    }

    function addDbToOnChainMapping(uint256 _db_id, uint256 _chain_id)
        public
        isValidDbId(_db_id)
    {
        require(_chain_id > 0, "invalid chain id");
        require(m_db_to_chain_id[_db_id] == 0, "db entry already exists");

        // update mapping(s)
        m_db_to_chain_id[_db_id] = _chain_id;
        m_chain_to_db_id[_chain_id] = _db_id;
    }

    function getChainId(uint256 _db_id) public view returns (uint256) {
        // invariant: caller guarantees db id exists within mapping
        return m_db_to_chain_id[_db_id];
    }

    function getDbIdFromChainId(uint256 _chain_id)
        public
        view
        returns (uint256)
    {
        return m_chain_to_db_id[_chain_id];
    }
}
