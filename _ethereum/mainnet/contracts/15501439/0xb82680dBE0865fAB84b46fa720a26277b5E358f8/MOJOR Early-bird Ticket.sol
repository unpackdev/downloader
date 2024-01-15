// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";


contract MojorEarlyBirdTicket is ERC721, ERC721URIStorage, Ownable {

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
    uint public no = 0;
    uint public mintListNo = 0;
    uint public mintStartTime;
    uint public mintEndTime;

    constructor() ERC721("Mojor Early Bird Ticket", "Mojor Early Bird Ticket") {
    }

    function safeMint(string memory uri) public {

        require(no < 10000, "Maximum limit 10000");

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

            participantsAllowListMinited[msg.sender] = participantsAllowListMinited[msg.sender] + 1;
            _safeMint(msg.sender, no);
            _setTokenURI(no, uri);
            mintList[mintListNo] = msg.sender;
            no++;
            mintListNo++;
            emit  paramAddressSurplusNumsEvent(msg.sender, alSurplus - 1, wlSurplus);
        }

        if (block.timestamp > mintEndTime) {
            //ALL MINT TIME
            uint totalMinted = wlSurplus + alSurplus;
            require(totalMinted > 0, "Can not mint more");
            //ALSURPLUS ENOUGH
            if (alSurplus > 0) {
                participantsAllowListMinited[msg.sender] = participantsAllowListMinited[msg.sender] + 1;
                emit paramAddressSurplusNumsEvent(msg.sender, alSurplus - 1, wlSurplus);

            }
            //SURPLUS WAITING LIST 
            if (alSurplus <= 0 && wlSurplus > 0) {
                participantsWaitingListMinted[msg.sender] = participantsWaitingListMinted[msg.sender] + 1;
                emit paramAddressSurplusNumsEvent(msg.sender, alSurplus, wlSurplus - 1);
            }
            _safeMint(msg.sender, no);
            _setTokenURI(no, uri);
            mintList[mintListNo] = msg.sender;
            no++;
            mintListNo++;
        }
    }

    function projectCreation(string memory uri) public onlyOwner {
        require(no < 10000, "Maximum limit 10000");
        _safeMint(msg.sender, no);
        _setTokenURI(no, uri);
        mintList[mintListNo] = msg.sender;
        no++;
        mintListNo++;
    }
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)  {
        return super.tokenURI(tokenId);
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

    function setParticipantWaitingList(address[] memory ads) onlyOwner public {
        uint whiteListNumSNow = mintListNo + ads.length;
        require(whiteListNumSNow < 10000, "Mint Maximum limit 10000");

        for (uint a = 0; a < ads.length; a++) {
            participantsWaitingList[ads[a]] = participantsWaitingList[ads[a]] + 1;
        }
    }

    function setParticipantAllowList(address[] memory ads) onlyOwner public {
        uint whiteListNumSNow = mintListNo + ads.length;
        require(whiteListNumSNow < 10000, "Mint Maximum limit 10000");

        for (uint a = 0; a < ads.length; a++) {
            participantsAllowList[ads[a]] = participantsAllowList[ads[a]] + 1;
        }
    }


}