// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";

import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";

abstract contract IAthleteSponsorshipNftUpgradeable is
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    uint256 m_token_id;
    mapping(uint256 => uint256) m_token_to_sponsorship_origination;
    mapping(uint256 => bool) m_token_is_upgraded;

    address m_approved_caller;

    function __IAthleteSponsorshipNft_init(
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        __IAthleteSponsorshipNft_init_unchained(_name, _symbol);
    }

    function __IAthleteSponsorshipNft_init_unchained(
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        m_approved_caller = address(0);
    }

    modifier isValidTokenId(uint256 _id) {
        require(_id > 0, "bad token val");
        require(_exists(_id), "token DNE");
        _;
    }

    modifier allowedCaller() {
        require(
            msg.sender == owner() || msg.sender == m_approved_caller,
            "INVALID CALLER"
        );
        _;
    }

    function setApprovalForCaller(address _operator)
        external
        virtual
        onlyOwner
    {
        console.log(
            "In[setApprovalForCaller] _operator[%s] owner[%s] m_approved_caller[%s]",
            _operator,
            owner(),
            m_approved_caller
        );
        m_approved_caller = _operator;
    }

    function fetchMySponsorshipNfts()
        external
        view
        virtual
        returns (uint256[] memory)
    {
        // init output array
        uint256 token_count = balanceOf(msg.sender);
        console.log(
            "In[fetchMySponsorshipNfts] token_count[%d] msg.sender[%s]",
            token_count,
            msg.sender
        );
        uint256[] memory token_ids = new uint256[](token_count);

        // early exit - no tokens
        if (token_count == 0) return token_ids;

        // go through all token ids and find those that belong to caller
        uint256 index = 0;
        for (uint256 id = 1; id <= m_token_id; id++) {
            if (ownerOf(id) == msg.sender) {
                token_ids[index] = id;
                index++;
            }
        }
        // return
        return token_ids;
    }

    function getTokenCount() external view virtual returns (uint256) {
        return m_token_id;
    }

    function getTokenOwner(uint256 _token_id)
        external
        view
        virtual
        isValidTokenId(_token_id)
        returns (address)
    {
        return ownerOf(_token_id);
    }

    function isSponsorshipUpgraded(uint256 _token_id)
        external
        view
        virtual
        returns (bool)
    {
        return m_token_is_upgraded[_token_id];
    }

    function setSponsorshipUpgraded(uint256 _token_id, bool _val)
        public
        virtual
    {
        m_token_is_upgraded[_token_id] = _val;
    }

    function getTokenOriginationId(uint256 _token_id)
        public
        view
        virtual
        returns (uint256)
    {
        return m_token_to_sponsorship_origination[_token_id];
    }

    function mintSponsorship(
        string calldata _token_uri,
        uint256 _origination_id,
        address _to
    ) public virtual allowedCaller returns (uint256) {
        require(_origination_id > 0, "MINT: BAD ORIG ID");

        // new token
        m_token_id++;

        // update local map(s)
        m_token_to_sponsorship_origination[m_token_id] = _origination_id;
        // will be upgraded on Signing Day if athlete has onboarded
        m_token_is_upgraded[m_token_id] = false;

        console.log(
            "IN[AthleteSponsorshipNft::initSponsorship] new_token_id[%d] _token_uri[%s] _to[%s]",
            m_token_id,
            _token_uri,
            _to
        );

        // mint it
        _mint(_to, m_token_id);
        assert(ownerOf(m_token_id) == _to);

        // give it the uri of its sponsorship metadata
        _setTokenURI(m_token_id, _token_uri);

        // return the new token id
        return m_token_id;
    }

    function upgradeSponsorshipUri(
        uint256 _token_id,
        string calldata _signature_uri
    ) public virtual allowedCaller {
        _setTokenURI(_token_id, _signature_uri);
    }

    function burnOnRefund(uint256 _token_id) public virtual allowedCaller {
        _burn(_token_id);
    }

    function getUpgradeEligibleTokens()
        external
        view
        virtual
        returns (uint256[] memory token_ids)
    {
        // get the # of eligible tokens
        uint256 eligible_token_count = 0;
        for (uint256 id = 1; id <= m_token_id; id++) {
            if (!m_token_is_upgraded[id]) eligible_token_count++;
        }

        // init array of eligible tokens
        token_ids = new uint256[](eligible_token_count);

        // is there work to be done here?
        if (eligible_token_count > 0) {
            // populate array of eligible tokens
            uint256 index = 0;
            for (uint256 id = 1; id <= m_token_id; id++) {
                if (!m_token_is_upgraded[id]) {
                    token_ids[index] = id;
                    index++;
                }
            }
            assert(index == eligible_token_count);
        }
    }
}
