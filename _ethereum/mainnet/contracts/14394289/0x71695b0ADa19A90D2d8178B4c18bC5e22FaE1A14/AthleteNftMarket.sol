// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";

import "./ReentrancyGuard.sol";

import "./EtherReceiver.sol";
import "./Foundation.sol";
import "./SponsorshipCreation.sol";
import "./SponsorshipCreationLib.sol";
import "./IOriginNftUpgradeable.sol";

contract AthleteNftMarket is
    ReentrancyGuard,
    SponsorshipCreation,
    EtherReceiver
{
    Foundation private m_foundation_contract;

    uint256 private m_sponsorship_price;

    constructor(
        Foundation _foundation_contract,
        IAthleteSponsorshipNftUpgradeable _sponsorship_nft
    ) SponsorshipCreation(_sponsorship_nft) {
        m_foundation_contract = _foundation_contract;

        // initial deployment of contract -> use v0 price
        if (m_sponsorship_price == 0) {
            m_sponsorship_price = SponsorshipCreationLib.SPONSOR_PRICE_V0;
        }
    }

    function setPrice(uint256 _new_price) external onlyOwner {
        m_sponsorship_price = _new_price;
    }

    function getSponsorshipPrice() external view returns (uint256) {
        return m_sponsorship_price;
    }

    // TODO: can this be a batch-execution method?
    // we airdrop to athletes wallet
    function mintOriginNftToOnChainAthlete(
        address _contract_origin_nft,
        string calldata _token_uri,
        uint256 _on_chain_ath_id,
        address _athlete_wallet
    ) external onlyOwner isValidAthleteId(_on_chain_ath_id) {
        console.log(
            "In[mintOriginNftToOnChainAthlete] on_chain_ath_id[%d] _athlete_wallet[%s]",
            _on_chain_ath_id,
            _athlete_wallet
        );

        // effects/interaction: mint the new origin nft
        IOriginNftUpgradeable(_contract_origin_nft).mintOriginNft(
            _token_uri,
            _on_chain_ath_id,
            _athlete_wallet
        );
    }

    event AthleteWithdrawsFunds(
        address indexed athlete_address,
        address indexed origin_nft_address,
        uint256 indexed token_id,
        uint256 amount
    );

    event SponsorshipCommission(
        address indexed athlete,
        uint256 indexed athlete_id,
        uint256 amount
    );

    // called by athlete
    // must have the relevant origin nft in his/her wallet
    function athleteWithdrawsFundsUsingOriginNft(
        address _origin_nft,
        uint256 _token_id
    ) public {
        console.log(
            "In[athleteWithdrawsFundsUsingOriginNft] _token_id[%d] msg.sender[%s]",
            _token_id,
            msg.sender
        );

        // checks: valid token
        require(_token_id > 0, "bad tok id");
        // checks: valid athlete id associated with this token
        uint256 on_chain_ath_id = IOriginNftUpgradeable(_origin_nft)
            .getAthleteForToken(_token_id);
        require(on_chain_ath_id > 0, "bad ath id");

        // checks: verify supplied wallet is owner of origin nft
        require(
            IOriginNftUpgradeable(_origin_nft).ownerOf(_token_id) == msg.sender,
            "not owner"
        );

        // get funds available for this athlete
        // -> go through all athlete sponsorships
        uint256 total_funds = 0;
        for (uint256 id = 1; id <= getAthleteSponsorshipCount(); id++) {
            if (m_id_to_athlete_sponsorship[id].athlete_id != on_chain_ath_id)
                continue;

            // sponsorship belongs to this athlete
            AthleteSponsorshipUtils.AthleteSponsorship
                storage ath_sponsorship = m_id_to_athlete_sponsorship[id];
            if (ath_sponsorship.funds_claimed_by_athlete) continue;

            // funds available?
            if (ath_sponsorship.funds_committed == 0) continue;
            uint256 funds_available = ath_sponsorship.funds_committed;

            // sponsorship round should be open
            assert(m_id_to_round_info[ath_sponsorship.round_id].is_open);

            // add to total pot
            total_funds += funds_available;

            // effect: mark funds as claimed
            ath_sponsorship.funds_claimed_by_athlete = true;
        }

        // checks: make sure we have this in escrow
        require(
            getBalance() >= total_funds,
            "contract without sufficient funds"
        );

        // take our rake
        uint256 our_rake = Foundation(m_foundation_contract)
            .calculateFoundationRakeForSalePrice(total_funds);
        assert(our_rake >= 0);
        assert(our_rake < total_funds);
        uint256 funds_for_athlete = total_funds - our_rake;

        // transfer funds to athlete
        {
            (bool sent, ) = payable(msg.sender).call{value: funds_for_athlete}(
                ""
            );
            require(sent, "transfer to ath failed");
        }

        // transfer rake to Foundation
        {
            (bool sent, ) = payable(m_foundation_contract).call{
                value: our_rake
            }("");
            require(sent, "transfer to foundation failed");
        }

        // emit event - athlete withdraw
        emit AthleteWithdrawsFunds(
            msg.sender,
            _origin_nft,
            _token_id,
            total_funds
        );

        // emit event - commission
        emit SponsorshipCommission(msg.sender, on_chain_ath_id, our_rake);
    }

    event SponsorshipRefund(
        uint256 indexed token_id,
        address indexed sponsor,
        uint256 indexed ath_id,
        uint256 price,
        uint256 ath_sponsorship_id,
        uint256 ath_sponsorship_origination_id
    );

    // called by token owner (they pay gas)
    function giveRefundForNonUpgradedSponsorship(uint256 _token_id)
        external
        nonReentrant
    {
        console.log(
            "In[refund] _token_id[%d] msg.sender[%s]",
            _token_id,
            msg.sender
        );

        // checks: signer is the token owner
        require(
            m_sponsorship_nft.getTokenOwner(_token_id) == msg.sender,
            "not the owner"
        );
        // checks: nft is not upgrade (b/c athlete never joined platform)
        require(
            !m_sponsorship_nft.isSponsorshipUpgraded(_token_id),
            "token already upgraded"
        );
        // get the origination id of this token
        uint256 sponsorship_origination_id = m_sponsorship_nft
            .getTokenOriginationId(_token_id);
        // checks: valid sponsorship origination id for this token
        require(sponsorship_origination_id > 0, "bad spnsrship orig id");

        console.log(
            "In[refund] sponsorship_origination_id[%d]",
            sponsorship_origination_id
        );

        // from that get: {price, ath sponsorship id}
        uint256 sponsorship_price = m_id_to_sponsorship_origination[
            sponsorship_origination_id
        ].price;
        uint256 athlete_sponsorship_id = m_id_to_sponsorship_origination[
            sponsorship_origination_id
        ].athlete_sponsorship_id;

        console.log(
            "In[refund] prc[%d] sponsorship_id[%d]",
            sponsorship_price,
            athlete_sponsorship_id
        );

        // checks: athlete sponsorship is refund-eligible
        require(
            m_id_to_athlete_sponsorship[athlete_sponsorship_id].refund_eligible,
            "not refund eligible"
        );

        // sanity checks
        assert(
            !m_id_to_athlete_sponsorship[athlete_sponsorship_id]
                .funds_claimed_by_athlete
        );
        assert(
            sponsorship_price <=
                m_id_to_athlete_sponsorship[athlete_sponsorship_id]
                    .funds_committed
        );
        assert(m_id_to_athlete_sponsorship[athlete_sponsorship_id].claimed > 0);

        AthleteSponsorshipUtils.AthleteSponsorship
            storage ath_sponsorship = m_id_to_athlete_sponsorship[
                athlete_sponsorship_id
            ];
        console.log(
            "In[refund] pre-refund state: claimed[%d] funds_committed[%d]",
            ath_sponsorship.claimed,
            ath_sponsorship.funds_committed
        );

        // effects: reverse the funds available to the athlete
        ath_sponsorship.funds_committed -= sponsorship_price;
        // effects: decrement the number of sponsorships claimed
        m_id_to_athlete_sponsorship[athlete_sponsorship_id].claimed--;

        console.log(
            "In[refund] post-refund state: claimed[%d] funds_committed[%d]",
            ath_sponsorship.claimed,
            ath_sponsorship.funds_committed
        );

        // effects: delete sponsorship origination entry
        delete m_id_to_sponsorship_origination[sponsorship_origination_id];

        // interaction: send funds back to sponsor
        (bool sent, ) = payable(msg.sender).call{value: sponsorship_price}("");
        require(sent, "refund failed");

        // interaction: burn sponsorship nft
        m_sponsorship_nft.burnOnRefund(_token_id);

        // emit event
        emit SponsorshipRefund(
            _token_id,
            msg.sender,
            m_id_to_athlete_sponsorship[athlete_sponsorship_id].athlete_id,
            sponsorship_price,
            athlete_sponsorship_id,
            sponsorship_origination_id
        );
    }
}
