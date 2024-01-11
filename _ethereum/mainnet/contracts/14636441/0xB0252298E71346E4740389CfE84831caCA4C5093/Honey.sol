// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./IERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// $$\   $$\
// $$ |  $$ |
// $$ |  $$ | $$$$$$\  $$$$$$$\   $$$$$$\  $$\   $$\
// $$$$$$$$ |$$  __$$\ $$  __$$\ $$  __$$\ $$ |  $$ |
// $$  __$$ |$$ /  $$ |$$ |  $$ |$$$$$$$$ |$$ |  $$ |
// $$ |  $$ |$$ |  $$ |$$ |  $$ |$$   ____|$$ |  $$ |
// $$ |  $$ |\$$$$$$  |$$ |  $$ |\$$$$$$$\ \$$$$$$$ |
// \__|  \__| \______/ \__|  \__| \_______| \____$$ |
//                                         $$\   $$ |
//                                         \$$$$$$  |
//                                          \______/
//                BEAR CARTEL 2022

contract HONEY is ERC20, Pausable, Ownable, ReentrancyGuard {
    uint256 public EMISSION_RATE = 57870370370370;
    uint256 burnRate = 200;

    IERC721 private constant _bearCartel =
        IERC721(0x9971F7F3300d10311d618682383BFccC9B0C36C2);

    mapping(uint256 => address) internal _bearToOwner;
    mapping(address => uint256[]) internal _ownerToBearIDs;
    mapping(uint256 => uint256) internal _tokenIDToStakeTime;

    constructor() ERC20("Honey", "HONEY") {}

    modifier callerIsSender() {
        require(msg.sender == tx.origin, "CONTRACT_INTERACTION_DISABLED");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateEmissionRate(uint256 rate) external onlyOwner {
        EMISSION_RATE = rate;
    }

    function updateBurnRate(uint256 rate) external onlyOwner {
        burnRate = rate;
    }

    // only to be used when needed for situations like liquidity
    function devMint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        callerIsSender
    {
        _burn(msg.sender, amount);
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId)
        internal
    {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    function hibernateBearsByID(uint256[] memory tokenIDs)
        external
        nonReentrant
        whenNotPaused
        callerIsSender
    {
        require(tokenIDs.length > 0, "MINIMUM_NOT_MET");
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(
                _bearCartel.ownerOf(tokenIDs[i]) == msg.sender,
                "NOT_TOKEN_OWNER"
            );

            _bearCartel.transferFrom(msg.sender, address(this), tokenIDs[i]);
            _ownerToBearIDs[msg.sender].push(tokenIDs[i]);
            _tokenIDToStakeTime[tokenIDs[i]] = block.timestamp;
            _bearToOwner[tokenIDs[i]] = msg.sender;
        }
    }

    function wakeBearsByID(uint256[] memory tokenIDs)
        external
        nonReentrant
        whenNotPaused
        callerIsSender
    {
        require(tokenIDs.length > 0, "MINIMUM_NOT_MET");
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(
                _bearToOwner[tokenIDs[i]] == msg.sender,
                "NOT_ORIGINAL_STAKER"
            );

            rewards += ((block.timestamp - _tokenIDToStakeTime[tokenIDs[i]]) *
                EMISSION_RATE);

            _bearCartel.transferFrom(address(this), msg.sender, tokenIDs[i]);
            removeTokenIdFromArray(_ownerToBearIDs[msg.sender], tokenIDs[i]);
            _tokenIDToStakeTime[tokenIDs[i]] = 0;
            _bearToOwner[tokenIDs[i]] = address(0);
        }
        _mint(msg.sender, rewards);
    }

    function viewHibernatingBears(address checker)
        external
        view
        returns (uint256[] memory)
    {
        return _ownerToBearIDs[checker];
    }

    function viewBearOwner(uint256 tokenID) external view returns (address) {
        return _bearToOwner[tokenID];
    }

    function viewPendingRewards(address checker)
        external
        view
        returns (uint256)
    {
        uint256 rewards = 0;
        uint256[] memory tokenIDs = _ownerToBearIDs[checker];

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (_tokenIDToStakeTime[tokenIDs[i]] != 0) {
                rewards += ((block.timestamp -
                    _tokenIDToStakeTime[tokenIDs[i]]) * EMISSION_RATE);
            }
        }

        return rewards;
    }

    function totalStaked() external view returns (uint256) {
        return _bearCartel.balanceOf(address(this));
    }

    function totalBurned() external view returns (uint256) {
        return
            _bearCartel.balanceOf(0x000000000000000000000000000000000000dEaD);
    }

    function burnBears(uint256[] memory tokenIDs)
        external
        nonReentrant
        whenNotPaused
        callerIsSender
    {
        uint256 honeyPerToken = 1000000000000000000 * burnRate;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(
                _bearCartel.ownerOf(tokenIDs[i]) == msg.sender,
                "NOT_OWNER_OF_TOKEN"
            );

            _bearCartel.transferFrom(
                msg.sender,
                0x000000000000000000000000000000000000dEaD,
                tokenIDs[i]
            ); // burn to the dead address
        }
        _mint(msg.sender, honeyPerToken * tokenIDs.length);
    }
}
