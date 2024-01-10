// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";

import "./AthleteMap.sol";
import "./AthleteSponsorshipUtils.sol";
import "./SponsorshipRounds.sol";

contract AthleteSponsorshipMap is AthleteMap, SponsorshipRounds, Ownable {
    //---------------------------------- member vars ------------------------------------

    uint256 private m_athlete_sponsorship_id;
    mapping(uint256 => AthleteSponsorshipUtils.AthleteSponsorship)
        internal m_id_to_athlete_sponsorship;

    uint256 private m_sponsor_origination_id;
    mapping(uint256 => AthleteSponsorshipUtils.SponsorshipOrigination) m_id_to_sponsorship_origination;

    // TODO: verify that you are using this
    // mapping: base attributes id => athlete id => athlete sponsorship id
    mapping(uint256 => mapping(uint256 => uint256)) m_sponsor_round_to_athlete_to_athlete_sponsorship;

    //---------------------------------- member vars ------------------------------------

    constructor() {
        m_athlete_sponsorship_id = 0;
    }

    //---------------------------------- modifiers ------------------------------------

    function isValidSponsorAttributes(uint256 _id) public view returns (bool) {
        return m_id_to_sponsorship_origination[_id].athlete_sponsorship_id > 0;
    }

    modifier modIsValidSponsorAttributesId(uint256 _id) {
        require(isValidSponsorAttributes(_id), "invalid sponsor attributes id");
        _;
    }

    modifier isValidAthleteSponsorshipId(uint256 _id) {
        require(
            m_id_to_athlete_sponsorship[_id].athlete_id > 0,
            "invalid athlete sponsorship id"
        );
        _;
    }

    //---------------------------------- modifiers ------------------------------------

    //---------------------------------- events ------------------------------------

    event InitAthleteSponsorship(uint256 id);

    //---------------------------------- events ------------------------------------

    //---------------------------------- methods ------------------------------------
    function getAthleteSponsorshipCount() public view returns (uint256) {
        return m_athlete_sponsorship_id;
    }

    function initAthleteSponsorship(
        uint256 _athlete_id,
        uint256 _sponsorship_round_id,
        uint256 _funds_for_athlete
    )
        internal
        isValidAthleteId(_athlete_id)
        returns (
            uint256 new_athlete_sponsorship_id,
            uint256 new_sponsor_attributes_id
        )
    {
        require(
            m_sponsor_round_to_athlete_to_athlete_sponsorship[
                _sponsorship_round_id
            ][_athlete_id] == 0,
            "sponsorship already exists"
        );
        require(isValidRoundChainId(_sponsorship_round_id), "bad round id");

        m_athlete_sponsorship_id++;

        console.log(
            "IN[ContainerAthlete::initAthleteSponsorship]: _athlete_id[%d] _base_attributes_id[%d] sponsorship_id[%d]",
            _athlete_id,
            _sponsorship_round_id,
            m_athlete_sponsorship_id
        );

        // init sponsorship for this athlete
        // first sponsor gets the first of these sponsorships (for free having paid gas)
        m_id_to_athlete_sponsorship[
            m_athlete_sponsorship_id
        ] = AthleteSponsorshipUtils.AthleteSponsorship({
            athlete_id: _athlete_id,
            round_id: _sponsorship_round_id,
            claimed: 1,
            funds_committed: _funds_for_athlete,
            funds_claimed_by_athlete: false,
            refund_eligible: false
        });

        // first sponsor gets the first of these sponsorships - create record of this
        m_sponsor_origination_id++;

        // add to lookup map
        m_id_to_sponsorship_origination[
            m_sponsor_origination_id
        ] = AthleteSponsorshipUtils.SponsorshipOrigination({
            price: msg.value,
            athlete_sponsorship_id: m_athlete_sponsorship_id,
            serial: 1
        });

        m_sponsor_round_to_athlete_to_athlete_sponsorship[
            _sponsorship_round_id
        ][_athlete_id] = m_athlete_sponsorship_id;

        // return ids of new on-chain elements
        return (m_athlete_sponsorship_id, m_sponsor_origination_id);
    }

    function getAthleteSponsorshipId(
        uint256 _ath_id,
        uint256 _sponsorship_round_id
    ) public view returns (uint256) {
        return
            m_sponsor_round_to_athlete_to_athlete_sponsorship[
                _sponsorship_round_id
            ][_ath_id];
    }

    function _athleteSponsorshipHasCapacity(uint256 _athlete_sponsorship_id)
        internal
        view
        isValidAthleteSponsorshipId(_athlete_sponsorship_id)
        returns (bool)
    {
        console.log(
            "IN[ContainerAthlete::_athleteSponsorshipHasCapacity]: _athlete_sponsorship_id[%d]",
            _athlete_sponsorship_id
        );

        (uint256 capacity, uint256 claimed) = getAthleteSponsorshipNumbers(
            _athlete_sponsorship_id
        );

        console.log(
            "IN[ContainerAthlete::_athleteSponsorshipHasCapacity]: claimed[%d], capacity[%d]",
            claimed,
            capacity
        );

        return claimed < capacity;
    }

    function addToAthleteSponsorship(
        uint256 _athlete_sponsorship_id,
        uint256 _funds_for_athlete
    )
        internal
        isValidAthleteSponsorshipId(_athlete_sponsorship_id)
        returns (uint256)
    {
        console.log(
            "IN[ContainerAthlete::addToAthleteSponsorship]: _athlete_sponsorship_id[%d] _price[%d]",
            _athlete_sponsorship_id,
            _funds_for_athlete
        );

        // checks: sponsorship has capacity
        require(
            _athleteSponsorshipHasCapacity(_athlete_sponsorship_id),
            "no capacity"
        );
        // checks: sponsorship round still open
        require(
            m_id_to_round_info[
                m_id_to_athlete_sponsorship[_athlete_sponsorship_id].round_id
            ].is_open,
            "not open"
        );

        // get current state of sponsorship
        AthleteSponsorshipUtils.AthleteSponsorship
            storage sponsorship = m_id_to_athlete_sponsorship[
                _athlete_sponsorship_id
            ];

        // capacity there -> update the sponsorship state
        console.log(
            "IN[ContainerAthlete::_fanSubmitsSponsorshipForAthlete]: sponsorship: ath_id[%d] claimed[%d] funds_committed[%d]",
            sponsorship.athlete_id,
            sponsorship.claimed,
            sponsorship.funds_committed
        );

        // state - sponsorships claimed
        sponsorship.claimed++;

        // state - funds committed
        sponsorship.funds_committed += _funds_for_athlete;

        // init local record of sponsor
        m_sponsor_origination_id++;

        // add to lookup(s)
        m_id_to_sponsorship_origination[
            m_sponsor_origination_id
        ] = AthleteSponsorshipUtils.SponsorshipOrigination({
            price: _funds_for_athlete,
            athlete_sponsorship_id: _athlete_sponsorship_id,
            serial: sponsorship.claimed
        });

        console.log(
            "IN[ContainerAthlete::_fanSubmitsSponsorshipForAthlete]: sponsorship (after update): id[%d] claimed[%d] funds_committed[%d]",
            _athlete_sponsorship_id,
            sponsorship.claimed,
            sponsorship.funds_committed
        );

        // return new sponsorship attributes id
        return m_sponsor_origination_id;
    }

    function getAthleteSponsorship(uint256 _athlete_sponsorship_id)
        external
        view
        returns (AthleteSponsorshipUtils.AthleteSponsorship memory sponsorship)
    {
        return m_id_to_athlete_sponsorship[_athlete_sponsorship_id];
    }

    function getAthleteSponsorshipNumbers(uint256 _athlete_sponsorship_id)
        public
        view
        returns (uint256 capacity, uint256 claimed)
    {
        // capacity is fixed for all sponsorships
        claimed = 0;
        capacity = 0;
        if (_athlete_sponsorship_id == 0) return (capacity, claimed);

        uint256 round_id = m_id_to_athlete_sponsorship[_athlete_sponsorship_id]
            .round_id;
        if (round_id == 0) return (capacity, claimed);

        // athlete sponsorship round exists -> get amount claimed
        claimed = m_id_to_athlete_sponsorship[_athlete_sponsorship_id].claimed;
        capacity = m_id_to_round_info[round_id].capacity;
    }

    function fetchSponsorshipStats()
        external
        view
        returns (uint256[] memory cumulative_sponsorship_funds)
    {
        cumulative_sponsorship_funds = new uint256[](m_athlete_id);

        // go through all athlete sponsorships
        for (
            uint256 sponsorship_id = 1;
            sponsorship_id <= m_athlete_sponsorship_id;
            sponsorship_id++
        ) {
            // get that sponsorship
            AthleteSponsorshipUtils.AthleteSponsorship
                storage ath_sponsorship = m_id_to_athlete_sponsorship[
                    sponsorship_id
                ];

            // get athlete for that sponsorship
            uint256 ath_id = ath_sponsorship.athlete_id;

            // output: set funds
            cumulative_sponsorship_funds[ath_id - 1] =
                cumulative_sponsorship_funds[ath_id - 1] +
                ath_sponsorship.funds_committed;
        }
        // end for, return
    }

    function setRefundEligible(uint256 _ath_sponsorship_id, bool _val)
        external
        onlyOwner
        isValidAthleteSponsorshipId(_ath_sponsorship_id)
    {
        m_id_to_athlete_sponsorship[_ath_sponsorship_id].refund_eligible = _val;
    }

    function isSponsorshipRefundEligible(uint256 _ath_sponsorship_id)
        external
        view
        returns (bool)
    {
        return m_id_to_athlete_sponsorship[_ath_sponsorship_id].refund_eligible;
    }
    //---------------------------------- methods ------------------------------------
}
