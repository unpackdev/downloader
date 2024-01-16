// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./OwnableUpgradeable.sol";
import "./IERC721.sol";

import "./IEternalVikings.sol";
import "./IEternalVikingsYielder.sol";

contract EternalVikingsStaking is OwnableUpgradeable {
    IEternalVikings public EVNFT;
    IEternalVikingsYielder public EVYielderModule;
    address public EVSacrificerModule;
   
    mapping(address => uint256) public walletEVStakeCount;

    constructor(
        address ev
    ) {}

    function initialize(
        address ev
    ) public initializer {
        __Ownable_init();
        EVNFT = IEternalVikings(ev);        
    }

    receive() external payable {
        payable(owner()).transfer(address(this).balance);
    }

    function stakeVikings(uint256[] memory vikingIds) external {
        require(vikingIds.length > 0, "Viking array empty");

        EVYielderModule.registerShadowEarnings(msg.sender);
        for (uint i = 0; i < vikingIds.length; i++) {
            uint256 vikingId = vikingIds[i];
            require(IERC721(address(EVNFT)).ownerOf(vikingId) == msg.sender, "Viking not owned by user");
            EVNFT.setStakingStatusOfToken(vikingId, true);
        }
        walletEVStakeCount[msg.sender] += vikingIds.length;
    }

    function delegateStakeVikings(address user, uint256[] memory vikingIds) external {
        require(EVSacrificerModule != address(0), "Sacrifice module not initialized");
        require(msg.sender == EVSacrificerModule, "Sender not sacrificer");
        require(vikingIds.length > 0, "Viking array empty");

        EVYielderModule.registerShadowEarnings(user);
        for (uint i = 0; i < vikingIds.length; i++) {
            uint256 vikingId = vikingIds[i];
            require(IERC721(address(EVNFT)).ownerOf(vikingId) == user, "Viking not owned by user");
            EVNFT.setStakingStatusOfToken(vikingId, true);
        }
        walletEVStakeCount[user] += vikingIds.length;
    }

    function unstakeVikings(uint256[] memory vikingIds) external {
        require(vikingIds.length > 0, "Viking array empty");
        
        EVYielderModule.registerShadowEarnings(msg.sender);
        for (uint i = 0; i < vikingIds.length; i++) {
            uint256 vikingId = vikingIds[i];
            require(EVNFT.stakingOwner(vikingId) == msg.sender, "Viking not owned by user");
            EVNFT.setStakingStatusOfToken(vikingId, false);
        }
        walletEVStakeCount[msg.sender] -= vikingIds.length;
    }

    function getStakedVikingIdsOfUser(address user) external view returns(uint256[] memory) {
        uint256 balanceOfUser = EVNFT.balanceOf(user);
        uint256[] memory userTokens = new uint256[](balanceOfUser);
        userTokens = EVNFT.tokensOfOwner(user);

        uint256 counter;
        uint256 stakedTokensOfUser = walletEVStakeCount[user];
        uint256[] memory userStakedTokens = new uint256[](stakedTokensOfUser);
        for (uint i = 0; i < userTokens.length; i++) {
            uint256 token = userTokens[i];
            if (EVNFT.tokenToStaked(token) != 0) {
                userStakedTokens[counter] = token;
                counter++;
            }
        }
        return userStakedTokens;
    }

    function getUnstakedVikingIdsOfUser(address user) external view returns(uint256[] memory) {
        uint256 balanceOfUser = EVNFT.balanceOf(user);
        uint256[] memory userTokens = new uint256[](balanceOfUser);
        userTokens = EVNFT.tokensOfOwner(user);

        uint256 counter;
        uint256 stakedTokensOfUser = walletEVStakeCount[user];
        uint256[] memory userNotStakedTokens = new uint256[](balanceOfUser - stakedTokensOfUser);
        for (uint i = 0; i < userTokens.length; i++) {
            uint256 token = userTokens[i];
            if (EVNFT.tokenToStaked(token) == 0) {
                userNotStakedTokens[counter] = token;
                counter++;
            }
        }
        return userNotStakedTokens;
    }

    function getStakedTimestampsOfVikings(uint256[] memory vikings) external view returns (uint256[] memory) {      
        uint256[] memory stakedTimestamps = new uint256[](vikings.length);
        for (uint i = 0; i < vikings.length; i++) {
            uint256 token = vikings[i];
            stakedTimestamps[i] = EVNFT.tokenToStaked(token);            
        }
        return stakedTimestamps;
    }


    function setEVNFT(address evNFT) external onlyOwner {
        EVNFT = IEternalVikings(evNFT);
    }

    function setYielderModule(address yielderAddress) external onlyOwner {
        EVYielderModule = IEternalVikingsYielder(yielderAddress);
    }

    function setSacrificerModule(address sacrificer) external onlyOwner {
        EVSacrificerModule = sacrificer;
    }
}