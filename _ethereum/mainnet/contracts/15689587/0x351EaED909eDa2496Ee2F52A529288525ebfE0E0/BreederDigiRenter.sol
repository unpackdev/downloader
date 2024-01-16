// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./DigiDaigaku.sol";
import "./DigiDaigakuHeroes.sol";
import "./DigiDaigakuSpirits.sol";
import "./HeroAdventure.sol";
import "./ERC20.sol";
import "./Context.sol";
import "./Address.sol";

contract BreederDigiRenter is AdventurePermissions {
    DigiDaigaku public genesisToken;
    DigiDaigakuHeroes public heroToken;
    DigiDaigakuSpirits public spiritToken;
    HeroAdventure public adventure;

    uint256 public constant FORCE_CLAIM_WINDOW = 1 days;
    uint256 public constant HERO_QUEST_DURATION = 1 days;

    mapping(uint16 => uint256) public genesisFee;

    mapping(uint16 => bool) public genesisIsDeposited;
    mapping(uint16 => bool) public genesisIsOnAdventure;

    mapping(uint16 => address) private _genesisOwner;
    mapping(uint16 => address) private _spiritOwner;

    mapping(uint16 => uint16) private _spiritGenesisAdventurePair;
    mapping(uint16 => uint16) private _genesisSpiritAdventurePair;

    mapping(uint16 => uint256) private _genesisQuestStart;

    event GenesisDeposited(uint16 indexed genesisId, address indexed genesisOwner, uint256 fee);
    event GenesisWithdrawn(uint16 indexed genesisId, address indexed genesisOwner);
    event GenesisFeeUpdated(uint16 indexed genesisId, uint256 oldFee, uint256 newFee);

    event HeroOnQuest(
        uint16 indexed spiritId,
        uint16 genesisId,
        address indexed spiritOwner,
        address indexed genesisOwner,
        uint256 fee
    );

    event HeroMinted(uint16 indexed spiritId, uint16 indexed genesisId, address indexed spiritOwner);
    event ForceClaim(uint16 indexed spiritId, uint16 indexed genesisId, address indexed genesisOwner);

    modifier onlyGenesisOwner(uint16 genesisId) {
        require(
            _msgSender() == _genesisOwner[genesisId],
            "BreederDigiRenter.onlyGenesisOwner: not owner of genesis"
        );
        _;
    }

    modifier onlySpiritOwner(uint16 spiritId) {
        require(
            _msgSender() == _spiritOwner[spiritId],
            "BreederDigiRenter.onlySpiritOwner: not owner of spirit"
        );
        _;
    }

    modifier onlyGenesisAvailable(uint16 genesisId) {
        require(
            genesisIsDeposited[genesisId],
            "BreederDigiRenter.onlyGenesisAvailable: genesis not deposited"
        );
        require(
            !genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.onlyGenesisAvailable: genesis is on adventure"
        );
        _;
    }

    constructor(
        address _genesisToken,
        address _heroToken,
        address _spiritToken,
        address _adventure
    ) {
        genesisToken = DigiDaigaku(_genesisToken);
        heroToken = DigiDaigakuHeroes(_heroToken);
        spiritToken = DigiDaigakuSpirits(_spiritToken);
        adventure = HeroAdventure(_adventure);

        spiritToken.setAdventuresApprovedForAll(address(adventure), true);
    }

    function depositGenesis(uint16 genesisId, uint256 fee) public {
        genesisToken.transferFrom(_msgSender(), address(this), genesisId);
        _genesisOwner[genesisId] = _msgSender();
        genesisFee[genesisId] = fee;
        genesisIsDeposited[genesisId] = true;

        emit GenesisDeposited(genesisId, _msgSender(), fee);
    }

    function depositMultipleGenesis(
        uint16[] memory genesisIds,
        uint256[] memory fees
    ) external {
        require(
            genesisIds.length == fees.length,
            "BreederDigiRenter.depositMultipleGenesis: incompatible count of values"
        );
        for (uint256 i = 0; i < genesisIds.length; i++) {
            depositGenesis(genesisIds[i], fees[i]);
        }
    }

    function withdrawGenesis(uint16 genesisId)
        external
        onlyGenesisAvailable(genesisId)
        onlyGenesisOwner(genesisId)
    {
        genesisToken.transferFrom(address(this), _msgSender(), genesisId);
        _genesisOwner[genesisId] = address(0);
        genesisFee[genesisId] = 0;
        genesisIsDeposited[genesisId] = false;

        emit GenesisWithdrawn(genesisId, _msgSender());
    }

    function updateGenesisFee(uint16 genesisId, uint256 newFee)
        external
        onlyGenesisAvailable(genesisId)
        onlyGenesisOwner(genesisId)
    {
        uint256 oldFee = genesisFee[genesisId];
        genesisFee[genesisId] = newFee;

        emit GenesisFeeUpdated(genesisId, oldFee, newFee);
    }

    /**
     * @notice Provide owned spiritId and available genesisId, fee is to explicit to prevent sandwich attack
     */
    function enterHeroQuest(uint16 spiritId, uint16 genesisId)
        external
        payable
        onlyGenesisAvailable(genesisId)
    {
        require(
            spiritToken.ownerOf(spiritId) == _msgSender(),
            "BreederDigiRenter.enterHeroQuest: not owner of spirit"
        );

        require(
            genesisFee[genesisId] == msg.value,
            "BreederDigiRenter.enterHeroQuest: fee has changed"
        );

        _spiritOwner[spiritId] = _msgSender();
        genesisIsOnAdventure[genesisId] = true;
        _genesisSpiritAdventurePair[genesisId] = spiritId;
        _spiritGenesisAdventurePair[spiritId] = genesisId;
        _genesisQuestStart[genesisId] = block.timestamp;

        spiritToken.transferFrom(_msgSender(), address(this), spiritId);
        genesisToken.approve(address(adventure), genesisId);
        adventure.enterQuest(spiritId, genesisId);

        // sent eth to genesis owner
        Address.sendValue(payable(_genesisOwner[genesisId]), msg.value);

        emit HeroOnQuest(spiritId, genesisId, _msgSender(), _genesisOwner[genesisId], msg.value);
    }

    function mintHero(uint16 spiritId) external onlySpiritOwner(spiritId) {
        uint16 genesisId = _spiritGenesisAdventurePair[spiritId];

        require(
            genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.mintHero: genesis is not on adventure"
        );

        // set values back to zero
        _spiritOwner[spiritId] = address(0);
        genesisIsOnAdventure[genesisId] = false;
        _genesisSpiritAdventurePair[genesisId] = uint16(0);
        _spiritGenesisAdventurePair[spiritId] = uint16(0);
        _genesisQuestStart[genesisId] = 0;

        adventure.exitQuest(spiritId, true);
        heroToken.transferFrom(address(this), _msgSender(), spiritId);

        emit HeroMinted(spiritId, genesisId, _msgSender());
    }

    function forceClaim(uint16 genesisId) external {
        uint16 spiritId = _genesisSpiritAdventurePair[genesisId];

        require(
            _msgSender() == _genesisOwner[genesisId],
            "BreederDigiRenter.forceClaim: not owner of genesis"
        );

        require(
            genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.forceClaim: genesis is not on adventure"
        );

        require(
            _genesisQuestStart[genesisId] +
                HERO_QUEST_DURATION +
                FORCE_CLAIM_WINDOW <
                block.timestamp,
            "BreederDigiRenter.forceClaim: force claim window not yet active"
        );

        address spiritOwner = _spiritOwner[spiritId];

        // set values back to zero
        _spiritOwner[spiritId] = address(0);
        genesisIsOnAdventure[genesisId] = false;
        _genesisSpiritAdventurePair[genesisId] = uint16(0);
        _spiritGenesisAdventurePair[spiritId] = uint16(0);
        _genesisQuestStart[genesisId] = 0;

        adventure.exitQuest(spiritId, true);
        heroToken.transferFrom(address(this), spiritOwner, spiritId);

        emit HeroMinted(spiritId, genesisId, spiritOwner);
        emit ForceClaim(spiritId, genesisId, _msgSender());
    }
}
