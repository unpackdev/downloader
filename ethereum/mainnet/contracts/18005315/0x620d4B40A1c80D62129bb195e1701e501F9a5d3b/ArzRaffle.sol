// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ArzNFT.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

/*
Things to Improve:
- Automate reset
*/

contract ArzRaffle is Ownable  {

    address public tokenAddress;
    
    struct Participant{
        bool hasEntered;
        uint256 won; 
    }
    struct PrizeInfo {
        bool COMPETITIVE_WHITELIST;
        bool GUARANTEED_WHITELIST;
        bool AIRDROP;
    }
    struct RaffleInfo {
        uint START_TIME;
        uint END_TIME;
        uint256 RESET_DURATION_HOURS;
        uint256 SLOT_PRICE;
        uint256 NUM_ENTERED;
        uint256 MAX_COMP_WHITELIST;
        uint256 MAX_GUARANTEED_WHITELIST;
        uint256 MAX_AIRDROP;
        uint256 TOTAL_PRIZES;
    }
    RaffleInfo public raffleInfo;
    PrizeInfo[] prizes;
    address[] enteredAddresses; 
    mapping(address => Participant) participants;

    uint256 j = 1;

    //Constructor
    constructor(
        address _tokenAddress
    ) 
    {
        tokenAddress = _tokenAddress;
    }

    ////////////////////////////
    // Settors and Accessors //
    ///////////////////////////
    function emptyPrizes() internal {
        while(prizes.length > 0) {
            prizes.pop();
        }
    }

    function setRaffleParams(
        uint _START_TIME,
        uint _END_TIME,
        uint256 _RESET_DURATION_HOURS,
        uint256 _SLOT_PRICE_WEI,
        uint256 _MAX_COMP_WHITELIST,
        uint256 _MAX_GUARANTEED_WHITELIST,
        uint256 _MAX_AIRDROP
    ) public onlyOwner {
        require(
            (_START_TIME == 0 ||
            _END_TIME - _START_TIME > 0) && _SLOT_PRICE_WEI >= 0,
            "Invalid raffle setup"
        );

        emptyPrizes();

        raffleInfo = RaffleInfo(
            _START_TIME,
            _END_TIME,
            _RESET_DURATION_HOURS * 1 hours,
            _SLOT_PRICE_WEI,
            0,
            _MAX_COMP_WHITELIST,
            _MAX_GUARANTEED_WHITELIST,
            _MAX_AIRDROP, 
            ( _MAX_COMP_WHITELIST + _MAX_GUARANTEED_WHITELIST + _MAX_AIRDROP)
        );

        for(uint256 i = 0; i < _MAX_COMP_WHITELIST; i++) {
            prizes.push(PrizeInfo(true, false, false));
        }

        for(uint256 i = 0; i < _MAX_GUARANTEED_WHITELIST; i++) {
            prizes.push(PrizeInfo(false, true, false));
        }

        for(uint256 i = 0; i < _MAX_AIRDROP; i++) {
            prizes.push(PrizeInfo(false, false, true));
        }

        require(prizes.length == raffleInfo.TOTAL_PRIZES, "Array Error");

        for (uint256 i = 0; i < raffleInfo.TOTAL_PRIZES; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (prizes.length - i);
            PrizeInfo memory temp = prizes[n];
            prizes[n] = prizes[i];
            prizes[i] = temp;
        }
    }

    function getRafflePrice() public view returns (uint256) {
        return raffleInfo.SLOT_PRICE;
    }

    function getEntranceState(address _user) public view returns (bool) {
        return participants[_user].hasEntered;
    }

    function getPrize(address _user) public view returns (uint256) {
        return participants[_user].won;
    }

    function resetCheck() public onlyOwner returns (bool) {
        if ((block.timestamp - raffleInfo.START_TIME) >= (raffleInfo.RESET_DURATION_HOURS) * j) {
            j++;
            reset();
            return true;
        }
        return false;
    }


    /////////////
    // Raffle //
    ////////////
    function enterRaffle() public payable {
        Participant storage participant = participants[msg.sender];

        require(!participant.hasEntered, "Address has already entered raffle");
        require(raffleInfo.NUM_ENTERED < raffleInfo.TOTAL_PRIZES, "Raffle closed");
        require(
            block.timestamp >= raffleInfo.START_TIME &&
            block.timestamp <= raffleInfo.END_TIME,
            "Raffle closed"
        );

        raffleInfo.NUM_ENTERED++;
        enteredAddresses.push(msg.sender);
        participant.hasEntered = true;
        participant.won = 0; 
        spin(msg.sender, participant);
    }

    function spin(address _user, Participant storage p) internal {
        require(msg.value == raffleInfo.SLOT_PRICE, "Incorrect amount");

        PrizeInfo memory prize = prizes[prizes.length - 1];
        prizes.pop();

        ArzNFT instanceArzNft = ArzNFT(tokenAddress);

        address[] memory sender = new address[](1);
        sender[0] = _user;

        if (prize.COMPETITIVE_WHITELIST) {
            instanceArzNft.addCompetitveUser(sender);
            p.won = 1;
        } else if (prize.GUARANTEED_WHITELIST) {
            instanceArzNft.addGuaranteedUser(sender);
            p.won = 2;
        } else {
            instanceArzNft.airdrop(1, sender);
            p.won = 3;
        }
    }


    function reset() internal {
        for (uint256 i = 0; i < enteredAddresses.length; i++) {
            delete participants[enteredAddresses[i]];
        }

        for (uint256 i = 0; i < enteredAddresses.length; i++) {
            enteredAddresses.pop();
        }
    }
}