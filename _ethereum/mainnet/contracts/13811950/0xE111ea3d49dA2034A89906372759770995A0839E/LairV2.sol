// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Context.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";

import "./IVampireGameERC721.sol";
import "./TokenTraits.sol";
import "./IBLOODBAG.sol";

import "./ILairV2.sol";
import "./AbstractLair.sol";

import "./console.sol";

/// @title The Vampire Lair V2
contract LairV2 is ILairV2, IERC721Receiver, Ownable, ReentrancyGuard {
    /// @notice sum of "predator score" of all staked vampires
    uint24 public totalPredatorScoreStaked = 0;
    /// @notice amount of $BLOODBAG for each predator score
    uint256 public bloodbagPerPredatorScore = 0;
    /// @notice map a predator score to a list of VampireStake[] containing vampires with that score
    mapping(uint8 => VampireStake[]) public scoreStakingMap;
    /// @notice tracks the index of each Vampire in the stake list
    mapping(uint16 => uint256) public stakeIndices;
    /// @notice map of controllers that can control this contract
    mapping(address => bool) public controllers;

    /// @notice VampireGame ERC721 contract for quering info and migrating
    IVampireGameERC721 public immutable vgame;
    AbstractLair public immutable legacyLair;
    IBLOODBAG public immutable bloodbag;

    /// ==== Events

    event VampireStaked(
        address indexed owner,
        uint16 indexed tokenId,
        uint256 bloodBagPerPredatorScoreWhenStaked
    );
    event VampireUnstaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount
    );
    event BloodBagClaimed(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount
    );
    event TaxUpdated(uint256 amount, uint256 unaccountedReward);

    /// ==== Constructor

    constructor(
        address _vgame,
        address _legacyLair,
        address _bloodbag
    ) {
        vgame = IVampireGameERC721(_vgame);
        legacyLair = AbstractLair(_legacyLair);
        bloodbag = IBLOODBAG(_bloodbag);
    }

    /// ==== Modifiers

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS_ALLOWED");
        _;
    }

    /// ==== Helpers

    /// @notice returns the predator score of a Vampire
    /// @param tokenId the Vampire's id
    /// @return the predator score of the Vampire (5-8)
    function _predatorScoreForVampire(uint16 tokenId)
        private
        view
        returns (uint8)
    {
        return 8 - [3, 0, 2, 1][vgame.getPredatorIndex(tokenId)];
    }

    /// ==== ILairControls

    /// @dev See {ILairControls.stakeVampire}
    function stakeVampire(address sender, uint16 tokenId)
        external
        override
        onlyControllers
    {
        _stakeVampire(sender, tokenId);
    }

    function _stakeVampire(address sender, uint16 tokenId) private {
        uint8 score = _predatorScoreForVampire(tokenId);

        // Update total predator score
        totalPredatorScoreStaked += score;

        // Store the location of the vampire in the VampireStake list
        stakeIndices[tokenId] = scoreStakingMap[score].length;

        // Push vampire to the VamprieStake list
        scoreStakingMap[score].push(
            VampireStake({
                owner: sender,
                tokenId: tokenId,
                bloodbagPerPredatorScoreWhenStaked: uint80(
                    bloodbagPerPredatorScore
                )
            })
        );

        emit VampireStaked(sender, tokenId, bloodbagPerPredatorScore);
    }

    /// @dev See {ILairControls.claimBloodBags}
    function claimBloodBags(address sender, uint16 tokenId)
        external
        override
        onlyControllers
        returns (uint256 owed)
    {
        uint8 score = _predatorScoreForVampire(tokenId);
        VampireStake memory stake = scoreStakingMap[score][
            stakeIndices[tokenId]
        ];
        require(sender == stake.owner, "NOT_OWNER_OR_NOT_STAKED");

        // Calculate and sets amount of bloodbags owed (this is returned by the fn)
        uint256 _bloodbagPerPredatorScore = bloodbagPerPredatorScore;
        owed =
            score *
            (_bloodbagPerPredatorScore -
                stake.bloodbagPerPredatorScoreWhenStaked);

        // Resets the vampire staking info
        scoreStakingMap[score][stakeIndices[tokenId]] = VampireStake({
            owner: sender,
            tokenId: tokenId,
            bloodbagPerPredatorScoreWhenStaked: uint80(
                _bloodbagPerPredatorScore
            )
        });

        // Logs an event with the blood claiming info
        emit BloodBagClaimed(sender, tokenId, owed);

        // <- Controller is supposed to transfer $BLOODBAGs
    }

    /// @dev See {ILairControls.unstakeVampire}
    function unstakeVampire(address sender, uint16 tokenId)
        external
        override
        onlyControllers
        returns (uint256 owed)
    {
        uint8 score = _predatorScoreForVampire(tokenId);
        VampireStake memory stake = scoreStakingMap[score][
            stakeIndices[tokenId]
        ];
        require(stake.owner == sender, "NOT_OWNER_OR_NOT_STAKED");

        // Calculate and sets amount of bloodbags owed (this is returned by the fn)
        owed =
            score *
            (bloodbagPerPredatorScore -
                stake.bloodbagPerPredatorScoreWhenStaked);

        // Sub vampire's score from total score staked
        totalPredatorScoreStaked -= score;

        // Gets the last vampire in the staking list for this score
        VampireStake memory lastStake = scoreStakingMap[score][
            scoreStakingMap[score].length - 1
        ];

        // Move the last staked vampire to the current position
        scoreStakingMap[score][stakeIndices[tokenId]] = lastStake;
        stakeIndices[lastStake.tokenId] = stakeIndices[tokenId];

        // Delete the last vampire from staking list, since it's duplicated now
        scoreStakingMap[score].pop();
        delete stakeIndices[tokenId];

        // Setting all state first, then controller will do the token transfer.
        // Doing that in this order will protects us against reentrancy.

        // Logs an event with the vampire unstaking and blood claiming info
        emit VampireUnstaked(sender, tokenId, owed);

        // <- Controller is supposed to transfer NFT
        // <- Controller is supposed to transfer $BLOODBAGs
    }

    function addTaxToVampires(uint256 amount, uint256 unaccountedRewards)
        external
        override
        onlyControllers
    {
        bloodbagPerPredatorScore +=
            (amount + unaccountedRewards) /
            totalPredatorScoreStaked;
        emit TaxUpdated(amount, unaccountedRewards);
    }

    function randomVampireOwner(uint256 seed) external view override returns (address) {
        if (totalPredatorScoreStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalPredatorScoreStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Wolves with the same alpha score
        // 5 = 8 -3

        for (uint8 i = 5; i <= 8; i++) {
            cumulative += scoreStakingMap[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Wolf with that alpha score
            return scoreStakingMap[i][seed % scoreStakingMap[i].length].owner;
        }
        return address(0x0);
    }

    /// ==== ILair

    /// @notice See {ILair.getTotalPredatorScoreStaked}
    function getTotalPredatorScoreStaked()
        external
        view
        override
        returns (uint24)
    {
        return totalPredatorScoreStaked;
    }

    /// @notice See {ILair.getBloodbagPerPredatorScore}
    function getBloodbagPerPredatorScore()
        external
        view
        override
        returns (uint256)
    {
        return bloodbagPerPredatorScore;
    }

    /// ==== IERC721Receiver

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "PLEASE_DONT");
        return IERC721Receiver.onERC721Received.selector;
    }

    /// ==== Only Owner

    /// @notice add a controller that will be able to call functions in this contract
    /// @param controller the address that will be authorized
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /// @notice remove a controller so it won't be able to call functions in this contract anymore
    /// @param controller the address that will be unauthorized
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /// ==== Frontend Helpers

    function ownerOf(uint16 tokenId, uint8 predatorScore)
        public
        view
        override
        returns (address)
    {
        return scoreStakingMap[predatorScore][stakeIndices[tokenId]].owner;
    }

    /// ==== Migration

    function migrate(
        uint16[] calldata vampires,
        uint8[] calldata predatorIndices
    ) external nonReentrant {
        require(
            vampires.length == predatorIndices.length,
            "ARRAYS_SHOULD_HAVE_SAME_SIZE"
        );

        uint16 tokenId;
        uint8 predatorIndex;
        for (uint256 i = 0; i < vampires.length; i++) {
            tokenId = vampires[i];
            predatorIndex = predatorIndices[i];
            uint256 idx = legacyLair.stakeIndices(tokenId);
            (address owner, , ) = legacyLair.scoreStakingMap(
                predatorIndex,
                idx
            );
            require(owner == _msgSender(), "NOT_OWNER");
            legacyLair.unstakeVampire(_msgSender(), tokenId);
            _stakeVampire(_msgSender(), tokenId);
            vgame.transferFrom(address(legacyLair), address(this), tokenId);
        }
        bloodbag.mint(_msgSender(), vampires.length * 10 ether);
    }
}
