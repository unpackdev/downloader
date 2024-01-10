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

import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ILL420BudStaking.sol";

/**
 * @title LL420Reveal
 * @dev Bud reveal contract.
 *
 */
contract LL420Reveal is Ownable, Pausable, ReentrancyGuard {
    uint8 public revealPeriod = 7;
    uint16 public constant TOTAL_SUPPLY = 20000;

    address public immutable stakingContractAddress;
    mapping(uint256 => bool) public requested;

    event RequestReveal(uint256 indexed _budId, address indexed _user, uint256 indexed _timestamp);

    constructor(address _stakingAddress) {
        require(_stakingAddress != address(0), "Zero address");

        stakingContractAddress = _stakingAddress;
    }

    /* ==================== External METHODS ==================== */

    /**
     * @dev Reveal the buds
     *
     * @param _id Id of game key
     * @param _ids Id array of buds
     */
    function reveal(uint256 _id, uint256[] memory _ids) external nonReentrant whenNotPaused {
        require(_ids.length <= TOTAL_SUPPLY, "Incorrect bud ids");

        uint8 _revealPeriod = revealPeriod;
        ILL420BudStaking BUD_STAKING = ILL420BudStaking(stakingContractAddress);

        uint256[] memory budIds = BUD_STAKING.getGKBuds(_id, _msgSender());
        /// Check if the ids belong to correct owner
        /// Check if the id is in pending of reveal
        for (uint256 i = 0; i < _ids.length; i++) {
            require(!requested[_ids[i]], "Bud is already requested to reveal");

            bool belong = false;
            for (uint256 j = 0; j < budIds.length; j++) {
                if (_ids[i] == budIds[j]) {
                    belong = true;
                    break;
                }
            }
            require(belong, "Bud not belong to the sender");
        }

        /// Check if Buds can be revealed
        (uint256[] memory periods, ) = BUD_STAKING.getBudInfo(_ids);
        for (uint256 i = 0; i < periods.length; i++) {
            require(periods[i] >= _revealPeriod, "Staked more than limit");

            requested[_ids[i]] = true;

            emit RequestReveal(_ids[i], _msgSender(), block.timestamp);
        }
    }

    /* ==================== OWNER METHODS ==================== */

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
