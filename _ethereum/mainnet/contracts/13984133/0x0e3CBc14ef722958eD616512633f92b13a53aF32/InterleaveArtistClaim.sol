// contracts/InterleaveArtistClaim.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC1155.sol";
import "./IERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";

/*
  _____       _            _                     
  \_   \_ __ | |_ ___ _ __| | ___  __ ___   _____ 
   / /\/ '_ \| __/ _ \ '__| |/ _ \/ _` \ \ / / _ \
/\/ /_ | | | | ||  __/ |  | |  __/ (_| |\ V /  __/
\____/ |_| |_|\__\___|_|  |_|\___|\__,_| \_/ \___|
*/

interface InterleaveArtistNFTs is IERC1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external returns (bool);
}

/*
The Arcadia Trilogy Credits
- [TimpersHD](https://twitter.com/TimpersHD)
- [David Ariew](https://twitter.com/DavidAriew)
- [DirtyRobot](https://twitter.com/DirtyRobotWorks)
- [BakaArts](https://twitter.com/TheBakaArts)
- [Ramon](https://twitter.com/Ramon_N90)
- [Jack Butcher](https://twitter.com/jackbutcher)
*/

/// @title The NFT contract used to claim Interleave SuperNFT 6 artist drops
/// @notice Contract used to claim the 6 different artist ERC1155 by burning a Interleave SuperNFT
contract InterleaveArtistClaim is Ownable {
    uint256 public claimedCount;

    bool public claimOpen;

    ERC1155Burnable private interleaveSuperNFT;

    InterleaveArtistNFTs private interleaveTimpersHD;
    InterleaveArtistNFTs private interleaveDavidAriew;
    InterleaveArtistNFTs private interleaveDirtyRobot;
    InterleaveArtistNFTs private interleaveBakaArts;
    InterleaveArtistNFTs private interleaveRamon;
    InterleaveArtistNFTs private interleaveJackButcher;

    constructor(
        address _interleaveSuperNFT,
        address _interleaveTimpersHD,
        address _interleaveDavidAriew,
        address _interleaveDirtyRobot,
        address _interleaveBakaArts,
        address _interleaveRamon,
        address _interleaveJackButcher
    ) {
        interleaveSuperNFT = ERC1155Burnable(_interleaveSuperNFT);

        interleaveTimpersHD = InterleaveArtistNFTs(_interleaveTimpersHD);
        interleaveDavidAriew = InterleaveArtistNFTs(_interleaveDavidAriew);
        interleaveDirtyRobot = InterleaveArtistNFTs(_interleaveDirtyRobot);
        interleaveBakaArts = InterleaveArtistNFTs(_interleaveBakaArts);
        interleaveRamon = InterleaveArtistNFTs(_interleaveRamon);
        interleaveJackButcher = InterleaveArtistNFTs(_interleaveJackButcher);

        claimOpen = false;
    }

    function claim(uint256 id) public {
        require(claimOpen, "Artist claiming is not open");

        interleaveSuperNFT.burn(msg.sender, id, 1);

        require(interleaveTimpersHD.mint(msg.sender, 0, 1, ""));
        require(interleaveDavidAriew.mint(msg.sender, 0, 1, ""));
        require(interleaveDirtyRobot.mint(msg.sender, 0, 1, ""));
        require(interleaveBakaArts.mint(msg.sender, 0, 1, ""));
        require(interleaveRamon.mint(msg.sender, 0, 1, ""));
        require(interleaveJackButcher.mint(msg.sender, 0, 1, ""));

        claimedCount++;
    }

    function setInterleaveTimpersHD(address nftInstance) public onlyOwner {
        interleaveTimpersHD = InterleaveArtistNFTs(nftInstance);
    }

    function setInterleaveDavidAriew(address nftInstance) public onlyOwner {
        interleaveDavidAriew = InterleaveArtistNFTs(nftInstance);
    }

    function setInterleaveDirtyRobot(address nftInstance) public onlyOwner {
        interleaveDirtyRobot = InterleaveArtistNFTs(nftInstance);
    }

    function setInterleaveBakaArts(address nftInstance) public onlyOwner {
        interleaveBakaArts = InterleaveArtistNFTs(nftInstance);
    }

    function setInterleaveRamon(address nftInstance) public onlyOwner {
        interleaveRamon = InterleaveArtistNFTs(nftInstance);
    }

    function setInterleaveJackButcher(address nftInstance) public onlyOwner {
        interleaveJackButcher = InterleaveArtistNFTs(nftInstance);
    }

    function toggleClaimOpen() public onlyOwner {
        claimOpen = !claimOpen;
    }
}
