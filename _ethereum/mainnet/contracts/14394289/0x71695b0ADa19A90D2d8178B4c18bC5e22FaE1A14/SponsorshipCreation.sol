// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IAthleteSponsorshipNftUpgradeable.sol";
import "./AthleteSponsorshipMap.sol";
import "./Foundation.sol";
import "./SponsorshipCreationLib.sol";

contract SponsorshipCreation is AthleteSponsorshipMap {
    IAthleteSponsorshipNftUpgradeable m_sponsorship_nft;

    constructor(IAthleteSponsorshipNftUpgradeable _sponsorship_nft) {
        m_sponsorship_nft = _sponsorship_nft;
    }

    // region: events

    event OnChainAthleteCreated(
        address indexed sponsor,
        uint256 indexed chain_id,
        AthleteLib.Sport sport,
        bytes32 athlete_name
    );

    event OnChainSponsorshipRoundCreated(
        address indexed sponsor,
        uint256 indexed round,
        uint256 indexed season,
        uint256 chain_id,
        bytes32 location
    );

    event OnChainAthleteSponsorshipCreated(
        address indexed sponsor,
        uint256 indexed sponsorship_chain_id,
        uint256 indexed sponsorship_origination_chain_id,
        uint256 ath_chain_id,
        uint256 rnd_chain_id
    );

    event OnChainAthleteSponsorshipNftCreated(
        address indexed sponsor,
        uint256 indexed token_id,
        uint256 indexed athlete_id,
        uint256 sponsorship_originator_id,
        uint256 round_id
    );

    // endregion

    // region: methods: visibility = external; description = helper

    function doOnChainInitAudit(
        uint256 _db_id_ath,
        uint256 _db_id_sponsorship_round
    ) external view returns (SponsorshipCreationLib.OnChainInitAudit memory) {
        bool init_athlete = !dbAthleteExistsOnChain(_db_id_ath);
        bool init_sponsorship_round = !dbSponsorshipRoundExistsOnChain(
            _db_id_sponsorship_round
        );

        // now determine sponsorship serial
        uint16 sponsorship_serial = 1;
        if (!init_athlete && !init_sponsorship_round) {
            // not the first athlete sponsorship
            // -> determine how many have already been minted
            uint256 athlete_sponsorship_id = getAthleteSponsorshipId(
                getAthleteIdFromDbId(_db_id_ath),
                getSponsorshipRoundIdFromDbId(_db_id_sponsorship_round)
            );
            require(athlete_sponsorship_id > 0, "bad ath spnsr id");
            sponsorship_serial =
                m_id_to_athlete_sponsorship[athlete_sponsorship_id].claimed +
                1;
        }
        return
            SponsorshipCreationLib.OnChainInitAudit({
                init_athlete: init_athlete,
                init_sponsorship_round: init_sponsorship_round,
                sponsorship_serial: sponsorship_serial
            });
    }

    function buildOnChainAthleteInitStruct(
        uint256 _ath_db_id,
        bytes32 _ath_name,
        AthleteLib.Sport _ath_sport,
        uint8 _ath_number,
        AthleteLib.PlayerPosition _ath_position
    ) external pure returns (SponsorshipCreationLib.AthleteInitArgs memory) {
        return
            SponsorshipCreationLib.AthleteInitArgs({
                db_id: _ath_db_id,
                full_name: _ath_name,
                sport: _ath_sport,
                number: _ath_number,
                position: _ath_position
            });
    }

    function buildOnChainSponsorshipRoundInitStruct(
        uint256 _round_db_id,
        uint16 _sponsorship_season,
        uint256 _sponsorship_round,
        bytes32 _round_location,
        uint16 _capacity
    )
        external
        pure
        returns (SponsorshipCreationLib.SponsorshipRoundInitArgs memory)
    {
        return
            SponsorshipCreationLib.SponsorshipRoundInitArgs({
                db_id: _round_db_id,
                season: _sponsorship_season,
                round: _sponsorship_round,
                location: _round_location,
                capacity: _capacity
            });
    }

    // endregion

    function _mintSponsorshipNft(
        uint256 _sponsorship_origination_id,
        string calldata _token_uri
    ) internal {
        // checks guaranteed by caller
        console.log(
            "In[SponsorshipCreation::_mintSponsorshipNft] _sponsorship_holder_id[%d]",
            _sponsorship_origination_id
        );
        uint256 new_token_id = m_sponsorship_nft.mintSponsorship(
            _token_uri,
            _sponsorship_origination_id,
            msg.sender
        );
        // assert that token owner is caller
        assert(m_sponsorship_nft.ownerOf(new_token_id) == msg.sender);

        console.log(
            "In[SponsorshipCreation::_mintSponsorshipNft] new_token_id[%d]",
            new_token_id
        );

        // emit event
        uint256 sponsorship_id = m_id_to_sponsorship_origination[
            _sponsorship_origination_id
        ].athlete_sponsorship_id;

        emit OnChainAthleteSponsorshipNftCreated(
            msg.sender,
            new_token_id,
            m_id_to_athlete_sponsorship[sponsorship_id].athlete_id,
            _sponsorship_origination_id,
            m_id_to_athlete_sponsorship[sponsorship_id].round_id
        );
    }

    function _sponsorCreatesOnChainAthlete(
        SponsorshipCreationLib.AthleteInitArgs calldata _args
    ) private returns (uint256 new_on_chain_ath_id) {
        // add athlete to contract storage
        new_on_chain_ath_id = addAthlete(
            _args.db_id,
            _args.full_name,
            _args.sport,
            _args.number,
            _args.position
        );
        // emit event
        emit OnChainAthleteCreated(
            msg.sender,
            new_on_chain_ath_id,
            _args.sport,
            _args.full_name
        );
    }

    function _sponsorCreatesOnChainSponsorshipRound(
        SponsorshipCreationLib.SponsorshipRoundInitArgs calldata _args
    ) private returns (uint256 on_chain_new_round_id) {
        console.log(
            "In[SponsorshipCreation::sponsorCreatesOnChainSponsorshipRound] _round_db_id[%d] _sponsorship_season[%d] _sponsorship_round[%d]",
            _args.db_id,
            _args.season,
            _args.round
        );
        console.log(
            "In[SponsorshipCreation::sponsorCreatesOnChainSponsorshipRound] capacity[%d]",
            _args.capacity
        );

        // add sponsorship round to contract storage
        on_chain_new_round_id = initSponsorshipRound(
            _args.db_id,
            _args.season,
            _args.round,
            _args.location,
            _args.capacity
        );

        console.log(
            "In[SponsorshipCreation::sponsorCreatesOnChainSponsorshipRound] new_on_chain_id[%d]",
            on_chain_new_round_id
        );

        // emit event
        emit OnChainSponsorshipRoundCreated(
            msg.sender,
            _args.round,
            _args.season,
            on_chain_new_round_id,
            _args.location
        );
    }

    function _sponsorCreatesOnChainAthleteSponsorship(
        uint256 _new_athlete_id,
        uint256 _new_base_attributes_id,
        uint256 _funds_for_athlete
    )
        private
        returns (
            uint256 new_on_chain_ath_sponsorship_id,
            uint256 new_on_chain_origination_id
        )
    {
        console.log(
            "In[SponsorshipCreation::sponsorCreatesOnChainAthleteSponsorship] _new_athlete_id[%d] _new_base_attributes_id[%d]",
            _new_athlete_id,
            _new_base_attributes_id
        );

        // add new athlete sponsorship to contract storage
        (
            new_on_chain_ath_sponsorship_id,
            new_on_chain_origination_id
        ) = initAthleteSponsorship(
            _new_athlete_id,
            _new_base_attributes_id,
            _funds_for_athlete
        );

        console.log(
            "In[SponsorshipCreation::sponsorCreatesOnChainAthleteSponsorship] new_athlete_sponsorship_id[%d] new_sponsor_attributes_id[%d]",
            new_on_chain_ath_sponsorship_id,
            new_on_chain_origination_id
        );

        // emit event
        emit OnChainAthleteSponsorshipCreated(
            msg.sender,
            new_on_chain_ath_sponsorship_id,
            new_on_chain_origination_id,
            _new_athlete_id,
            _new_base_attributes_id
        );
    }

    function sponsorSubmits(
        SponsorshipCreationLib.OnChainInitAudit calldata _init_audit,
        SponsorshipCreationLib.AthleteInitArgs calldata _athlete_args,
        SponsorshipCreationLib.SponsorshipRoundInitArgs calldata _round_args,
        string calldata _token_uri
    ) external payable {
        uint256 on_chain_ath_id = 0;
        uint256 on_chain_round_id = 0;
        uint256 on_chain_origination_id = 0;
        uint256 on_chain_sponsorship_id = 0;
        console.log(
            "In[sponsorSubmits] init_athlete[%s] init_sponsorship_round[%s]",
            _init_audit.init_athlete,
            _init_audit.init_sponsorship_round
        );

        // call relevant initialization method based on what work must be done
        // on-chain for athlete
        if (_init_audit.init_athlete) {
            // init athlete
            on_chain_ath_id = _sponsorCreatesOnChainAthlete(_athlete_args);
        } else {
            // round exists - grab id based on db id
            on_chain_ath_id = getAthleteIdFromDbId(_athlete_args.db_id);
        }

        // on-chain for sponsorship round
        if (_init_audit.init_sponsorship_round) {
            // init round
            on_chain_round_id = _sponsorCreatesOnChainSponsorshipRound(
                _round_args
            );
        } else {
            // round exists - grab id based on db id
            on_chain_round_id = getSponsorshipRoundIdFromDbId(
                _round_args.db_id
            );
        }
        require(on_chain_ath_id > 0, "invalid ath id");
        require(on_chain_round_id > 0, "invalid round id");

        // if either athlete OR sponsorship round requires init
        // --> so does the athlete sponsorship
        if (_init_audit.init_athlete || _init_audit.init_sponsorship_round) {
            (
                ,
                on_chain_origination_id
            ) = _sponsorCreatesOnChainAthleteSponsorship(
                on_chain_ath_id,
                on_chain_round_id,
                msg.value
            );
        } else {
            // otherwise, sponsorship should already exist
            on_chain_sponsorship_id = getAthleteSponsorshipId(
                on_chain_ath_id,
                on_chain_round_id
            );
            // submit sponsorship
            on_chain_origination_id = addToAthleteSponsorship(
                on_chain_sponsorship_id,
                msg.value
            );
        }
        require(on_chain_origination_id > 0, "invalid origination id");

        // mint the sponsorship nft
        _mintSponsorshipNft(on_chain_origination_id, _token_uri);
    }

    // only agency can upgrade sponsorship nft (we pay the gas)
    function upgradeSponsorship(
        uint256 _token_id,
        string calldata _signature_uri
    ) external onlyOwner {
        // check: valid token value
        require(_token_id > 0, "bad token");
        // check: sponsorship not already upgraded
        require(
            !m_sponsorship_nft.isSponsorshipUpgraded(_token_id),
            "already upgraded"
        );
        // check: incoming uri is non-empty
        require(bytes(_signature_uri).length > 0, "bad uri");

        // effect: mark sponsorship as upgraded
        m_sponsorship_nft.setSponsorshipUpgraded(_token_id, true);

        // TODO: store a separate uri instead of directly updating pre-existing one?
        // interaction: upgrade the sponsorship uri
        m_sponsorship_nft.upgradeSponsorshipUri(_token_id, _signature_uri);
    }
}
