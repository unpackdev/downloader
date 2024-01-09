// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";



contract stakeing is Ownable , IERC721Receiver,ReentrancyGuard{

    address  nftAddress = 0x3F916867A9f38aa68aD7583C7360f83387d06dAf;
    address  erc20Address =  0xf4d2888d29D722226FafA5d9B24F9164c092421E;

    uint8 public singlehashrate = 2 ;
    uint8 public doublehashrate = 5 ;
    uint8 public pairhashrate = 10 ;

    mapping(address => uint256[] ) public stakedEyeStarIds30;
    mapping(address => uint256[] ) public stakedEyeStarIds60;

    mapping(address => uint256) public hashrate30;
    mapping(address => uint256) public hashrate60;

    uint256 public totalhashrate30;
    uint256 public totalhashrate60;

    uint256 public amonut30;
    uint256 public amonut60;

    uint256 public stakeStartdate;

    bool public claimLive30; 
    bool public claimLive60; 
    bool public stakeLive; 
    bool public depositLive = true; 


    constructor() {
        stakeStartdate = block.timestamp;
    }

    function toggleClaimLive30() external onlyOwner {
        claimLive30 = !claimLive30;
    }

    function toggleClaimLive60() external onlyOwner {
        claimLive60 = !claimLive60;
    }

    function toggleDepositLivee() external onlyOwner {
        depositLive = !depositLive;
    }

    function setAmount30(uint256 amonut) external onlyOwner {
        amonut30 = amonut;
    }

    function setAmount60(uint256 amonut) external onlyOwner {
        amonut60 = amonut;
    }

    function set20Address(address erc20) external onlyOwner {
        erc20Address = erc20;
    }

    function confirmHashrate(uint256 amount) public onlyOwner {
      amonut30 = ( totalhashrate30 * 100 / ( totalhashrate30 + totalhashrate60 ) ) * amount / 100;
      amonut60 = amount - amonut30;
      stakeLive = !stakeLive; 
      stakeStartdate = block.timestamp;
    }


    function deposit(uint256[] memory single,uint256[2][] memory double,uint256 lockMod) external {
        require(lockMod==1 || lockMod ==2, "lockMod abnormal");
        require(depositLive, "deposit end");

        if(single.length>0) {
             _deposit(single,lockMod);
        }
        if(double.length>0) {
            _depositDouble(double,lockMod);
        }
    }


    function _deposit(uint256[] memory eyeStarIds,uint256 lockMod) private {
        uint256 hashrate;
        for(uint256 i = 0; i < eyeStarIds.length ; i++){
            uint256 eyeStarId = eyeStarIds[i];
            IERC721(nftAddress).safeTransferFrom(msg.sender,address(this),eyeStarId);
            hashrate +=singlehashrate;

            if(lockMod == 1){
                stakedEyeStarIds30[msg.sender].push(eyeStarId);
            }else{
                stakedEyeStarIds60[msg.sender].push(eyeStarId);
            }
        }

        if(lockMod == 1){
            hashrate30[msg.sender] += hashrate;
            totalhashrate30 += hashrate;
        }else{
            hashrate60[msg.sender] += hashrate;
            totalhashrate60 += hashrate;
        }  
    }

    function _depositDouble(uint256[2][] memory eyeStarIds,uint256 lockMod) private {

        for(uint256 i = 0; i < eyeStarIds.length ; i++){
            uint256 leftId = eyeStarIds[i][0];
            uint256 rightId = eyeStarIds[i][1];
            require(leftId!=0 && rightId!=0, "direction error1");
            require(leftId<=3605, "direction error2");
            require(rightId>3605, "direction error3");
        }

        uint256 stakeType;
        uint256 hashrate;
        for(uint256 i = 0; i < eyeStarIds.length ; i++){
            uint256 leftId = eyeStarIds[i][0];
            uint256 rightId = eyeStarIds[i][1];

            IERC721(nftAddress).safeTransferFrom(msg.sender,address(this),leftId);
            IERC721(nftAddress).safeTransferFrom(msg.sender,address(this),rightId);
            if(leftId+rightId == 7212){
                hashrate += pairhashrate;
                stakeType = 3;
            }else{
                hashrate += doublehashrate;
                stakeType = 2;
            }
          
            if(lockMod == 1){
                stakedEyeStarIds30[msg.sender].push(leftId);
                stakedEyeStarIds30[msg.sender].push(rightId);
            }else{
                stakedEyeStarIds60[msg.sender].push(leftId);
                stakedEyeStarIds60[msg.sender].push(rightId);
            }
        }

        if(lockMod == 1){
                hashrate30[msg.sender] += hashrate;
                totalhashrate30 += hashrate;
            }else{
                hashrate60[msg.sender] += hashrate;
                totalhashrate60 += hashrate;
        }  
    }

    function unstake30()  public  nonReentrant() {
        
        for (uint256 i; i < stakedEyeStarIds30[msg.sender].length; i++) {
            uint256 tokenId = stakedEyeStarIds30[msg.sender][i];
            IERC721(nftAddress).safeTransferFrom(address(this), msg.sender,tokenId);
        }   

        delete stakedEyeStarIds30[msg.sender];

         if(!stakeLive){
                totalhashrate30 -= hashrate30[msg.sender];
         }
         hashrate30[msg.sender] = 0;
    }


    function unstake60()  public  nonReentrant() {

        for (uint256 i; i < stakedEyeStarIds60[msg.sender].length; i++) {
            uint256 tokenId = stakedEyeStarIds60[msg.sender][i];
            IERC721(nftAddress).safeTransferFrom(address(this), msg.sender,tokenId);
        }   

        delete stakedEyeStarIds60[msg.sender];

        if(!stakeLive){
            totalhashrate60 -= hashrate60[msg.sender];
        }
        hashrate60[msg.sender] = 0;
    }


    function _claimToken(uint256 lockMod) private {
        uint256 reward ;
        if(lockMod==1 ){
            reward = amonut30 / totalhashrate30  *  hashrate30[msg.sender];
            unstake30();
        }else{
            reward = amonut60 / totalhashrate60  *  hashrate60[msg.sender];
            unstake60();
        }
        IERC20(erc20Address).transfer(msg.sender, reward);
    }

    function expirationDate30 () external view returns (bool){
        return stakeStartdate + 30 days <= block.timestamp || claimLive30;
    }

    function expirationDate60 () external view returns (bool){
        return stakeStartdate + 60 days <= block.timestamp || claimLive60;
    }

    function claimAndWithdraw30() external  {
        require( stakeStartdate + 30 days <= block.timestamp || claimLive30, "claim_closed");
        require(hashrate30[msg.sender] > 0, "not hashrate");
        _claimToken(1);
    }

    function claimAndWithdraw60() external   {
        require( stakeStartdate + 60 days <= block.timestamp || claimLive60, "claim_closed");
        require(hashrate60[msg.sender] > 0, "not hashrate");
        _claimToken(2);

    }

    function numberOfStaked(address user, uint256 lockMod) external view returns (uint256) {

        if(lockMod==1 ){
            return (stakedEyeStarIds30[user].length);
        }else{
            return (stakedEyeStarIds60[user].length);
        }
    }

    function withdrawTokens() external onlyOwner {
        uint256 tokenSupply = IERC20(erc20Address).balanceOf(address(this));
        IERC20(erc20Address).transfer(msg.sender, tokenSupply);
    }

    function onERC721Received(address,address,uint256,bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }



}