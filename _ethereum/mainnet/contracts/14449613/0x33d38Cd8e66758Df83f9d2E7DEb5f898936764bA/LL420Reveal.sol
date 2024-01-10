//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Reveal Buds
//
// by LOOK LABS
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ILL420BudStaking.sol";

/**
 * @title LL420Reveal
 * @dev Bud reveal contract.
 *
 */
contract LL420Reveal is VRFConsumerBaseV2, Ownable, Pausable, ReentrancyGuard {
    VRFCoordinatorV2Interface public COORDINATOR;
    LinkTokenInterface public LINK_TOKEN;

    uint8 revealPeriod = 7;
    uint8 private constant REQUEST_CONFIRMATION = 3;
    uint16 public TOTAL_SUPPLY = 20000;
    uint16 public totalRevealed;
    uint16 constant THC0 = 12000;
    uint16 constant THC1 = 5000;
    uint16 constant THC2 = 2000;
    uint16 constant THC3 = 1000;
    uint16[4] public revealedBudPerThc = [0, 0, 0, 0];
    uint32 public callbackGaskLimit = 300000;
    uint64 private subscriptionId;
    bytes32 public keyHash;
    address private vrfCoordinator;
    address public stakingContractAddress;

    mapping(uint256 => uint256[]) private _vrfReqQueue;
    mapping(uint256 => bool) private _pending;

    event GenerateRandomNumber(uint256 indexed id, uint256 number);
    event GasLeft(uint256 indexed gas);

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        address _stakingAddress
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        require(_stakingAddress != address(0), "Zero address error");

        subscriptionId = _subscriptionId;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINK_TOKEN = LinkTokenInterface(_link);
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        stakingContractAddress = _stakingAddress;
    }

    /* ==================== External METHODS ==================== */

    /**
     * @dev Set the thc and reveal the bud
     *
     * @param _id Id of game key
     * @param _ids Id array of buds
     */
    function reveal(uint256 _id, uint256[] memory _ids) external nonReentrant whenNotPaused {
        require(stakingContractAddress != address(0), "Staking contract is not set yet");
        require(_ids.length < TOTAL_SUPPLY, "Wrong amount of bud ids");

        ILL420BudStaking BUD_STAKING = ILL420BudStaking(stakingContractAddress);

        uint256[] memory budIds = BUD_STAKING.getGKBuds(_id, _msgSender());
        /// Check if the ids are belong to correct owner
        /// Check if the id is in pending of reveal
        for (uint256 i; i < _ids.length; i++) {
            require(!_pending[_ids[i]], "Bud is in progress to reveal or revealed already");
            _pending[_ids[i]] = true;

            bool belong = false;
            for (uint256 j; j < budIds.length; j++) {
                if (_ids[i] == budIds[j]) {
                    belong = true;
                    break;
                }
            }
            require(belong, "Bud is not belong to this user");
        }

        /// Check if Buds are able to reveal and also revealed already
        (uint256[] memory periods, uint256[] memory thc) = BUD_STAKING.getBudInfo(_ids);
        for (uint256 i = 0; i < periods.length; i++) {
            require(periods[i] >= revealPeriod && thc[i] == 200, "THC is set already or staking period is less than 7");
        }
        /// Request VRF
        _requestRandomWords(_ids);
    }

    /**
     * @dev Set the thc and reveal the bud
     *
     * @param _ids Id array of buds
     * @return status array of status value 0, 1, 2
     * 0: not revealed
     * 1: in progress of reveal
     * 2: revealed
     */
    function revealStatus(uint256[] memory _ids) external view returns (uint256[] memory) {
        require(_ids.length < TOTAL_SUPPLY && _ids.length > 0, "Wrong amount of bud ids");
        uint256[] memory status = new uint256[](_ids.length);
        ILL420BudStaking BUD_STAKING = ILL420BudStaking(stakingContractAddress);

        (, uint256[] memory thc) = BUD_STAKING.getBudInfo(_ids);
        for (uint256 i; i < _ids.length; i++) {
            if (_pending[_ids[i]]) {
                status[i] = thc[i] == 200 ? 1 : 2;
            } else {
                status[i] = 0;
            }
        }

        return status;
    }

    /* ==================== INTERNAL METHODS ==================== */

    /// Chainlink VRF callback
    function fulfillRandomWords(
        uint256 _requestId, /* requestId */
        uint256[] memory _randomWords
    ) internal override {
        uint256 startGas = gasleft();
        _updateBudTHC(_requestId, _randomWords);
        uint256 gasUsed = startGas - gasleft();
        emit GasLeft(gasUsed);
    }

    /// Assumes the subscription is funded sufficiently.
    function _requestRandomWords(uint256[] memory _ids) internal {
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATION,
            callbackGaskLimit,
            1
        );
        _vrfReqQueue[requestId] = _ids;
    }

    /**
     * @dev converts random value to thc level and set it to staking contract
     */
    function _updateBudTHC(uint256 _requestId, uint256[] memory _randomWords) internal {
        uint256[] memory budIds = _vrfReqQueue[_requestId];

        uint256[] memory thcInfo = new uint256[](budIds.length);
        uint256 length = budIds.length;
        uint256 restTHC0 = THC0 - revealedBudPerThc[0];
        uint256 restTHC1 = THC1 - revealedBudPerThc[1];
        uint256 restTHC2 = THC2 - revealedBudPerThc[2];
        uint256 restTHC3 = THC3 - revealedBudPerThc[3];

        require(restTHC0 + restTHC1 + restTHC2 + restTHC3 == TOTAL_SUPPLY - totalRevealed);
        uint16 _totalRevealed = totalRevealed;

        for (uint256 i = 0; i < length; i++) {
            unchecked {
                uint256 rest = TOTAL_SUPPLY - _totalRevealed;
                require(rest > 0, "Cant mod with zero");

                uint256 pos = _random(_randomWords[0], i) % rest;
                uint256 level;
                if (pos >= 0 && pos < restTHC0) {
                    level = 0;
                    restTHC0--;
                    revealedBudPerThc[level]++;
                } else if (pos >= restTHC0 && pos < restTHC0 + restTHC1) {
                    level = 1;
                    restTHC1--;
                    revealedBudPerThc[level]++;
                } else if (pos >= restTHC0 + restTHC1 && pos < restTHC0 + restTHC1 + restTHC2) {
                    level = 2;
                    restTHC2--;
                    revealedBudPerThc[level]++;
                } else if (pos >= restTHC0 + restTHC1 + restTHC2 && pos < restTHC0 + restTHC1 + restTHC2 + restTHC3) {
                    level = 3;
                    restTHC3--;
                    revealedBudPerThc[level]++;
                }
                _totalRevealed++;
                thcInfo[i] = level;
                emit GenerateRandomNumber(budIds[i], level);
            }
        }
        totalRevealed = _totalRevealed;

        // ILL420BudStaking STAKING_CONTRACT = ILL420BudStaking(stakingContractAddress);
        // STAKING_CONTRACT.setTHC(budIds, thcInfo);
    }

    function _random(uint256 _randomNumber, uint256 _index) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_randomNumber, _index)));
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev Set subscription id from chainlink
     * visit https://vrf.chain.link/
     *
     * @param _subscriptionId: Subscription id
     * @param _keyHash: specify the maximum amount of gas
     * @param _callbackGaskLimit gas limit for callback
     */
    function updateVRF(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGaskLimit
    ) external onlyOwner {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGaskLimit = _callbackGaskLimit;
    }

    /**
     * @dev set staking and bud contract addresses
     * @param _stakingAddress The address of LL420BudStaking contract
     */
    function setStakingContract(address _stakingAddress) external onlyOwner {
        if (_stakingAddress != address(0)) stakingContractAddress = _stakingAddress;
    }

    /**
     */
    function updateReveals(uint16[4] memory _data) external onlyOwner {
        revealedBudPerThc = _data;
    }

    /**
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev this set the reveal lock period for test from owner side.
     */
    function setRevealPeriod(uint8 _days) external onlyOwner {
        revealPeriod = _days;
    }
}
