// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";

abstract contract IOriginNftUpgradeable is
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    uint256 m_token_id;
    mapping(uint256 => uint256) m_token_to_athlete;
    mapping(uint256 => uint256) m_athlete_to_token;

    address m_approved_caller;

    function __IOriginNftUpgradeable_init(
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        __IOriginNftUpgradeable_init_unchained(_name, _symbol);
    }

    function __IOriginNftUpgradeable_init_unchained(
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        m_approved_caller = address(0);
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

    function getTokenCount() external view virtual returns (uint256) {
        return m_token_id;
    }

    function getAthleteForToken(uint256 _token_id)
        public
        view
        virtual
        returns (uint256)
    {
        return m_token_to_athlete[_token_id];
    }

    event OriginNftMinted(
        address indexed athlete_wallet,
        uint256 indexed athlete_id,
        uint256 indexed token_id
    );

    function mintOriginNft(
        string calldata _signature_uri,
        uint256 _on_chain_ath_id,
        address _athlete
    ) public virtual allowedCaller {
        // checks: athlete does not already have an origin nft
        require(
            m_athlete_to_token[_on_chain_ath_id] == 0,
            "ath already has nft"
        );

        // effects: new token id
        m_token_id++;

        console.log(
            "In[mintOriginNft] _on_chain_ath_id[%d] m_token_id[%d]",
            _on_chain_ath_id,
            m_token_id
        );

        // effects: update map(s)
        m_token_to_athlete[m_token_id] = _on_chain_ath_id;
        m_athlete_to_token[_on_chain_ath_id] = m_token_id;

        // interaction: mint new token to athlete
        _mint(_athlete, m_token_id);
        assert(ownerOf(m_token_id) == _athlete);

        // interaction: set the uri of athletes signature
        _setTokenURI(m_token_id, _signature_uri);

        // emit event with new token id
        emit OriginNftMinted(_athlete, _on_chain_ath_id, m_token_id);
    }
}
