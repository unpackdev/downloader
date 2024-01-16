// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract MojorEarlyBirdTicket is Ownable, ERC721A, ReentrancyGuard {

    uint public maxBatchSize_ = 5000;
    uint public collectionSize_ = 5000;

    event paramTimeEvent      (uint parmsTime);
    event paramAddressSurplusNumsEvent      (address ads, uint alSurplusNums, uint wlSurplusNums);
    event addMintParticipantEvent      (address ads);
    event luckyWinnerBirthEvent    (address ads, uint tokenId);
    event luckyNumBirthEvent       (uint noc);

    mapping(address => uint) public participantsWaitingList;
    mapping(address => uint) public participantsWaitingListMinted;
    mapping(address => uint) public participantsAllowList;
    mapping(address => uint) public participantsAllowListMinited;
    mapping(uint => address) public participantMaps;
    address[10000] public mintList;
    uint public mintListNo = 0;
    uint public mintStartTime;
    uint public mintEndTime;

    // // metadata URI
    string private _baseTokenURI;

    constructor() ERC721A("Mojor Early Bird Ticket", "MOJOR EARLY BIRD TICKET", maxBatchSize_, collectionSize_) {
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function safeMint() public {
        require(totalSupply() < 10000, "Maximum limit 10000");

        if (mintStartTime == 0 || block.timestamp < mintStartTime) {
            revert("Not Time To Mint");
        }

        //ONLY MINT BY ALLOW LIST TIME
        uint alSurplus = participantsAllowList[msg.sender] - participantsAllowListMinited[msg.sender];
        uint wlSurplus = participantsWaitingList[msg.sender] - participantsWaitingListMinted[msg.sender];

        if (block.timestamp >= mintStartTime && block.timestamp <= mintEndTime) {
            if (alSurplus <= 0) {
                revert("Can Not Mint More");
            }

            participantsAllowListMinited[msg.sender] = participantsAllowListMinited[msg.sender] + alSurplus;
            _safeMint(msg.sender, alSurplus);
            mintList[mintListNo] = msg.sender;
            mintListNo++;
            emit  paramAddressSurplusNumsEvent(msg.sender, alSurplus - alSurplus, wlSurplus);
        }

        bool isMinted = false;
        if (block.timestamp > mintEndTime) {
            //ALL MINT TIME
            uint totalMinted = wlSurplus + alSurplus;
            require(totalMinted > 0, "Can not mint more");
            //ALSURPLUS ENOUGH
            if (alSurplus > 0) {
                participantsAllowListMinited[msg.sender] = participantsAllowListMinited[msg.sender] + alSurplus;
                emit paramAddressSurplusNumsEvent(msg.sender, alSurplus - alSurplus, wlSurplus);
                _safeMint(msg.sender, alSurplus);
                isMinted = true;
            }

            //SURPLUS WAITING LIST
            if (wlSurplus > 0) {
                participantsWaitingListMinted[msg.sender] = participantsWaitingListMinted[msg.sender] + wlSurplus;
                emit paramAddressSurplusNumsEvent(msg.sender, alSurplus, wlSurplus - wlSurplus);
                _safeMint(msg.sender, wlSurplus);
                isMinted = true;

            }
            if (isMinted) {
                mintList[mintListNo] = msg.sender;
                mintListNo++;
            }
        }
    }

    function projectCreation(uint count) public onlyOwner {
        require(totalSupply() + count < 10000, "Maximum limit 10000");
        _safeMint(msg.sender, count);
        mintList[mintListNo] = msg.sender;
        mintListNo++;

    }


    function isMintedTotal(address participant) public view returns (uint){
        uint wlMinted = participantsWaitingListMinted[participant];
        uint alMinted = participantsAllowListMinited[participant];
        uint totalMinted = wlMinted + alMinted;
        if (totalMinted > 0) {
            return totalMinted;
        }
        return 0;
    }

    function isMintedByWL(address participant) public view returns (uint){
        uint wlMinted = participantsWaitingListMinted[participant];
        if (wlMinted > 0) {
            return wlMinted;
        }
        return 0;
    }

    function isMintedByAL(address participant) public view returns (uint){
        uint alMinted = participantsAllowListMinited[participant];
        if (alMinted > 0) {
            return alMinted;
        }
        return 0;
    }


    function isValid(address participant) public view returns (uint){
        uint alSurplus = participantsAllowList[participant] - participantsAllowListMinited[participant];
        //ONLY MINT BY ALLOW LIST TIME
        if (block.timestamp >= mintStartTime && block.timestamp <= mintEndTime) {
            if (alSurplus > 0) {
                return alSurplus;
            }
            return 0;
        }
        //ALL MINT TIME
        uint wlSurplus = participantsWaitingList[participant] - participantsWaitingListMinted[participant];
        uint totalMinted = wlSurplus + alSurplus;
        if (totalMinted > 0) {
            return totalMinted;
        }
        return 0;
    }

    function setMintTimes(uint startTime, uint endTime) public onlyOwner {
        mintStartTime = startTime;
        mintEndTime = endTime;
    }

    function setParticipantWaitingList(address[] memory ads, uint[] memory nums) onlyOwner public {
        for (uint a = 0; a < ads.length; a++) {
            participantsWaitingList[ads[a]] = participantsWaitingList[ads[a]]+nums[a];
        }
    }

    function setParticipantAllowList(address[] memory ads, uint[] memory nums) onlyOwner public {
        for (uint a = 0; a < ads.length; a++) {
            participantsAllowList[ads[a]] = participantsAllowList[ads[a]]+nums[a];
        }
    }


}