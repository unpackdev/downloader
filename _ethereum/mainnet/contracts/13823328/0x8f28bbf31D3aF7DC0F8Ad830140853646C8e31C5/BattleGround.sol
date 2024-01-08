// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";

interface IGolemsAndDragons {
    function ownerOf(uint256 id) external view returns (address);

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId,
        bytes memory data_
    ) external;

    function isDragon(uint256 token) external view returns (bool);

    function addStats(
        uint256 tokenID,
        uint16 health,
        uint16 attack,
        uint16 defense,
        uint16 agility
    ) external;
}

interface IAncientGold {
    function balanceOf(address address_) external view returns (uint256);

    function bgTransfer(address to_, uint256 amount_) external;
}

contract BattleGround is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    struct Stake {
        address owner;
        uint256 token;
        uint80 time;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // Private variables
    bool private _paused;

    // Public variables
    IGolemsAndDragons public golemsAndDragons;
    IAncientGold public ancientGold;

    uint256 public totalTokensStaked;

    mapping(uint256 => uint256) public stakeIndices;
    mapping(address => Stake[]) public stakes;

    // Public constants
    uint256 public constant TTE = 1 days;
    uint256 public constant EARNINGS_RATE = 15000 ether;
    uint256 public constant HEALTH_RATE = 10;
    uint256 public constant ATTACK_RATE = 1;
    uint256 public constant DEFENSE_RATE = 5;
    uint256 public constant AGILITY_RATE = 1;

    modifier whenPaused() {
        require(_paused, "GAD-BG-E1");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "GAD-BG-E2");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function startTrainingTokens(address address_, uint16[] calldata tokens)
        external
    {
        require(
            address_ == _msgSender() ||
                _msgSender() == address(golemsAndDragons),
            "GAD-BG-E3"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            if (_msgSender() != address(golemsAndDragons)) {
                require(
                    golemsAndDragons.ownerOf(tokens[i]) == _msgSender(),
                    "GAD-BG-E4"
                );
                golemsAndDragons.transferFrom(
                    _msgSender(),
                    address(this),
                    tokens[i]
                );
            }

            totalTokensStaked += 1;
            stakeIndices[tokens[i]] = stakes[address_].length;
            stakes[address_].push(
                Stake(address_, tokens[i], uint80(block.timestamp))
            );
        }
    }

    event TokenStatsUpgraded(
        uint256 tokenId,
        uint256 health,
        uint256 attack,
        uint256 defense,
        uint256 agility
    );

    function claimFromTraining(uint16[] calldata tokens, bool unstake)
        external
        whenNotPaused
    {
        uint256 earnings = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Stake memory stake = stakes[_msgSender()][stakeIndices[tokens[i]]];
            require(stake.owner == _msgSender(), "GOD-BG-E5");
            require(
                !unstake || block.timestamp - stake.time >= TTE,
                "GOD-BG-E6"
            );

            uint256 actualHealthRate = golemsAndDragons.isDragon(tokens[i])
                ? HEALTH_RATE * 3
                : HEALTH_RATE;

            earnings += ((block.timestamp - stake.time) * EARNINGS_RATE) / TTE;
            uint256 health = ((block.timestamp - stake.time) *
                actualHealthRate) / TTE;
            uint256 attack = ((block.timestamp - stake.time) * ATTACK_RATE) /
                TTE;
            uint256 defense = ((block.timestamp - stake.time) * DEFENSE_RATE) /
                TTE;
            uint256 agility = ((block.timestamp - stake.time) * AGILITY_RATE) /
                TTE;

            if (unstake) {
                totalTokensStaked -= 1;

                Stake memory lastStake = stakes[_msgSender()][
                    stakes[_msgSender()].length - 1
                ];
                stakes[_msgSender()][stakeIndices[tokens[i]]] = lastStake;
                stakeIndices[lastStake.token] = stakeIndices[tokens[i]];
                stakes[_msgSender()].pop();
                delete stakeIndices[tokens[i]];

                golemsAndDragons.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokens[i],
                    ""
                );
            } else {
                stakes[_msgSender()][stakeIndices[tokens[i]]] = Stake(
                    _msgSender(),
                    tokens[i],
                    uint80(block.timestamp)
                );
            }

            emit TokenStatsUpgraded(
                tokens[i],
                health,
                attack,
                defense,
                agility
            );

            golemsAndDragons.addStats(
                tokens[i],
                uint16(health),
                uint16(attack),
                uint16(defense),
                uint16(agility)
            );
        }

        // Prevent revert if $AGOLD contract does not have enough balance
        uint256 balance = ancientGold.balanceOf(address(ancientGold));
        if (balance < earnings) earnings = balance;

        ancientGold.bgTransfer(_msgSender(), earnings);
    }

    function setGolemsAndDragons(address contract_) external onlyOwner {
        golemsAndDragons = IGolemsAndDragons(contract_);
    }

    function setAncientGold(address contract_) external onlyOwner {
        ancientGold = IAncientGold(contract_);
    }

    function getAllStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}
