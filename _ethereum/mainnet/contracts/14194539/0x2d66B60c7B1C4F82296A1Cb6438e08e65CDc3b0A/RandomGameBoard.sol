// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./VRFConsumerBase.sol";

enum GameState {
    PreReveal,
    GettingVRF,
    ReceivedVRF,
    Set,
    Complete
}

contract RandomGameBoard is VRFConsumerBase {

    using SafeMath for uint256;

    GameState public gameState;

    uint256[] internal homeTeam = new uint256[](10);
    uint256[] internal awayTeam = new uint256[](10);
    mapping(uint256 => uint256) public homeTeamMap;
    mapping(uint256 => uint256) public awayTeamMap;
    bool public teamAssignment;
    uint256[] public possibleScores = [0,1,2,3,4,5,6,7,8,9];

    uint256[] public homeTeamRandomness;
    uint256[] public awayTeamRandomness;
    uint256 public teamAssignmentRandomness;

    bytes32 internal keyHash;
    uint256 internal VRFfee;
    bytes32 internal VRFRequestId;

    constructor()
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
        0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    ) 
    {
        gameState = GameState.PreReveal;

        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        VRFfee = 2 ether;

        homeTeamRandomness = new uint256[](9);
        awayTeamRandomness = new uint256[](9);
    }

    function getGameBoardRandomness() public virtual returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= VRFfee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, VRFfee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(gameState == GameState.PreReveal,"Game must be in initial state");
        gameState = GameState.GettingVRF;
        assignRandomness(randomness);
    }

    function assignRandomness(uint256 _randomness) internal {
        require(gameState == GameState.GettingVRF,"Game must be in initial state");
        gameState = GameState.ReceivedVRF;

        uint256 nextRandomNumber = uint256(keccak256(abi.encode(_randomness)));

        for(uint256 i=0; i < 9; i++){
            nextRandomNumber = uint256(keccak256(abi.encode(nextRandomNumber)));
            homeTeamRandomness[i] = nextRandomNumber;
            
        }

        for(uint256 i=0; i < 9; i++){
            nextRandomNumber = uint256(keccak256(abi.encode(nextRandomNumber)));
            awayTeamRandomness[i] = nextRandomNumber;
        }

        nextRandomNumber = uint256(keccak256(abi.encode(nextRandomNumber)));
        teamAssignmentRandomness = nextRandomNumber;

    }

    function assignGameBoard() public virtual {
        require(gameState == GameState.ReceivedVRF, "Game in wrong state");
        gameState = GameState.Set;
        
        uint256[] memory digits = possibleScores;
        uint256 randomNumberInRange = 0;

        for(uint256 i = 0; i < 9; i++){
            randomNumberInRange = getRandomNumberInRange(homeTeamRandomness[i],0+i,9);
            digits = swapArrayElement(digits,i,randomNumberInRange);
            homeTeamMap[digits[i]] = i;
        }
        homeTeam = digits;

        digits = possibleScores;

        for(uint256 i = 0; i < 9; i++){
            randomNumberInRange = getRandomNumberInRange(awayTeamRandomness[i],0+i,9);
            digits = swapArrayElement(digits,i,randomNumberInRange);
            awayTeamMap[digits[i]] = i;
        }
        awayTeam = digits;

        randomNumberInRange = getRandomNumberInRange(teamAssignmentRandomness, 0, 1);
        
        if(randomNumberInRange == 0){
            teamAssignment = false;
        }
        else{
            teamAssignment = true;
        }

    }

    function swapArrayElement(uint256[] memory initialArray, uint256 firstElement, uint256 secondElement) public pure returns (uint256[] memory){
        uint256 temp = initialArray[firstElement];
        initialArray[firstElement] = initialArray[secondElement];
        initialArray[secondElement] = temp;
        return initialArray;
    }

    function getRandomNumberInRange(uint256 randomness, uint256 lowerBound, uint256 upperBound) public pure returns (uint256){
        return randomness.mod(upperBound.sub(lowerBound).add(1)).add(lowerBound);
    }

    function getHomeTeamArray() public view returns (uint256[] memory){
        uint256[] memory homeTeamArray = new uint256[](10);
        for(uint256 i = 0; i < 10; i++){
            homeTeamArray[i] = homeTeam[i];
        }
        return homeTeamArray;
    }

    function getAwayTeamArray() public view returns (uint256[] memory){
        uint256[] memory awayTeamArray = new uint256[](10);
        for(uint256 i = 0; i < 10; i++){
            awayTeamArray[i] = awayTeam[i];
        }
        return awayTeamArray;
    }
    

}