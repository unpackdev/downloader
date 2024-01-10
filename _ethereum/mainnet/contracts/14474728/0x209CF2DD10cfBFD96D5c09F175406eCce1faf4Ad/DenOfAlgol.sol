// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./IShatteredEON.sol";
import "./IImperialGuild.sol";
import "./IRAW.sol";
import "./IEON.sol";
import "./IColonist.sol";
import "./IPirates.sol";

contract DenOfAlgol is Pausable {
    uint8 public onosiaLiquorId;
    // shard Ids
    uint256 public spearId;
    uint256 public templeId;
    uint256 public riotId;
    uint256 public phantomId;

    // activate shard minting 
    bool public shardsActive;
    // address => used in allowing system communication between contracts
    mapping(address => bool) private admins;
    //owner
    address public auth;
    // reference to raw resource contract
    IRAW public RAW;
    // reference to refined EON for minting and burning
    IEON public EON;
    // reference to the pirate NFT collection
    IPirates public pirateNFT;
    // reference to the colonist NFT collection
    IColonist public colonistNFT;
    // reference to the ImperialGuild collection
    IImperialGuild public imperialGuild;
    //reference to main game logic
    IShatteredEON public shattered;

    constructor() {
        _pause();
        auth = msg.sender;
        admins[msg.sender] = true;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(RAW) != address(0) &&
                address(EON) != address(0) &&
                address(pirateNFT) != address(0) &&
                address(colonistNFT) != address(0) &&
                address(imperialGuild) != address(0) &&
                address(shattered) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _RAW,
        address _EON,
        address _pirateNFT,
        address _colonistNFT,
        address _imperialGuild,
        address _shatteredEON
    ) external onlyOwner {
        RAW = IRAW(_RAW);
        EON = IEON(_EON);
        pirateNFT = IPirates(_pirateNFT);
        colonistNFT = IColonist(_colonistNFT);
        imperialGuild = IImperialGuild(_imperialGuild);
        shattered = IShatteredEON(_shatteredEON);
    }

    // $rEON or EON exchange amount handled within ImperialGuild contract
    // Will fail if sender doesn't have enough $rEON or $EON or does not
    // provide the required sacrafices,
    // Transfer does not need approved,
    // as there is established trust between this contract and the ImperialGuild contract

    function buySpear(bool RAWPayment) external whenNotPaused noCheaters {
        require(shardsActive = true, "Shard minting not available yet");
        require(tx.origin == msg.sender, "Only EOA");
        if (RAWPayment) {
            imperialGuild.mint(spearId, 1, 1, msg.sender);
        } else {
            imperialGuild.mint(spearId, 0, 1, msg.sender);
        }
    }

    function buyTemple(bool RAWPayment) external whenNotPaused noCheaters {
        require(shardsActive = true, "Shard minting not available yet");
        require(tx.origin == msg.sender, "Only EOA");
        if (RAWPayment) {
            imperialGuild.mint(templeId, 1, 1, msg.sender);
        } else {
            imperialGuild.mint(templeId, 0, 1, msg.sender);
        }
    }

    function makeOnosiaLiquor(uint16 qty, bool RAWPayment)
        external
        whenNotPaused
        noCheaters
    {
        require(tx.origin == msg.sender);
        require(onosiaLiquorId > 0, "wrong tokenId");
        if (RAWPayment) {
            imperialGuild.mint(onosiaLiquorId, 1, qty, msg.sender);
        } else {
            imperialGuild.mint(onosiaLiquorId, 0, qty, msg.sender);
        }
    }

    function buyRiot(uint256 colonistId, bool RAWPayment)
        external
        whenNotPaused
        noCheaters
    {
        require(shardsActive = true, "Shard minting not available yet");
        require(tx.origin == msg.sender);
        // Must check this, as getTokenTraits will be allowed since this contract is an admin
        if (RAWPayment) {
            // This will check if origin is the owner of the token
            colonistNFT.burn(colonistId);
            imperialGuild.mint(riotId, 1, 1, msg.sender);
        } else {
            // check origin of owner of token
            colonistNFT.burn(colonistId);
            imperialGuild.mint(riotId, 0, 1, msg.sender);
        }
    }

    function buyPhantom(
        uint256 colonistId,
        uint256 pirateId,
        bool RAWPayment
    ) external whenNotPaused noCheaters {
        require(shardsActive = true, "Shard minting not available yet");
        require(tx.origin == msg.sender);
        // Must check this, as getTokenTraits will be allowed since this contract is an admin
        if (RAWPayment) {
            // check origin of tokens owner
            colonistNFT.burn(colonistId);
            pirateNFT.burn(pirateId);
            imperialGuild.mint(phantomId, 1, 1, msg.sender);
        } else {
            // check origin of token owner
            colonistNFT.burn(colonistId);
            pirateNFT.burn(pirateId);
            imperialGuild.mint(phantomId, 0, 1, msg.sender);
        }
    }

    function setOnosiaLiquorId(uint8 id) external onlyOwner {
        onosiaLiquorId = id;
    }

    function setShardIds(
        uint256 spear,
        uint256 temple,
        uint256 riot,
        uint256 phantom
    ) external onlyOwner {
        spearId = spear;
        templeId = temple;
        riotId = riot;
        phantomId = phantom;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    function toggleShardMinting(bool _shardsActive) external onlyOwner {
        shardsActive = _shardsActive;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disable
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }
}
