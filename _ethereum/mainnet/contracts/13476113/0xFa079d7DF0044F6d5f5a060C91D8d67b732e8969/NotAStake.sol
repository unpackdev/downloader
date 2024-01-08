// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract NotAStake is IERC721Receiver, Ownable {
    
    struct Operator {
        bool active;
        uint tokensHour;
        address tokenAddress;
    }
    
    struct Item {
        address owner;
        uint stakeTime;
        uint lastWithdraw;
    }

    bool public paused = false;
    mapping (address => mapping(uint => Item)) public owners;
    mapping (address => Operator) public operators;
    mapping (address => mapping(address => uint[])) private _qty;

    modifier notPaused(){
        require(!paused, "PAUSED");
        _;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }
    
    function getAssetsByHolder(address operator, address holder) public view returns (uint[] memory){
        return _qty[operator][holder];
    }
    
    function setOperator(address operator, bool active, uint tokensHour, address tokenAddress) public onlyOwner {
        operators[operator] = Operator(active, tokensHour, tokenAddress);
    }
    
    function stake(address operator, uint[] calldata tokenIds) public notPaused {
        require(operators[operator].active,"collection not allowed");
        IERC721 NFT = IERC721(operator);
        for(uint i=0; i < tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            require(NFT.ownerOf(tokenId) == _msgSender());
            NFT.transferFrom(_msgSender(), address(this), tokenId);
            owners[operator][tokenId] = Item(_msgSender(),block.timestamp,0);
            _qty[operator][_msgSender()].push(tokenId);
        }
    }
    
    function unstake(address operator, uint[] calldata tokenIds) public {
        IERC721 NFT = IERC721(operator);
         for(uint i=0; i< tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            require(owners[operator][tokenId].owner == _msgSender(), "NOT OWNER");
            NFT.transferFrom(address(this), _msgSender(), tokenId);
            owners[operator][tokenId] = Item(address(0),0,0);
            for(uint j=0;j<_qty[operator][_msgSender()].length;j++){
                if(_qty[operator][_msgSender()][j] == tokenId){
                    _qty[operator][_msgSender()][j] = 9999999999;
                    break;
                }
            }
        }
    }
    
    function recover(address operator, uint tokenId) public onlyOwner {
        require(owners[operator][tokenId].owner == address(0), "NOT ZERO ADDRESS");
        IERC721 NFT = IERC721(operator);
        NFT.transferFrom(address(this), _msgSender(), tokenId);
    }
    
    function getProfits(address operator, uint tokenId) public view returns(uint) {
        Item memory item = owners[operator][tokenId];
        Operator memory op = operators[operator];
        if(!op.active || item.stakeTime == 0){
            return 0;
        }
        uint lastWithdraw = item.stakeTime > item.lastWithdraw ? item.stakeTime : item.lastWithdraw;
        uint stakeTime = (block.timestamp - lastWithdraw) / 1 hours;
        return stakeTime * op.tokensHour;
    }
    
    function withdraw(address operator, uint tokenId) public notPaused {
         require(owners[operator][tokenId].owner == _msgSender(), "NOT OWNER");
         Item storage item = owners[operator][tokenId];
         Operator memory op = operators[operator];
         uint profits = getProfits(operator, tokenId);
         require(profits > 0, "WITHDRAW ZERO TOKENS");
         require(op.tokenAddress != address(0), "NO ERC20 SETUP");
         require(op.active, "PAUSED");
         IERC20 COIN = IERC20(operators[operator].tokenAddress);
         item.lastWithdraw = block.timestamp;
         COIN.transferFrom(COIN.owner(), _msgSender(), profits);
    }
    
    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(operators[operator].active,"collection not allowed");
        return this.onERC721Received.selector;
    }
}

