/*

     ___   .___________.  ______   .___  ___. ____    ____  _______ .______          _______. _______ 
    /   \  |           | /  __  \  |   \/   | \   \  /   / |   ____||   _  \        /       ||   ____|
   /  ^  \ `---|  |----`|  |  |  | |  \  /  |  \   \/   /  |  |__   |  |_)  |      |   (----`|  |__   
  /  /_\  \    |  |     |  |  |  | |  |\/|  |   \      /   |   __|  |      /        \   \    |   __|  
 /  _____  \   |  |     |  `--'  | |  |  |  |    \    /    |  |____ |  |\  \----.----)   |   |  |____ 
/__/     \__\  |__|      \______/  |__|  |__|     \__/     |_______|| _| `._____|_______/    |_______|
                                                                                                      

*/


// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.6;

import "./atomverse_genesis.sol";
import "./nuclei.sol";

contract atomverse_staking is Ownable, IERC721Receiver {
    
    event NFTStaked(address owner, uint256 tokenId, uint256 timestamp);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 timestamp);
    event Claimed(address owner, uint256 amount);
    
    constructor(atomverse_genesis _nft, nuclei _token) {
        atomverse_nft = _nft;
        nucleiToken = _token;
    }
    atomverse_genesis atomverse_nft;
    nuclei nucleiToken;

    uint256 public totalStaked;
    uint256[] public scores;
    
    
    struct Stake {
        uint24 tokenId;
        uint48 timestamp;
        address owner;
    }
    mapping(uint256 => Stake) public cryoChambers;


    function setScores(uint256[] memory _scores) external onlyOwner {
        for (uint256 i = 0; i < _scores.length; i++) {
            scores.push(_scores[i]);
        }
    }

    function reSetScores(uint256[] memory _scores) external onlyOwner {
        scores = _scores;
    }

    function stake(uint256[] calldata tokenIds) external {
        uint256 tokenId;
        totalStaked += tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(
                atomverse_nft.ownerOf(tokenId) == msg.sender,
                "not your token"
            );
            require(cryoChambers[tokenId].tokenId == 0, "already staked");

            atomverse_nft.transferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, tokenId, block.timestamp);

            cryoChambers[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
    }

    function _unstakeMany(address account, uint256[] calldata tokenIds)
        internal
    {
        uint256 tokenId;
        totalStaked -= tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = cryoChambers[tokenId];
            require(staked.owner == msg.sender, "not an owner");

            delete cryoChambers[tokenId];
            atomverse_nft.transferFrom(address(this), account, tokenId);
            emit NFTUnstaked(account, tokenId, block.timestamp);
            
        }
    }

    function claim(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, false);
    }

    function claimForAddress(address account, uint256[] calldata tokenIds)
        external
    {
        _claim(account, tokenIds, false);
    }

    function unstake(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, true);
    }

    function _claim(
        address account,
        uint256[] calldata tokenIds,
        bool _unstake
    ) internal {
        uint256 tokenId;
        uint256 earned = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            uint256 _earned = 0;
            Stake memory staked = cryoChambers[tokenId];
            require(staked.owner == account, "not an owner");
            uint256 stakedAt = staked.timestamp;
            uint256 timeElapsedScore = (block.timestamp - stakedAt);
            uint256 rarityScore = scores[tokenId];
            _earned = (timeElapsedScore * rarityScore)/12 minutes;
            _earned = 1 ether * _earned;
            _earned = _earned / 100;
            earned += _earned;

            cryoChambers[tokenId] = Stake({
                owner: account,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
        if (earned > 0) {
            nucleiToken.mint(account, earned);
        }
        if (_unstake) {
            _unstakeMany(account, tokenIds);
        }
        emit Claimed(account, earned);
    }

    function earningInfo(uint256[] calldata tokenIds)
        external
        view
        returns (uint256 info)
    {
        uint256 tokenId = 0;
        uint256 earned = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 _earned = 0;
            tokenId = tokenIds[i];
            Stake memory staked = cryoChambers[tokenId];
            if (staked.tokenId !=0){
                uint256 stakedAt = staked.timestamp;
                uint256 timeElapsedScore = (block.timestamp - stakedAt);
                uint256 rarityScore = scores[tokenId];
                _earned = (timeElapsedScore * rarityScore)/12 minutes;
                _earned = 1 ether * _earned;
                _earned = _earned / 100;
                earned += _earned;
            }
        }
        return earned;
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = 0;
        uint256 supply = 4444;
        for (uint256 i = 1; i <= supply; i++) {
            if (cryoChambers[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    function tokensOfOwner(address account)
        public
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 supply = 4444;
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= 4444; tokenId++) {
            if (cryoChambers[tokenId].owner == account) {
                tmp[index] = cryoChambers[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function unStakeAll() external onlyOwner {
        for (uint256 tokenId = 1; tokenId <= 4444; tokenId++) {
            Stake memory staked = cryoChambers[tokenId];
            if (staked.tokenId != 0) {
                delete cryoChambers[tokenId];
                emit NFTUnstaked(staked.owner, tokenId, block.timestamp);
                atomverse_nft.transferFrom(
                    address(this),
                    staked.owner,
                    tokenId
                );
            }
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(
            from == address(0x0),
            "Cannot send nfts to cryoChambers directly"
        );
        return IERC721Receiver.onERC721Received.selector;
    }
}
