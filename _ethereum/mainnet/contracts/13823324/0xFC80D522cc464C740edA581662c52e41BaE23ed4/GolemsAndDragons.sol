// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

interface IAGold {
    function burn(address _address, uint256 amount) external;
}

interface IRandom {
    function random(uint256 _seed, uint256 _limit)
        external
        view
        returns (uint16);
}

interface IBattleGround {
    function startTrainingTokens(address address_, uint16[] calldata tokens)
        external;
}

contract GolemsAndDragons is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    struct Stats {
        uint16 health;
        uint16 attack;
        uint16 defense;
        uint16 agility;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // Constants
    uint256 public constant MAX_TOKENS = 50000;
    uint256 public constant MAX_TX_AMOUNT = 5;

    // Public variables
    bool public paused;

    IAGold public AGold;
    IRandom public Random;
    IBattleGround public BattleGround;

    uint16 public totalGolems;
    uint16 public totalDragons;

    // Public mappings
    mapping(uint256 => uint256) public phasePrices;
    mapping(uint256 => uint256) public phaseBreakpoints;

    mapping(uint256 => uint256) public dragonIDs;
    mapping(uint256 => uint256) public golemIDs;
    mapping(uint256 => Stats) public tokenStats;

    string public dragonURI;
    string public golemURI;

    bytes32 public whitelistRoot;

    // Private variables
    mapping(uint256 => bool) private dragonMap;
    mapping(address => uint256) private dragonsBeforeGolem;
    mapping(address => bool) private statsEditor;

    uint16 private maxHealth;
    uint16 private maxAttack;
    uint16 private maxDefense;
    uint16 private maxAgility;

    bool private _whitelist;

    event ThatsAnAwfullyLargeAmountOfDragonsBuddy(
        address source,
        uint256 amount
    );

    modifier shouldBePaused() {
        require(
            paused,
            "GAD-721-E1" /*"Minting must be paused"*/
        );
        _;
    }

    modifier shouldNotBePaused() {
        require(
            !paused,
            "GAD-721-E2" /*"Minting must be unpaused"*/
        );
        _;
    }

    modifier onlyStatsEditor() {
        require(
            statsEditor[_msgSender()],
            "GAD-721-E3" /*"Must be able to edit stats"*/
        );
        _;
    }

    function initialize() public initializer {
        __ERC721_init("Golem Game", "GODR");
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        paused = true;

        phaseBreakpoints[0] = 10000;
        phaseBreakpoints[1] = 20000;
        phaseBreakpoints[2] = 30000;
        phaseBreakpoints[3] = 40000;

        phasePrices[1] = 0.069 ether;
        phasePrices[2] = 10000 ether;
        phasePrices[3] = 20000 ether;
        phasePrices[4] = 40000 ether;
        phasePrices[5] = 80000 ether;

        maxHealth = 1000;
        maxAttack = 100;
        maxDefense = 500;
        maxAgility = 75;

        statsEditor[_msgSender()] = true;
    }

    function mint(
        uint256 amount,
        bool train,
        bytes32[] calldata _merkleProof
    ) external payable shouldNotBePaused {
        require(
            totalSupply() + amount <= phaseBreakpoints[phase() - 1],
            "GAD-721-E4" //"Mint amount would surpass phase breakpoint"
        );
        require(
            totalSupply() + amount <= MAX_TOKENS,
            "GAD-721-E5" //"Cannot mint more tokens than limit"
        );
        require(
            amount > 0 && amount <= MAX_TX_AMOUNT,
            "GAD-721-E6" //"Cannot mint more tokens than TX limit"
        );
        require(
            !_whitelist || balanceOf(_msgSender()) + amount <= 3,
            "GAD-721-E9" // "Cannot mint more than 3 tokens in total when whitelist sale is active"
        );

        if (_whitelist) {
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            require(
                MerkleProofUpgradeable.verify(
                    _merkleProof,
                    whitelistRoot,
                    leaf
                ),
                "GAD-721-E10" // "Whitelist verification failed"
            );
        }

        if (phase() == 1) {
            require(
                msg.value == phasePrices[1] * amount,
                "GAD-721-E7" //"Value is below required amount"
            );
        } else {
            require(
                msg.value == 0,
                "GAD-721-E8" /*"Minting no longer requires ETH payment"*/
            );

            AGold.burn(msg.sender, phasePrices[phase()] * amount);
        }

        uint16[] memory tokenIds = train
            ? new uint16[](amount)
            : new uint16[](0);
        for (uint8 i = 0; i < amount; i++) {
            bool willBeDragon = false;
            uint256 tokenID = totalSupply() + 1;

            if (totalGolems == 45000) {
                willBeDragon = true;
            } else if (totalDragons == 5000) {
                willBeDragon = false;
            } else {
                willBeDragon = Random.random(totalSupply(), 100) >= 90;
            }

            if (willBeDragon) {
                dragonMap[tokenID] = true;
                dragonIDs[tokenID] = totalDragons + 1;
                tokenStats[tokenID] = Stats(300, 10, 0, 0);

                totalDragons++;
                dragonsBeforeGolem[_msgSender()]++;

                if (
                    dragonsBeforeGolem[_msgSender()] > 4 && totalGolems != 45000
                ) {
                    // This is becomming a bit sussy
                    emit ThatsAnAwfullyLargeAmountOfDragonsBuddy(
                        _msgSender(),
                        dragonsBeforeGolem[_msgSender()]
                    );
                }
            } else {
                golemIDs[tokenID] = totalGolems + 1;
                tokenStats[tokenID] = Stats(100, 10, 0, 0);

                totalGolems++;

                if (dragonsBeforeGolem[_msgSender()] > 0)
                    dragonsBeforeGolem[_msgSender()] = 0;
            }

            if (train) {
                _safeMint(address(BattleGround), tokenID);
                tokenIds[i] = uint16(tokenID);
            } else _safeMint(msg.sender, tokenID);
        }

        if (train) {
            BattleGround.startTrainingTokens(msg.sender, tokenIds);
        }
    }

    function addStats(
        uint256 tokenID,
        uint16 health,
        uint16 attack,
        uint16 defense,
        uint16 agility
    ) external onlyStatsEditor {
        if (health > 0) {
            if (dragonMap[tokenID])
                tokenStats[tokenID].health = (
                    tokenStats[tokenID].health + health > maxHealth * 3
                        ? maxHealth * 3
                        : tokenStats[tokenID].health + health
                );
            else
                tokenStats[tokenID].health = (
                    tokenStats[tokenID].health + health > maxHealth
                        ? maxHealth
                        : tokenStats[tokenID].health + health
                );
        }
        if (attack > 0)
            tokenStats[tokenID].attack = (
                tokenStats[tokenID].attack + attack > maxAttack
                    ? maxAttack
                    : tokenStats[tokenID].attack + attack
            );
        if (defense > 0)
            tokenStats[tokenID].defense = (
                tokenStats[tokenID].defense + defense > maxDefense
                    ? maxDefense
                    : tokenStats[tokenID].defense + defense
            );
        if (agility > 0)
            tokenStats[tokenID].agility = (
                tokenStats[tokenID].agility + agility > maxAgility
                    ? maxAgility
                    : tokenStats[tokenID].agility + agility
            );
    }

    function resetStats(uint256 tokenID) external onlyStatsEditor {
        tokenStats[tokenID] = dragonMap[tokenID]
            ? Stats(300, 10, 0, 0)
            : Stats(100, 10, 0, 0);
    }

    function phase() public view returns (uint8) {
        if (totalSupply() <= phaseBreakpoints[0]) {
            return 1;
        } else if (totalSupply() <= phaseBreakpoints[1]) {
            return 2;
        } else if (totalSupply() <= phaseBreakpoints[2]) {
            return 3;
        } else if (totalSupply() <= phaseBreakpoints[3]) {
            return 4;
        } else {
            return 5;
        }
    }

    function isDragon(uint256 token) external view returns (bool) {
        return dragonMap[token];
    }

    function isWhitelistOnly() external view returns (bool) {
        return _whitelist;
    }

    function setAGold(address _agold) external onlyOwner {
        AGold = IAGold(_agold);
    }

    function setRandom(address _random) external onlyOwner {
        Random = IRandom(_random);
    }

    function setBattleGround(address _battleground) external onlyOwner {
        BattleGround = IBattleGround(_battleground);
    }

    function setPhaseBreakpoint(uint8 _phase, uint16 breakpoint)
        external
        onlyOwner
    {
        phaseBreakpoints[_phase] = breakpoint;
    }

    function setPhasePrice(uint8 _phase, uint256 price) external onlyOwner {
        phasePrices[_phase] = price;
    }

    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
    }

    function setWhitelistEnabled(bool enabled_) external onlyOwner {
        _whitelist = enabled_;
    }

    function setWhitelistRoot(bytes32 root_) external onlyOwner {
        whitelistRoot = root_;
    }

    function withdraw(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function setDragonURI(string memory uri) external onlyOwner {
        dragonURI = uri;
    }

    function setGolemURI(string memory uri) external onlyOwner {
        golemURI = uri;
    }

    function setStatsEditor(address source, bool isApproved)
        external
        onlyOwner
    {
        statsEditor[source] = isApproved;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (tokenId < 1 || tokenId > totalSupply()) {
            return "ipfs://QmQ5iziedAMaH4ZwmC3Q6mdVrawJYAJnfEx8vQYMJsxtSa";
        }

        if (dragonMap[tokenId]) {
            return
                string(
                    abi.encodePacked(dragonURI, dragonIDs[tokenId].toString())
                );
        } else {
            return
                string(
                    abi.encodePacked(golemURI, golemIDs[tokenId].toString())
                );
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (_msgSender() != address(BattleGround))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );

        _transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
