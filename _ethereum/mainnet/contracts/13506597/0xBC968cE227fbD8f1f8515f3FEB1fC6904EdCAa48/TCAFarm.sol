// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/*
  ________            ______                 __           ___                   
 /_  __/ /_  ___     / ____/______  ______  / /_____     /   |  ____  ___  _____
  / / / __ \/ _ \   / /   / ___/ / / / __ \/ __/ __ \   / /| | / __ \/ _ \/ ___/
 / / / / / /  __/  / /___/ /  / /_/ / /_/ / /_/ /_/ /  / ___ |/ /_/ /  __(__  ) 
/_/ /_/ /_/\___/   \____/_/   \__, / .___/\__/\____/  /_/  |_/ .___/\___/____/  
                             /____/_/                       /_/                 
  
  The Crypto Apes Token: $APES
*/

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract TCAFarm is ERC20Burnable, Ownable {
    uint256 public constant MAX_WALLET_BURIED = 30;
    uint256 public constant TCA_EMISSIONS_RATE = 57870370370370; // 5 per day
    address public constant TCA_ADDRESS = 0x4a084E3030304c3E0f8e52ec653984764f310273;
    bool public stakingLive = true;

    mapping(uint256 => uint256) internal TCATokenIdTimeStaked;
    mapping(uint256 => address) internal TCATokenIdToBurier;
    mapping(address => uint256[]) internal burierToTCATokenIds;
    
    IERC721Enumerable private constant _tcaIERC721Enumerable = IERC721Enumerable(TCA_ADDRESS);

    constructor() ERC20("Apes", "APES") {
    }

    modifier stakingEnabled {
        require(stakingLive, "STAKING_NOT_LIVE");
        _;
    }

    function getApesBuried(address burier) public view returns (uint256[] memory) {
        return burierToTCATokenIds[burier];
    }
    
    function getBuriedCount(address burier) public view returns (uint256) {
        return burierToTCATokenIds[burier].length;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
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

    function buryApesByIds(uint256[] memory tokenIds) public stakingEnabled {
        require(getBuriedCount(msg.sender) + tokenIds.length <= MAX_WALLET_BURIED, "MAX_TOKENS_BURRIED_PER_WALLET");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(_tcaIERC721Enumerable.ownerOf(id) == msg.sender && TCATokenIdToBurier[id] == address(0), "TOKEN_IS_NOT_YOURS");
            _tcaIERC721Enumerable.transferFrom(msg.sender, address(this), id);

            burierToTCATokenIds[msg.sender].push(id);
            TCATokenIdTimeStaked[id] = block.timestamp;
            TCATokenIdToBurier[id] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(getBuriedCount(msg.sender) > 0, "MUST_ATLEAST_BE_BURIED_ONCE");
        uint256 totalRewards = 0;

        for (uint256 i = burierToTCATokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = burierToTCATokenIds[msg.sender][i - 1];

            _tcaIERC721Enumerable.transferFrom(address(this), msg.sender, tokenId);
            totalRewards += ((block.timestamp - TCATokenIdTimeStaked[tokenId]) * TCA_EMISSIONS_RATE);
            burierToTCATokenIds[msg.sender].pop();
            TCATokenIdToBurier[tokenId] = address(0);
        }

        _mint(msg.sender, totalRewards);
    }

    function unstakeApesByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(TCATokenIdToBurier[id] == msg.sender, "NOT_ORIGINAL_BURIER");

            _tcaIERC721Enumerable.transferFrom(address(this), msg.sender, id);
            totalRewards += ((block.timestamp - TCATokenIdTimeStaked[id]) * TCA_EMISSIONS_RATE);

            removeTokenIdFromArray(burierToTCATokenIds[msg.sender], id);
            TCATokenIdToBurier[id] = address(0);
        }

        _mint(msg.sender, totalRewards);
    }

    function claimByApeTokenId(uint256 tokenId) public {
        require(TCATokenIdToBurier[tokenId] == msg.sender, "NOT_BURIED_BY_YOU");
        _mint(msg.sender, ((block.timestamp - TCATokenIdTimeStaked[tokenId]) * TCA_EMISSIONS_RATE));
        TCATokenIdTimeStaked[tokenId] = block.timestamp;
    }

    function claimAll() public {
        uint256 totalRewards = 0;

        uint256[] memory apeTokenIds = burierToTCATokenIds[msg.sender];
        for (uint256 i = 0; i < apeTokenIds.length; i++) {
            uint256 id = apeTokenIds[i];
            require(TCATokenIdToBurier[id] == msg.sender, "NOT_BURIED_BY_YOU");
            totalRewards += ((block.timestamp - TCATokenIdTimeStaked[id]) * TCA_EMISSIONS_RATE);
            TCATokenIdTimeStaked[id] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function getAllRewards(address burier) public view returns (uint256) {
        uint256 totalRewards = 0;

        uint256[] memory apeTokenIds = burierToTCATokenIds[burier];
        for (uint256 i = 0; i < apeTokenIds.length; i++) {
            totalRewards += ((block.timestamp - TCATokenIdTimeStaked[apeTokenIds[i]]) * TCA_EMISSIONS_RATE);
        }

        return totalRewards;
    }

    function getRewardsByApeTokenId(uint256 tokenId) public view returns (uint256) {
        require(TCATokenIdToBurier[tokenId] != address(0), "TOKEN_NOT_BURIED");

        uint256 secondsStaked = block.timestamp - TCATokenIdTimeStaked[tokenId];
        return secondsStaked * TCA_EMISSIONS_RATE;
    }

    function getApeBurier(uint256 tokenId) public view returns (address) {
        return TCATokenIdToBurier[tokenId];
    }

    function toggle() external onlyOwner {
        stakingLive = !stakingLive;
    }
}