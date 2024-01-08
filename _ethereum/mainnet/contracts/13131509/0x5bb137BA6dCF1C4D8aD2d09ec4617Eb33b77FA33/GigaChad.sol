// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract GigaChad is Ownable, ERC721, ERC721Enumerable {
    uint256 constant public LIKE_PRICE = 10000000000000000; // 0.01 ETH
    uint256 constant private TOKEN_PRICE = 1000000000000000000; // 1 ETH
    uint256[] private DISCOUNTS = [0, 5, 10];
    uint256 constant private SALE_START_TIME = 1630515600; // 2021-09-01 17:00:00 UTC
    uint256 constant private REWARDS_TIME = 1631293200; // 2021-09-10 17:00:00 UTC
    uint256 constant private REWARDS_FOR_TOKENS = 10;
    uint256 constant private REWARDS_FOR_VOTERS = 10;
    uint256 constant private AUTHOR_SHARE = 50;
    uint256 constant private FOUNDATION_SHARE = 50;

    address private _collection = address(this);
    address payable private _foundationAddress;
    address payable private _authorAddress;

    address[] private _voterTickets;
    uint256[] private _tokenTickets;
    address[] private _winners;
    mapping(address => uint256) private _winnersRewards;

    uint256[] private _tokens = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122];
    uint256[] private _rewards = [123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142];

    bool private _rewardsAssigned = false;

    mapping(uint256 => uint256) private _likes;

    constructor(address payable foundationAddress, address payable authorAddress)
    ERC721("GigaChad", "GGCHD")
    Ownable()
    {
        _foundationAddress = foundationAddress;
        _authorAddress = authorAddress;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeid6xqq23im4sbfa6htmrma34yumwettfzj4hnpmnwveos3lwpz574/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function ownersOf(uint256[] memory tokenIds) public view returns (address[] memory) {
        address[] memory owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_exists(tokenIds[i])) {
                owners[i] = ownerOf(tokenIds[i]);
            } else {
                owners[i] = address(0);
            }
        }
        return owners;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    function rand(uint256 from, uint256 to, uint256 seed) private view returns (uint256) {
        return from + (uint256(keccak256(abi.encodePacked(seed, block.difficulty, blockhash(block.number), block.timestamp))) % (to + 1 - from));
    }

    function quickSortWith(uint[] memory arr, uint[] memory data, int left, int right) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                (data[uint(i)], data[uint(j)]) = (data[uint(j)], data[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortWith(arr, data, left, j);
        if (i < right)
            quickSortWith(arr, data, i, right);
    }

    function sortWith(uint256[] memory arr, uint256[] memory data) private pure {
        quickSortWith(arr, data, int(0), int(arr.length - 1));
    }

    function init() external onlyOwner {
        uint256 currentSupply = totalSupply();
        require(currentSupply == 0, "GigaChad: forbidden");

        for (uint256 tokenId = 143; tokenId <= 152; tokenId++) {
            _mint(_foundationAddress, tokenId);
        }
    }

    function getSaleCountdown() external view returns (uint256) {
        if (block.timestamp >= SALE_START_TIME) {
            return 0;
        } else {
            return SALE_START_TIME - block.timestamp;
        }
    }

    function getTokensForSale() external view returns (uint256) {
        return _tokens.length;
    }

    function getPrice(uint256 count) public view returns (uint256) {
        require(count <= 3, "GigaChad: nonexistent pack");
        require(_tokens.length >= count, "GigaChad: not enough tokens");
        uint256 basePrice = TOKEN_PRICE * count;
        uint256 discount = basePrice * DISCOUNTS[count - 1] / 100;
        return basePrice - discount;
    }

    function mint(uint256 count) external payable returns (uint256[] memory) {
        require(_tokens.length >= count, "GigaChad: not enough tokens");
        require(block.timestamp >= SALE_START_TIME, "GigaChad: sale has not started yet");
        require(msg.value >= getPrice(count), "GigaChad: value sent is below the price");

        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenIndex = rand(0, _tokens.length - 1, i);
            uint256 tokenId = _tokens[tokenIndex];
            _mint(msg.sender, tokenId);
            tokenIds[i] = tokenId;
            _tokens[tokenIndex] = _tokens[_tokens.length - 1];
            delete _tokens[_tokens.length - 1];
            _tokens.pop();
        }
        return tokenIds;
    }

    function assignRewards() external {
        require(!_rewardsAssigned, "GigaChad: forbidden");
        require(block.timestamp >= REWARDS_TIME, "GigaChad: forbidden");

        uint256 rewardIndex = 0;

        for (uint256 i = 0; i < REWARDS_FOR_VOTERS; i++) {
            while (_voterTickets.length > 0 && rewardIndex < _rewards.length) {
                uint256 ticketIndex = rand(0, _voterTickets.length - 1, i);
                address winnerAddress = _voterTickets[ticketIndex];
                if (_winnersRewards[winnerAddress] == 0) {
                    uint256 rewardTokenId = _rewards[rewardIndex];
                    _winnersRewards[winnerAddress] = rewardTokenId;
                    _winners.push(winnerAddress);
                    _voterTickets[ticketIndex] = _voterTickets[_voterTickets.length - 1];
                    _voterTickets.pop();
                    rewardIndex++;
                    break;
                } else {
                    _voterTickets[ticketIndex] = _voterTickets[_voterTickets.length - 1];
                    _voterTickets.pop();
                }
            }
        }

        for (uint256 i = 0; i < REWARDS_FOR_TOKENS; i++) {
            while (_tokenTickets.length > 0 && rewardIndex < _rewards.length) {
                uint256 ticketIndex = rand(0, _tokenTickets.length - 1, i);
                uint256 winnerTokenId = _tokenTickets[ticketIndex];
                address winnerAddress = ownerOf(winnerTokenId);
                if (_winnersRewards[winnerAddress] == 0) {
                    uint256 rewardTokenId = _rewards[rewardIndex];
                    _winnersRewards[winnerAddress] = rewardTokenId;
                    _winners.push(winnerAddress);
                    _tokenTickets[ticketIndex] = _tokenTickets[_tokenTickets.length - 1];
                    _tokenTickets.pop();
                    rewardIndex++;
                    break;
                } else {
                    _tokenTickets[ticketIndex] = _tokenTickets[_tokenTickets.length - 1];
                    _tokenTickets.pop();
                }
            }
        }

        if (rewardIndex < _rewards.length) {
            while (rewardIndex < _rewards.length) {
                uint256 rewardTokenId = _rewards[rewardIndex];
                _mint(_foundationAddress, rewardTokenId);
                rewardIndex++;
            }
        }

        _rewardsAssigned = true;
    }

    function getWinners() external view returns (address[] memory) {
        return _winners;
    }

    function getReward(address winner) public view returns (uint256) {
        return _winnersRewards[winner];
    }

    function claimReward() external returns (uint256) {
        uint256 tokenId = getReward(msg.sender);
        require(tokenId != 0 && !exists(tokenId), "GigaChad: forbidden");
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    function like(uint256 tokenId) external payable {
        require(_exists(tokenId), "GigaChad: nonexistent token");
        require(msg.value >= LIKE_PRICE, "GigaChad: value sent is below the price");

        _likes[tokenId] = _likes[tokenId] + 1;

        _voterTickets.push(msg.sender);
        _tokenTickets.push(tokenId);
    }

    function getLikes(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "GigaChad: nonexistent token");
        return _likes[tokenId];
    }

    function getTop() public view returns (uint256[] memory tokenIds, uint256[] memory likes) {
        uint256 currentSupply = totalSupply();
        uint256[] memory allLikes = new uint256[](currentSupply);
        uint256[] memory allTokenIds = new uint256[](currentSupply);
        uint256 count = 0;
        for (uint256 tokenIndex = 0; tokenIndex < currentSupply; tokenIndex++) {
            uint256 tokenId = tokenByIndex(tokenIndex);
            allLikes[tokenIndex] = _likes[tokenId];
            allTokenIds[tokenIndex] = tokenId;
            if (_likes[tokenId] > 0) {
                count++;
            }
        }
        sortWith(allLikes, allTokenIds);
        likes = new uint256[](count);
        tokenIds = new uint256[](count);
        if (count > 0) {
            uint256 index = 0;
            for (uint256 i = allLikes.length - 1; i >= allLikes.length - count; i--) {
                likes[index] = allLikes[i];
                tokenIds[index] = allTokenIds[i];
                index++;
            }
        }
        return (tokenIds, likes);
    }

    function withdraw() external {
        require(msg.sender == _foundationAddress || msg.sender == _authorAddress || msg.sender == owner(), "GigaChad: forbidden");

        uint256 balance = address(this).balance;
        uint256 authorValue = balance * AUTHOR_SHARE / 100;
        uint256 foundationValue = balance - authorValue;

        _foundationAddress.transfer(foundationValue);
        _authorAddress.transfer(authorValue);
    }

}
