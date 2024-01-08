//     _ _   _ _   _  ____ _     _____
//     | | | | | \ | |/ ___| |   | ____|
//  _  | | | | |  \| | |  _| |   |  _|
// | |_| | |_| | |\  | |_| | |___| |___
//  \___/ \___/|_| \_|\____|_____|_____|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./Apes.sol";
import "./Bananas.sol";

contract Jungle is Ownable, IERC721Receiver {
    using SafeMath for uint256;

    //Establish interface for Apes
    Apes apes;

    //Establish interface for $BANANAS
    Bananas bananas;

    event ApeStolen(address previousOwner, address newOwner, uint256 tokenId);
    event ApeStaked(address owner, uint256 tokenId, uint256 status);
    event ApeClaimed(address owner, uint256 tokenId);

    /* Struct to track token info
    Status is as follows:
        0 - Unstaked
        1 - HungryApe
        2 - GreedyApe
        3 - MutantApe
    */
    struct tokenInfo {
        uint256 tokenId;
        address owner;
        uint256 status;
        uint256 timeStaked;
    }

    // maps id to token info structure
    mapping(uint256 => tokenInfo) public jungle;

    //Amount token id to amount stolen
    mapping(uint256 => uint256) public bananasStolen;

    //Daily $BANANAS earned by HungryApes
    uint256 public hungryApeBananasRate = 100 ether;
    //Total number of HungryApes staked
    uint256 public totalHungryApesStaked = 0;
    //Percent of $BANANAS earned by HungryApes that is kept
    uint256 public hungryApeShare = 50;

    //Percent of $BANANAS earned by hungryApes that is stolen by GreedyApes
    uint256 public greedyApeShare = 50;
    //5% chance a greedyApe gets lost each time it is unstaked
    uint256 public chanceGreedyApeGetsLost = 5;

    //Store tokenIds of all GreedyApes staked
    uint256[] public greedyApesStaked;
    //Store Index of greedyApes staked
    mapping(uint256 => uint256) public greedyApeIndices;

    //Store tokenIds of all mutantApes staked
    uint256[] public mutantApesStaked;
    //Store Index of mutantApes staked
    mapping(uint256 => uint256) public mutantApeIndices;

    //1 day lock on staking
    uint256 public minStakeTime = 1 days;

    bool public staking = false;

    //Used to keep track of total Apes supply
    uint256 public totalSupply = 5000;

    constructor(){}



    //Mint Apes for bananas
    function mintApeForBananas(bool stake, uint256 status) public {
        require(staking, "Staking is paused");
        bananas.burn(msg.sender, getBananasCost(totalSupply));
        apes.mintApeForBananas();
        uint256 tokenId = totalSupply;
        totalSupply++;
        if(stake){
            jungle[tokenId] = tokenInfo({
                tokenId: tokenId,
                owner: msg.sender,
                status: status,
                timeStaked: block.timestamp
            });
            if (status == 1)
                totalHungryApesStaked++;
            else if (status == 2){
                greedyApesStaked.push(tokenId);
                greedyApeIndices[tokenId] = greedyApesStaked.length - 1;
            }
            else if (status == 3){
                mutantApesStaked.push(tokenId);
                mutantApeIndices[tokenId] = mutantApesStaked.length - 1;
            }
        } else {
            apes.safeTransferFrom(address(this), msg.sender, tokenId);
        }

    }

    function getBananasCost(uint256 supply) internal pure returns (uint256 cost){
   if (supply < 6000)
            return 100;            
        else if (supply < 8000)
            return 200;
        else if (supply < 10000)
            return 400;
        else if (supply < 12000)
            return 800;
         else if (supply < 14000)
            return 1000;
         else if (supply < 15000)
            return 1200;
    }

    //-----------------------------------------------------------------------------//
    //------------------------------Staking----------------------------------------//
    //-----------------------------------------------------------------------------//

    /*sends any number of Apes to the jungle
        ids -> list of ape ids to stake
        Status == 1 -> HungryApe
        Status == 2 -> GreedyApe
        Status == 3 -> MutantApe
    */
    function sendManyToJungle(uint256[] calldata ids, uint256 status) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(apes.ownerOf(ids[i]) == msg.sender, "Not your Ape");
            require(staking, "Staking is paused");

            jungle[ids[i]] = tokenInfo({
                tokenId: ids[i],
                owner: msg.sender,
                status: status,
                timeStaked: block.timestamp
            });

            emit ApeStaked(msg.sender, ids[i], status);
            apes.transferFrom(msg.sender, address(this), ids[i]);

            if (status == 1)
                totalHungryApesStaked++;
            else if (status == 2){
                greedyApesStaked.push(ids[i]);
                greedyApeIndices[ids[i]] = greedyApesStaked.length - 1;
            }
            else if (status == 3){
                mutantApesStaked.push(ids[i]);
                mutantApeIndices[ids[i]] = mutantApesStaked.length - 1;

            }
        }
    }

    function unstakeManyApes(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            tokenInfo memory token = jungle[ids[i]];
            require(token.owner == msg.sender, "Not your Ape");
            require(apes.ownerOf(ids[i]) == address(this), "Ape must be staked in order to claim");
            require(staking, "Staking is paused");
            require(block.timestamp - token.timeStaked >= minStakeTime, "1 day stake lock");

            _claim(msg.sender, ids[i]);

            if (token.status == 1){
                totalHungryApesStaked--;
            }
            else if (token.status == 2){
                uint256 lastGreedyApe = greedyApesStaked[greedyApesStaked.length - 1];
                greedyApesStaked[greedyApeIndices[ids[i]]] = lastGreedyApe;
                greedyApeIndices[lastGreedyApe] = greedyApeIndices[ids[i]];
                greedyApesStaked.pop();
            }
            else if (token.status == 3){
                uint256 lastMutantApe = mutantApesStaked[mutantApesStaked.length - 1];
                mutantApesStaked[mutantApeIndices[ids[i]]] = lastMutantApe;
                mutantApeIndices[lastMutantApe] = mutantApeIndices[ids[i]];
                mutantApesStaked.pop();
            }

            emit ApeClaimed(address(this), ids[i]);

            //retrieve token info again to account for stolen Apes
            tokenInfo memory newToken = jungle[ids[i]];
            apes.safeTransferFrom(address(this), newToken.owner, ids[i]);
            jungle[ids[i]] = tokenInfo({
                tokenId: ids[i],
                owner: newToken.owner,
                status: 0,
                timeStaked: block.timestamp
            });
        }
    }

    function claimManyApes(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            tokenInfo memory token = jungle[ids[i]];
            require(token.owner == msg.sender, "Not your Ape");
            require(apes.ownerOf(ids[i]) == address(this), "Ape must be staked in order to claim");
            require(staking, "Staking is paused");

            _claim(msg.sender, ids[i]);
            emit ApeClaimed(address(this), ids[i]);

            //retrieve token info again to account for stolen Apes
            tokenInfo memory newToken = jungle[ids[i]];
            jungle[ids[i]] = tokenInfo({
                tokenId: ids[i],
                owner: newToken.owner,
                status: newToken.status,
                timeStaked: block.timestamp
            });
        }
    }

    function _claim(address owner, uint256 tokenId) internal {
        tokenInfo memory token = jungle[tokenId];
        if (token.status == 1){
            if(greedyApesStaked.length > 0){
                uint256 bananasGathered = getPendingBananas(tokenId);
                bananas.mint(owner, bananasGathered.mul(hungryApeShare).div(100));
                stealBananas(bananasGathered.mul(greedyApeShare).div(100));
            }
            else {
                bananas.mint(owner, getPendingBananas(tokenId));
            }
        }
        else if (token.status == 2){
            uint256 roll = randomIntInRange(tokenId, 100);
            if(roll > chanceGreedyApeGetsLost || mutantApesStaked.length == 0){
                bananas.mint(owner, bananasStolen[tokenId]);
                bananasStolen[tokenId ]= 0;
            } else{
                getNewOwnerForGreedyApe(roll, tokenId);
            }
        }
    }

    //Public function to view pending $BANANAS earnings for HungryApes.
    function getBananasEarnings(uint256 id) public view returns(uint256) {
        return getPendingBananas(id);
    }

    //Passive earning of $BANANAS, 100 $BANANAS per day
    function getPendingBananas(uint256 id) internal view returns(uint256) {
        tokenInfo memory token = jungle[id];
        return (block.timestamp - token.timeStaked) * 100 ether / 1 days;
    }

    //Returns a pseudo-random integer between 0 - max
    function randomIntInRange(uint256 seed, uint256 max) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        ))) % max;
    }

    //Return new owner of lost GreedyApe from current mutantApes
    function stealBananas(uint256 amount) internal{
        uint256 roll = randomIntInRange(amount, greedyApesStaked.length);
        bananasStolen[greedyApesStaked[roll]] += amount;
    }

    //Return new owner of lost greedyApe from current mutantApes
    function getNewOwnerForGreedyApe(uint256 seed, uint256 tokenId) internal{
        tokenInfo memory greedyApe = jungle[tokenId];
        uint256 roll = randomIntInRange(seed, mutantApesStaked.length);
        tokenInfo memory mutantApe = jungle[mutantApesStaked[roll]];
        emit ApeStolen(greedyApe.owner, mutantApe.owner, tokenId);
        jungle[tokenId] = tokenInfo({
                tokenId: tokenId,
                owner: mutantApe.owner,
                status: 2,
                timeStaked: block.timestamp
        });
        bananas.mint(mutantApe.owner, bananasStolen[tokenId]);
        bananasStolen[tokenId] = 0;
    }

    function getTotalMutantApesStaked() public view returns (uint256) {
        return mutantApesStaked.length;
    }

    function getTotalGreedyApesStaked() public view returns (uint256) {
        return greedyApesStaked.length;
    }

    //Set address for Apes
    function setApeAddress(address apeAddr) external onlyOwner {
        apes = Apes(apeAddr);
    }

    //Set address for $BANANAS
    function setBananasAddress(address bananasAddr) external onlyOwner {
        bananas = Bananas(bananasAddr);
    }

    //Start/Stop staking
    function toggleStaking() public onlyOwner {
        staking = !staking;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
    }
}