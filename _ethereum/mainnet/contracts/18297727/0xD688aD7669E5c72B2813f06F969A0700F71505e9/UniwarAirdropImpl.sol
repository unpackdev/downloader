// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20Upgradeable.sol";

import "./UniwarRecoverable.sol";


/**
 * Owner equips archers with starshots for battle by assigning quills to each elf.
 * Archers can then arm themselves with starshots by transferring quills to themselves.
*/
contract UniwarAirdropImpl is UniwarRecoverable {
    /// @dev used as an arguments type for the equip method.
    struct Quill {
        address archer;
        uint256 amount;
    }

    uint256 public startAt; // @dev The timestamp when the airdrop starts.
    uint256 public endAt; // @dev The timestamp when the airdrop ends.
    
    mapping(address => mapping(address => uint256)) public quills; // @dev The amount of quills (tokens) an archer has for a starshot (token).

    event Assign(address indexed _starshot, uint256 indexed _quills, address _archer);
    event Arm(address indexed _starshot, uint256 indexed _quills, address indexed _archer, address _elf);
    event UpdateTimestamps(uint256 _startAt, uint256 _endAt);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _startAt, uint256 _endAt) initializer external {
        __UniwarRecoverable_init();
        startAt = _startAt;
        endAt = _endAt;
    }

    /// @dev Only the owner can equip all archers with starshots. (Airdrop assumes it has tokens).
    /// @param _starshot The starshot (token) to equip for battle.
    /// @param _quills Array of Quill Structs to equip the archers with.
    function equip(address _starshot, Quill[] calldata _quills) external onlyOwner {
        require(_starshot != address(0), "UniwarAirdrop: starshot cannot be zero address");
        require(_quills.length > 0, "UniwarAirdrop: invalid quills"); // TODO: Limit the size of array to prevent gas issues.

        for (uint256 i = 0; i < _quills.length; i++) {
            unchecked {
                quills[_starshot][_quills[i].archer] += _quills[i].amount;
            }
        }
    }

    /// @dev Only the owner can assign starshots to an archer. (Manual use only)
    /// @param _starshot The starshot (token) to arm for battle.
    /// @param _quills The amount of quills (tokens) to arm the archer starshots with.
    /// @param _archer The archer to arm the starshot for.
    /// @custom:emit Assign
    function assign(address _starshot, uint256 _quills, address _archer) external onlyOwner {
        unchecked {
            quills[_starshot][_archer] += _quills;
        }
        emit Assign(_starshot, _quills, _archer); // Forego this to save gas
    }


    /// @param _starshot The starshot (token) to check the amount of quills (tokens) an archer has.
    /// @param _archer The archer to check the amount of quills (tokens) for.
    /// @return The amount of quills (tokens) an archer has for a starshot (token).
    function quillsOf(address _starshot, address _archer) external view returns (uint256) {
        return _quillsOf(_starshot, _archer);
    }

    function _quillsOf(address _starshot, address _archer) private view returns (uint256) {
        return quills[_starshot][_archer] / 5; // Used Unichads Inputs so divide by 5
    }

    /// @notice Arms an archer with starshot quills. (Transfer tokens)
    /// @dev External function can be called by any warrior.
    /// @param _starshot The starshot (token) to arm.
    /// @param _quills The amount of quills (tokens) to arm.
    /// @param _elf The elf to become an archer when armed.
    /// @custom:emit Arm
    function arm(address _starshot, uint256 _quills, address _elf) external {
        if (startAt > 0) {
            require(block.timestamp >= startAt, "UniwarAirdrop: airdrop has not started");
        }
        
        if (endAt > 0) {
            require(block.timestamp <= endAt, "UniwarAirdrop: airdrop has ended");
        }
        
        IERC20Upgradeable _bow = IERC20Upgradeable(_starshot);
        address _archer = msg.sender;
        require(_starshot != address(0), "UniwarAirdrop: starshot cannot be zero address");
        require(_elf != address(0), "UniwarAirdrop: elf cannot be zero address");
        require(_quills > 0, "UniwarAirdrop: invalid quills");
        require(_quillsOf(_starshot, _archer) >= _quills, "UniwarAirdrop: insufficient archer quills");
        require(_bow.balanceOf(address(this)) >= _quills, "UniwarAirdrop: insufficient airdrop quills");
        unchecked {
            quills[_starshot][_archer] -= _quills * 5; /// @dev reentrancy guard
        }
        _bow.transfer(_elf, _quills);
        emit Arm(_starshot, _quills, _archer, _elf);
    }

    function updateTimestamps(uint256 _startAt, uint256 _endAt) external onlyOwner {
        startAt = _startAt;
        endAt = _endAt;
    }
    
    function _authorizeUpgrade(address _newImplementation) internal onlyOwner override {}
}
