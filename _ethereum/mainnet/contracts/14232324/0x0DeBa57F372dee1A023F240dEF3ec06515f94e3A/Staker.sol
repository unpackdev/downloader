// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./FXY.sol";

contract Staker is Ownable, IERC721Receiver {
    mapping (uint => address) public ownership;
    mapping(uint => uint) public stakeTime;
    mapping(address => uint) public lastWithdraw;
    mapping (address => uint[]) private _qty;
    bool public paused = false;
    uint nullToken = 1 ether;
    uint tokensHour = 1;
    IERC721 public NFT;
    FXY public TOKEN;

    modifier notPaused(){
        require(!paused, "PAUSED");
        _;
    }

    constructor() {

    }

    function setTokenshour(uint new_) external onlyOwner {
        tokensHour = new_;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function setNFTAddress(address new_) external onlyOwner {
        NFT = IERC721(new_);
    }

    function setCOINAddress(address new_) external onlyOwner {
        TOKEN = FXY(new_);
    }

    function getAssetsByHolder(address holder) public view returns (uint[] memory){
        return _qty[holder];
    }

    function getProfits(uint tokenId) public view returns(uint) {
        if(stakeTime[tokenId] == 0 || tokenId == nullToken){
            return 0;
        }
        uint lWithdraw = stakeTime[tokenId] > lastWithdraw[_msgSender()] ? stakeTime[tokenId] : lastWithdraw[_msgSender()];
        uint sTime = (block.timestamp - lWithdraw) / 1 hours;
        return sTime * tokensHour;
    }

    function getAllProfits() public view returns(uint) {
        uint[] memory tokenIds = getAssetsByHolder(_msgSender());
        uint profits = 0 ;
        for(uint i=0; i< tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            if(ownership[tokenId] == _msgSender()){
                profits += getProfits(tokenId);
            }
        }
        return profits;
    }

    function stake(uint[] calldata tokenIds) public notPaused {
        for(uint i=0; i < tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            if(NFT.ownerOf(tokenId) == _msgSender()){
                stakeTime[tokenId] = block.timestamp;
                ownership[tokenId] = _msgSender();
                NFT.transferFrom(_msgSender(), address(this), tokenId);
                _qty[_msgSender()].push(tokenId);
            }
        }
    }

    function unstake(uint[] calldata tokenIds) public {
        for(uint i=0; i< tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            recover(tokenId);
            removeToken(tokenId);
        }
    }

    function unstakeAll(bool wd) public {
        uint[] memory tokenIds = getAssetsByHolder(_msgSender());
        if(wd){
            claim();
        }
        for(uint i=0; i< tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            recover(tokenId);
        }
        delete _qty[_msgSender()];
    }

    function recover(uint tokenId) internal {
        require(ownership[tokenId] == _msgSender(), "ownership failed");
        ownership[tokenId] = address(0);
        NFT.transferFrom(address(this), _msgSender(), tokenId);
    }

    function removeToken(uint tokenId) internal {
        for(uint i=0;i<_qty[_msgSender()].length;i++){
            if(_qty[_msgSender()][i] == tokenId){
                _qty[_msgSender()][i] = nullToken;
                break;
            }
        }
    }

    function claim() public notPaused {
        uint[] memory tokenIds = getAssetsByHolder(_msgSender());
        uint profits = 0 ;
        for(uint i=0; i< tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            if(ownership[tokenId] == _msgSender()){
                profits += getProfits(tokenId);
            }
        }
        require(profits > 0, "WITHDRAW ZERO TOKENS");
        lastWithdraw[_msgSender()] = block.timestamp;
        TOKEN.mintTo(_msgSender(), profits);
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(address(NFT) == operator, "not allowed");
        return this.onERC721Received.selector;
    }

}