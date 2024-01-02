// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";

error HouseIsNotActive();
error NotAnNFTOwner();
error NotEnoughFunds();
error NotEnoughFundsOnContract();
error NotEnoughNFTsOnContract();
error NoTokensToSellOrStakeOrUnstake();
error NoFundsToClaim();

contract House is ERC721Holder, Ownable {
    using SafeERC20 for IERC20;

    uint public immutable area;
    address public immutable ftAddress;
    address public immutable nftAddress;
    address public immutable rewardsAddress;
    bool public isActive = false;

    uint private constant NFT_PRICE = 1000 * 1e18;
    uint private constant SELL_COEF_BP = 9900;
    uint[] private NFTsPool;
    mapping(address => uint[]) private stakedNFTs;
    mapping(address => User) private users;
    address[] private userAddresses;
    uint private totalStakedInPeriod = 0;

    struct User {
        uint112 totalEarned;
        uint112 totalClaimed;
        uint24 totalStakedInPeriod;
        bool isActive;
    }

    constructor(
        uint _area,
        address _ftAddress,
        address _nftAddress,
        address _rewardsAddress
    ) payable {
        area = _area;
        ftAddress = _ftAddress;
        nftAddress = _nftAddress;
        rewardsAddress = _rewardsAddress;
    }

    function availableNFTs() public view returns (uint) {
        return NFTsPool.length;
    }

    function getUserNFTs(address _address) public view returns (uint[] memory) {
        return stakedNFTs[_address];
    }

    function getUserInfo(address _address) public view returns (User memory) {
        return users[_address];
    }

    function activateHouse(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function buyNFT(uint _nftAmount) external {
        if (!isActive) {
            revert HouseIsNotActive();
        }
        if (
            _nftAmount * NFT_PRICE >
            IERC20(ftAddress).balanceOf(address(msg.sender))
        ) {
            revert NotEnoughFunds();
        }
        if (NFTsPool.length < _nftAmount) {
            revert NotEnoughNFTsOnContract();
        }
        IERC20(ftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _nftAmount * NFT_PRICE
        );
        for (uint i = 0; i < _nftAmount; i++) {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                NFTsPool[NFTsPool.length - 1]
            );
            NFTsPool.pop();
        }
    }

    function sellNFT(uint[] memory _tokenIds) external {
        if (!isActive) {
            revert HouseIsNotActive();
        }
        if (_tokenIds.length == 0) {
            revert NoTokensToSellOrStakeOrUnstake();
        }
        if (
            ((_tokenIds.length * NFT_PRICE * SELL_COEF_BP) / 10_000) >
            IERC20(ftAddress).balanceOf(address(this))
        ) {
            revert NotEnoughFundsOnContract();
        }
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (
                IERC721(nftAddress).ownerOf(_tokenIds[i]) != address(msg.sender)
            ) {
                revert NotAnNFTOwner();
            }
            IERC721(nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
            NFTsPool.push(_tokenIds[i]);
        }
        IERC20(ftAddress).safeTransfer(
            msg.sender,
            (_tokenIds.length * NFT_PRICE * SELL_COEF_BP) / 10_000
        );
    }

    function stakeNFT(uint[] memory _tokenIds) external {
        if (!isActive) {
            revert HouseIsNotActive();
        }
        if (_tokenIds.length == 0) {
            revert NoTokensToSellOrStakeOrUnstake();
        }
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (
                IERC721(nftAddress).ownerOf(_tokenIds[i]) != address(msg.sender)
            ) {
                revert NotAnNFTOwner();
            }
            IERC721(nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
            stakedNFTs[msg.sender].push(_tokenIds[i]);
        }
        if (users[msg.sender].isActive == false) {
            userAddresses.push(msg.sender);
            users[msg.sender].isActive = true;
        }
    }

    function unstakeNFT(uint[] memory _tokenIds) external {
        if (!isActive) {
            revert HouseIsNotActive();
        }
        if (_tokenIds.length == 0) {
            revert NoTokensToSellOrStakeOrUnstake();
        }
        uint[] storage tokens = stakedNFTs[msg.sender];
        uint tokensToUnstake = 0;
        uint tokensIdsLength = _tokenIds.length;
        for (uint i = 0; i < tokensIdsLength; i++) {
            for (uint j = 0; j < tokens.length; j++) {
                if (_tokenIds[i] == tokens[j]) {
                    tokensToUnstake++;
                    tokens[j] = tokens[tokens.length - 1];
                    tokens.pop();
                    break;
                }
            }
            if (tokensIdsLength == tokensToUnstake) {
                break;
            }
        }
        if (tokensToUnstake != tokensIdsLength) {
            revert NotAnNFTOwner();
        }
        for (uint i = 0; i < tokensIdsLength; i++) {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
            if (users[msg.sender].totalStakedInPeriod > 0) {
                users[msg.sender].totalStakedInPeriod -= 1;
            }
            if (totalStakedInPeriod > 0) {
                totalStakedInPeriod -= 1;
            }
        }
        if (tokens.length == 0) {
            users[msg.sender].isActive = false;
            uint addressesLength = userAddresses.length;
            for (uint i = 0; i < addressesLength; i++) {
                if (userAddresses[i] == msg.sender) {
                    userAddresses[i] = userAddresses[addressesLength - 1];
                    userAddresses.pop();
                    break;
                }
            }
        }
    }

    function distributeRewards(uint _rewards) external onlyOwner {
        if (_rewards > IERC20(rewardsAddress).balanceOf(address(this))) {
            revert NotEnoughFundsOnContract();
        }
        uint reward;
        uint usersLength = userAddresses.length;
        if (totalStakedInPeriod == 0) {
            reward = 0;
        } else {
            reward = _rewards / totalStakedInPeriod;
        }
        totalStakedInPeriod = 0;
        for (uint i = 0; i < usersLength; i++) {
            uint userReward = reward *
                users[userAddresses[i]].totalStakedInPeriod;
            if (userReward > 0) {
                users[userAddresses[i]].totalEarned += uint112(userReward);
            }
            uint userStakedAmount = stakedNFTs[userAddresses[i]].length;
            users[userAddresses[i]].totalStakedInPeriod = uint24(
                userStakedAmount
            );
            totalStakedInPeriod += userStakedAmount;
        }
    }

    function claimRewards() external {
        if (!isActive) {
            revert HouseIsNotActive();
        }
        address user = msg.sender;
        uint reward = users[user].totalEarned - users[user].totalClaimed;
        if (reward <= 0) {
            revert NoFundsToClaim();
        }
        if (reward > IERC20(rewardsAddress).balanceOf(address(this))) {
            revert NotEnoughFundsOnContract();
        }
        IERC20(rewardsAddress).safeTransfer(user, reward);
        users[user].totalClaimed += uint112(reward);
    }

    function withdrawRewards() external onlyOwner {
        uint balance = IERC20(rewardsAddress).balanceOf(address(this));
        if (balance <= 0) {
            revert NoFundsToClaim();
        }
        IERC20(rewardsAddress).safeTransfer(msg.sender, balance);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint _tokenId,
        bytes memory _data
    ) public override returns (bytes4) {
        require(
            msg.sender == nftAddress ||
                (_operator == nftAddress && msg.sender == address(0)),
            "ERC721: wrong NFT collection"
        );
        if (_from == address(0)) {
            NFTsPool.push(_tokenId);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        if (balance <= 0) {
            revert NoFundsToClaim();
        }
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
