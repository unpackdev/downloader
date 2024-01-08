// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";

contract TheBirdHouseFarm is ERC20, Ownable {

/*
  _____ _          ___ _        _ _  _                    ___               
 |_   _| |_  ___  | _ |_)_ _ __| | || |___ _  _ ___ ___  | __|_ _ _ _ _ __  
   | | | ' \/ -_) | _ \ | '_/ _` | __ / _ \ || (_-</ -_) | _/ _` | '_| '  \ 
   |_| |_||_\___| |___/_|_| \__,_|_||_\___/\_,_/__/\___| |_|\__,_|_| |_|_|_|
                                                                            
*/

    using SafeMath for uint256;

    uint256 public EMISSIONS_RATE = 1150000000000000;
    uint256 public startingTimestamp;
    uint256 public endingTimestamp = 1661832000;

    IERC721Enumerable private TheBirdHouseContract;

    //Mapping of OG bird to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimestamp;

    constructor(address _theBirdHouseAddress) ERC20("BirdSeed", "BIRDSEED") {
        _mint(msg.sender, 10000000000000000000000);

        TheBirdHouseContract = IERC721Enumerable(_theBirdHouseAddress);

        startingTimestamp = block.timestamp;
    }

    /**
     * @dev Calculates rewards since block.
     * @param _blockTimestamp The block timestamp to calculate from.
     */

    function calculateBirdseedByTimestamp(uint256 _blockTimestamp)
        internal
        view
        returns (uint256)
    {
        //Calculate the time passed since the last claim
        uint256 secondsPassed = block.timestamp - _blockTimestamp;
        return secondsPassed * EMISSIONS_RATE;
    }

    /**
     * @dev Returns SEED to be awarded for a token.
     * @param _tokenId The tokenId to view.
     */

    function viewBirdseedForToken(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(_tokenId >= 0 && _tokenId < 6000, "Must use a valid tokenId");

        if (tokenIdToTimestamp[_tokenId] == 0) {
            //If they have yet to claim for this bird, then use the starting timestamp as the from time.
            return calculateBirdseedByTimestamp(startingTimestamp);
        } else {
            //If they have claimed, then use the time of when they last claimed.
            return calculateBirdseedByTimestamp(tokenIdToTimestamp[_tokenId]);
        }
    }

    /**
     * @dev Returns SEED to be awarded for an entire wallet.
     * @param _owner The wallet to view.
     */

    function viewUnclaimedBirdseed(address _owner)
        public
        view
        returns (uint256)
    {
        require(TheBirdHouseContract.balanceOf(_owner) > 0, "Wallet must own at least one bird!");
        uint256 tokenCount = TheBirdHouseContract.balanceOf(_owner);
        uint256 rollingBirdseed;

        for (uint256 i; i < tokenCount; i++) {
            //Loop through all of their tokens and find the tokenId of each one.
            uint256 _tokenId = TheBirdHouseContract.tokenOfOwnerByIndex(
                _owner,
                i
            );
            //Add total to a rolling sum.
            rollingBirdseed = rollingBirdseed + viewBirdseedForToken(_tokenId);
        }

        return rollingBirdseed;
    }

    /**
     * @dev Mints SEED to sender.
     * @param _tokenIds The tokenIds to claim.
     */

    function claimBirdseedForTokenIds(uint256[] memory _tokenIds) public returns (uint256) {
        require(_tokenIds.length > 0, "Must claim at least one bird!");
        require(block.timestamp <= endingTimestamp, "Claim period is over!");
        uint256 rollingBirdseed;

        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(TheBirdHouseContract.ownerOf(_tokenId) == msg.sender, "You can only claim birdseed for birds that you own!");
            rollingBirdseed = rollingBirdseed + viewBirdseedForToken(_tokenId);

            //Set their claim time to now.
            tokenIdToTimestamp[_tokenId] = block.timestamp;
        }

        _mint(msg.sender, rollingBirdseed);
        return rollingBirdseed;
    }

    /**
     * @dev Mints SEED to sender.
     */

    function claimBirdseed() public returns (uint256) {
        require(TheBirdHouseContract.balanceOf(msg.sender) > 0, "Must own at least one bird!");
        require(block.timestamp <= endingTimestamp, "Claim period is over!");
        uint256 tokenCount = TheBirdHouseContract.balanceOf(msg.sender);
        uint256 rollingBirdseed;

        for (uint256 i; i < tokenCount; i++) {
            uint256 _tokenId = TheBirdHouseContract.tokenOfOwnerByIndex(
                msg.sender,
                i
            );
            rollingBirdseed = rollingBirdseed + viewBirdseedForToken(_tokenId);

            //Set their claim time to now.
            tokenIdToTimestamp[_tokenId] = block.timestamp;
        }

        _mint(msg.sender, rollingBirdseed);
        return rollingBirdseed;
    }
}
