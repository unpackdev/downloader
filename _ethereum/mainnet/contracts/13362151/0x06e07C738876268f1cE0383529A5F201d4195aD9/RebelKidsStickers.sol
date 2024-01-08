// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC20.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract RebelKidsStickers is ERC20, ReentrancyGuard, Ownable {

    uint public constant MAX_CAP = 10000000;
    uint public constant REWARD_PER_TOKEN = 3000;

    ERC721Enumerable public kidsContract;
    ERC721Enumerable public familiarsContract;

    uint[] public months;
    mapping(address => mapping(uint => uint)) public lastRewardedMonth;
    mapping(address => mapping(uint => uint)) public rewardsCount;


    constructor(ERC721Enumerable _kidsContract, ERC721Enumerable _familiarsContract) ERC20("Rebel Kids Stickers", "RBLSTCKRS") {
        months = [1633046400, 1635724800, 1638316800, 1640995200, 1643673600, 1646092800];
        kidsContract = _kidsContract;
        familiarsContract = _familiarsContract;
    }

    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function currentMonth(uint currentTimestamp) internal view returns (uint) {
        if (currentTimestamp < months[0]) {
            return 1;
        }
        for (uint i = 1; i < months.length; i++) {
            if (months[i] > currentTimestamp) {
                return i + 1;
            }
        }
        return months.length + 1;
    }

    function findClaimableTokens(IERC721Enumerable minterContract, uint8 scale) internal view returns (uint, uint[] memory) {
        uint balance = minterContract.balanceOf(_msgSender());

        uint weight = 0;
        address contractAddress = address(minterContract);
        uint month = currentMonth(block.timestamp);
        uint[] memory rewardedTokens = new uint[](balance);
        uint pos = 0;
        for (uint i = 0; i < balance; i++) {
            uint tokenId = minterContract.tokenOfOwnerByIndex(_msgSender(), i);
            uint lastMonth = lastRewardedMonth[contractAddress][tokenId];

            if (lastMonth == 0 || lastMonth < month) {
                uint rewards = rewardsCount[contractAddress][tokenId];
                uint d = rewards > 6 ? 0 : 6 - rewards;
                weight += 1 << d;
                rewardedTokens[pos] = tokenId;
                pos += 1;
            }
        }

        uint reward = weight * REWARD_PER_TOKEN / scale / 64;
        return (reward > MAX_CAP - totalSupply() ? MAX_CAP - totalSupply() : reward, rewardedTokens);
    }

    function claim(IERC721Enumerable minterContract, uint8 scale) internal {
        (uint tickets, uint[] memory tokens) = findClaimableTokens(minterContract, scale);
        uint month = currentMonth(block.timestamp);
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == 0) {
                break;
            }
            lastRewardedMonth[address(minterContract)][tokens[i]] = month;
            rewardsCount[address(minterContract)][tokens[i]] += 1;
        }
        if (tickets != 0) {
            _mint(_msgSender(), tickets);
        }
    }

    function findClaimableTokensForKids() public view returns (uint) {
        (uint tickets,) = findClaimableTokens(kidsContract, 1);
        return tickets;
    }

    function findClaimableTokensForFamiliars() public view returns (uint) {
        (uint tickets,) = findClaimableTokens(familiarsContract, 3);
        return tickets;
    }

    function findClaimableTokensForAll() public view returns (uint) {
        (uint tickets1,) = findClaimableTokens(kidsContract, 1);
        (uint tickets2,) = findClaimableTokens(familiarsContract, 3);
        return tickets1 + tickets2;
    }

    function claimWithKids() public nonReentrant {
        claim(kidsContract, 1);
    }

    function claimWithFamiliars() public nonReentrant {
        claim(familiarsContract, 3);
    }

    function claim() public nonReentrant {
        claim(kidsContract, 1);
        claim(familiarsContract, 3);
    }

    function sendTokens(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i]);
        }
    }

}
