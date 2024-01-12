// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";


contract MojorEarlyBirdTicket is ERC721, ERC721URIStorage,Ownable {

    event paramTimeEvent      (uint  parmsTime);
    event addMintParticipantEvent      (address  ads);
    event luckyWinnerBirthEvent    (address  ads,uint tokenId);
    event luckyNumBirthEvent       (uint  noc);
    mapping(address => uint) public participants;
    mapping(uint => address) public participantMaps;
    mapping(address => bool) public minterMaps;
    address[10000] public whiteList;
    bytes32 public lotteryParmOne;
    mapping(uint => uint) public winner;
    uint public no=0;
    uint public winNo=0;
    uint public whiteListNo=0;
    uint public mintStartTime;
    uint public mintEndTime;

    constructor() ERC721("Mojor Early Bird Ticket V1.0", "Mojor Early Bird Ticket V1.0") {
    }

    function safeMint(string memory uri)public  {
        require(block.timestamp >= mintStartTime, "Mint hasn't started yet");
        require(block.timestamp <= mintEndTime,"Mint has ended");
        require(participants[msg.sender]==0,"Can only be mint once");
        require(minterMaps[msg.sender],"You are not eligible for mint");
        require(no<10000,"Maximum limit 10000");
        _safeMint(msg.sender, no);
        _setTokenURI(no, uri);
        participants[msg.sender]=1;
        participantMaps[no]=msg.sender;
        lotteryParmOne=blockhash(block.number -1);
        whiteList[whiteListNo]=msg.sender;
        no++;
        whiteListNo++;
    }

    // The remedy of omission
    function remedyMint(string memory uri,address omission) public  onlyOwner{
        require(participants[msg.sender]==0,"Can only be remedy once");
        require(no<10000,"Maximum limit 10000");
        _safeMint(omission, no);
        _setTokenURI(no, uri);
        participants[omission]=1;
        participantMaps[no]=omission;
        lotteryParmOne=blockhash(block.number -1);
        whiteList[whiteListNo]=omission;
        minterMaps[omission]=true;
        no++;
        whiteListNo++;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)public  view  override(ERC721, ERC721URIStorage) returns (string memory)  {
        return super.tokenURI(tokenId);
    }

    function isMinted(address participant) public view returns(bool){

        if(participants[participant] >0){
            return true;
        }
        return false;
    }


    function isValid(address participant) public view returns(bool){
        return minterMaps[participant];
    }


    function setLotteryTimes(uint startTime,uint endTime) public onlyOwner{
        mintStartTime=startTime;
        mintEndTime=endTime;

    }

    function addMintAccountOne(address ads) public  onlyOwner{
        uint whiteListNumSNow=whiteListNo+1;
        require(whiteListNumSNow<10000,"Maximum limit 10000");
        whiteList[whiteListNo]=ads;
        minterMaps[ads]=true;
        whiteListNo++;
        emit addMintParticipantEvent(ads);

    }

    function addMintAccountBatch(address[]  memory addrs) public  onlyOwner{
        uint whiteListNumSNow=whiteListNo+addrs.length;
        require(whiteListNumSNow<10000,"Maximum limit 10000");
        for(uint i = 0; i < addrs.length; i++){
            whiteList[whiteListNo]=addrs[i];
            minterMaps[addrs[i]]=true;
            whiteListNo++;
            emit addMintParticipantEvent(addrs[i]);
        }
    }


    function mojorLottery() public onlyOwner returns(address){
        address lucky;
        uint  parmsOne=getNumber(lotteryParmOne);
        uint  parmstwo=getNumber(blockhash(block.number - 1));
        uint  parmsTotal=parmsOne*parmstwo*block.timestamp;
        uint  luckyNum=parmsTotal % no;
        emit luckyNumBirthEvent(luckyNum);
        lucky= participantMaps[luckyNum];
        emit luckyWinnerBirthEvent(lucky,luckyNum);
        winner[winNo]=luckyNum;
        winNo++;
        return lucky;
    }

    function mojorLotteryOne(uint num) public onlyOwner returns(uint){
        uint  parmsOne=getNumber(lotteryParmOne);
        uint  parmstwo=getNumber(blockhash(block.number - num));
        uint  parmsTotal=parmsOne*parmstwo * ((block.timestamp)/ num);
        uint  luckyNum=parmsTotal % no;
        return luckyNum;
    }


    function mojorLotterys(uint times) public  onlyOwner {
        uint[1000] memory lucks;
        uint idx=0;
        bool rp=true;
        uint ft= times;
        uint luckyNum;
        address lucky;
        require(times>0,"Must more than one");
        require(times<no,"Must less than account nums");
        for(uint t=0;t<times;t++){
            while(rp){
                rp=false;
                ft++;
                emit paramTimeEvent(ft);
                luckyNum=mojorLotteryOne(ft);
                emit luckyNumBirthEvent(luckyNum);
                lucky= participantMaps[luckyNum];
                //check Diff
                for(uint l=0; l<lucks.length ;l++){
                    if(lucks[l] == luckyNum){
                        rp=true;
                    }
                }
                if(!rp){
                    emit luckyWinnerBirthEvent(lucky,luckyNum);
                    winner[winNo]=luckyNum;
                    winNo++;
                    lucks[idx]=luckyNum;
                    idx++;
                }

            }
            rp=true;
        }
    }

    function _toBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
            add(m, 20),
            xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function isEqual(bytes memory a, bytes memory b) public pure returns (bool) {
        if (a.length != b.length) return false;
        for(uint i = 0; i < a.length; i ++) {
            if(a[i] != b[i]) return false;
        }
        return true;
    }

    function getNumber(bytes32 _hash) private pure returns(uint8) {
        for(uint8 i = _hash.length - 1;i >= 0;i--){
            uint8 b = uint8(_hash[i]) % 16;
            if(b>0 && b<10) return b;
            uint8 c = uint8(_hash[i]) / 16;
            if(c>0 && c<10) return c;
        }
        return 1;
    }


}