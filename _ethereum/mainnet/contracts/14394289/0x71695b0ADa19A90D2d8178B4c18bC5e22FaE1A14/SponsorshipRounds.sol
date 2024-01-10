// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";

import "./AthleteSponsorshipUtils.sol";
import "./DbToOnChainMapping.sol";

contract SponsorshipRounds {
    // region: member vars

    uint256 m_id;
    DbToOnChainMapping m_round_db_to_chain_id;

    // mapping 1
    // id -> struct
    mapping(uint256 => AthleteSponsorshipUtils.SponsorshipRoundInfo)
        internal m_id_to_round_info;

    // mapping 2
    // season -> type -> state -> city -> base attributes id
    mapping(uint256 => mapping(uint256 => mapping(string => mapping(string => uint256))))
        internal m_base_attributes;

    // endregion

    constructor() {
        m_id = 0;
        m_round_db_to_chain_id = new DbToOnChainMapping();
    }

    // region: modifiers
    function isValidRoundChainId(uint256 _chain_id) public view returns (bool) {
        return m_id_to_round_info[_chain_id].season > 0;
    }

    modifier modIsValidRoundChainId(uint256 _chain_id) {
        require(m_id_to_round_info[_chain_id].season > 0, "bad chain id");
        _;
    }

    // endregion

    function getSponsorshipRoundIdFromDbId(uint256 _db_id)
        public
        view
        returns (uint256)
    {
        return m_round_db_to_chain_id.getChainId(_db_id);
    }

    function getRoundDbIdFromChainId(uint256 _chain_id)
        external
        view
        returns (uint256)
    {
        return m_round_db_to_chain_id.getDbIdFromChainId(_chain_id);
    }

    function dbSponsorshipRoundExistsOnChain(uint256 _db_id)
        public
        view
        returns (bool)
    {
        return m_round_db_to_chain_id.dbExistsOnChain(_db_id);
    }

    function getSponsorshipRoundCount() external view returns (uint256) {
        return m_id;
    }

    function closeDbSponsorshipRound(uint256 _db_id) external {
        require(_db_id > 0, "bad db id");
        closeSponsorshipRound(getSponsorshipRoundIdFromDbId(_db_id));
    }

    function closeSponsorshipRound(uint256 _chain_id)
        internal
        modIsValidRoundChainId(_chain_id)
    {
        // update round status
        m_id_to_round_info[_chain_id].is_open = false;
    }

    function initSponsorshipRound(
        uint256 _db_id,
        uint16 _season,
        uint256 _type,
        bytes32 _location,
        uint16 _capacity
    ) public returns (uint256) {
        console.log("In[initSponsorshipRound] entering...");
        if (dbSponsorshipRoundExistsOnChain(_db_id)) {
            uint256 on_chain_id = getSponsorshipRoundIdFromDbId(_db_id);
            assert(m_id_to_round_info[on_chain_id].season > 0);
            console.log(
                "In[initSponsorshipRound] db_id[%d] exists on-chain with id[%d]...returning",
                _db_id,
                on_chain_id
            );
            return on_chain_id;
        }

        // extra nft type enum from numeric arg
        AthleteSponsorshipUtils.NftType type_enum = AthleteSponsorshipUtils
            .NftType(_type);
        require(
            type_enum != AthleteSponsorshipUtils.NftType.None,
            "invalid nft type"
        );

        // increment
        m_id += 1;

        // update lookup - base attributes - part 1
        m_id_to_round_info[m_id] = AthleteSponsorshipUtils
            .SponsorshipRoundInfo({
                season: _season,
                nft_type: type_enum,
                capacity: _capacity,
                location: _location,
                is_open: true
            });

        // update lookup - db to on-chain id
        m_round_db_to_chain_id.addDbToOnChainMapping(_db_id, m_id);

        console.log("In[initSponsorshipRound] leaving...new m_id[%d]", m_id);

        console.log("In[initSponsorshipRound] leaving...returning", m_id);

        // return new base attributes id
        return m_id;
    }
}
