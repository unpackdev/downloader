// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";


contract MetaOasisStaking is IERC721Receiver, Ownable {
    event eventRequest(address user, Stake stake);
    event eventClaim(address user, uint256 reward);

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 private token;
    IERC721 private nft;
    address private nftAddress;


    uint256 public timeLimit;
    uint256 public regular;
    uint256 public premium;
    uint256 public royal;
    uint256 public special;


    struct Stake {
        uint256[] tokenIds; // stake tokenid
        uint256[] blocks; // stake block number

        uint256 claimAvailable; // claim Available count
        uint256 claimAvailableTime; // claim Available time
        uint256 claimedTotal; // claimed Total count
    }


    // [tokenid] = address
    mapping (uint256 => address) private stakingAddress;
    // [address] = struct Stake
    mapping (address => Stake) private stakingList;


    constructor(
        IERC20 _token,
        IERC721 _nft,
        address _nftAddress,
        uint256 _timeLimit,
        uint256 _regular,
        uint256 _premium,
        uint256 _royal,
        uint256 _special
    ) public {
        token = IERC20(_token);
        nft = IERC721(_nft);
        nftAddress = _nftAddress;
        timeLimit = _timeLimit;

        regular = _regular;
        premium = _premium;
        royal = _royal;
        special = _special;
    }


    function staking(uint256[] memory tokenIds) public {
        for (uint256 i = 0 ; i < tokenIds.length; i++) {
            require(msg.sender == nft.ownerOf(tokenIds[i]), 'Must be owner');


            nft.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }


    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns (bytes4) {
        require(msg.sender == nftAddress, 'Not allowed NFT');

        stakingAddress[tokenId] = from;


        Stake storage staker = stakingList[from];
        staker.tokenIds.push(tokenId);
        staker.blocks.push(block.number);
        

        return this.onERC721Received.selector;
    }


    function unStaking(uint256[] memory tokenIds) public {
        require(stakingList[msg.sender].claimAvailable == 0, "Not possible during claim");


        for (uint256 i = 0 ; i < tokenIds.length; i++) {
            require(msg.sender == stakingAddress[tokenIds[i]], 'Must be the same user');


            // set claimAvailable
            stakingList[msg.sender].claimAvailable = getReward(msg.sender);
            stakingList[msg.sender].claimAvailableTime = block.timestamp + (timeLimit * 1 hours);


            // reset stakingAddress[tokenid]
            stakingAddress[tokenIds[i]] = address(0);


            uint256 index = 0;
            for (uint256 j = 0; j < stakingList[msg.sender].tokenIds.length; j++) {
                if (stakingList[msg.sender].tokenIds[j] != 0 &&
                    stakingList[msg.sender].tokenIds[j] == tokenIds[i]) {
                    index = j;
                    break;
                }
            }

            // reset stakingList[address].tokenId
            delete stakingList[msg.sender].tokenIds[index];
            delete stakingList[msg.sender].blocks[index];


            
            // send NFT
            nft.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }



    // requst claim
    function requestClaim() public {
        require(stakingList[msg.sender].claimAvailable == 0, "can not request duplicate");


        stakingList[msg.sender].claimAvailable = getReward(msg.sender);
        stakingList[msg.sender].claimAvailableTime = block.timestamp + (timeLimit * 1 hours);
        for (uint256 i = 0; i < stakingList[msg.sender].tokenIds.length; i++) {
            if (stakingList[msg.sender].tokenIds[i] != 0) {
                stakingList[msg.sender].blocks[i] = block.number;
            }
        }

        emit eventRequest(msg.sender, stakingList[msg.sender]);
    }


    function claim() public {
        require(stakingList[msg.sender].claimAvailableTime < block.timestamp, "Not yet available");
        require(stakingList[msg.sender].claimAvailable > 0, "do not have claim");
        require(token.balanceOf(address(this)) >= stakingList[msg.sender].claimAvailable, 'empty token');


        // send token
        uint256 reward = stakingList[msg.sender].claimAvailable;
        token.transfer(msg.sender, reward * 10 ** 9);


        // update status
        stakingList[msg.sender].claimAvailable = 0;
        stakingList[msg.sender].claimAvailableTime = 0;
        stakingList[msg.sender].claimedTotal = stakingList[msg.sender].claimedTotal + reward;


        emit eventClaim(msg.sender, reward);
    }





    // ***** public view *****
    function getStakingAddress(uint256 tokenId) public view returns (address) {
        return stakingAddress[tokenId];
    }
    function getStakingList(address user) public view returns (Stake memory stake) {
        return stakingList[user];
    }

    // cal reward count
    function getReward(address user) public view returns (uint256) {
        uint256 reward = 0;
        for (uint256 i = 0; i < stakingList[user].tokenIds.length; i++) {
            if (stakingList[user].tokenIds[i] != 0) {
                // 1: Regular, 2: Premium, 3: Royal, 4: Special
                uint256 prefix = uint256(SafeMath.div(stakingList[user].tokenIds[i], 1000000));
                uint256 ratio = 0;
                if (prefix == 1) {
                    ratio = regular;
                }
                if (prefix == 2) {
                    ratio = premium;
                }
                if (prefix == 3) {
                    ratio = royal;
                }
                if (prefix == 4) {
                    ratio = special;
                }

                uint256 diff = block.number - stakingList[user].blocks[i];
                reward = reward + (diff * ratio);
            }
        }
        return reward;
    }


    // onlyOwner
    function setRatio(uint256 _regular, uint256 _premium, uint256 _royal, uint256 _special, uint256 _timeLimit) public onlyOwner {
        regular = _regular;
        premium = _premium;
        royal = _royal;
        special = _special;

        timeLimit = _timeLimit;
    }
    function withdraw (address payable _account, uint256 _amount) public onlyOwner {
        require(address(_account) != address(0) && address(_account) != address(this), 'wrong address');
        require(token.balanceOf(address(this)) >= _amount, 'empty token');

        token.transfer(_account, _amount);
    }
}