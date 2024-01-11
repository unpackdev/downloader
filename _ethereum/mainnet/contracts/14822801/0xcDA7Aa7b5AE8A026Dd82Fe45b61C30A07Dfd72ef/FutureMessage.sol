// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./ERC721URIStorage.sol";

// import "./ERC721Enumerable.sol";
import "./Strings.sol";

// import "./console.sol";
import "./ERC721Enumerable.sol";

// This is the main building block for smart contracts.
contract FutureMessage is ERC721Enumerable , Ownable  {

    /*
        定义每一个消息的类型，包含了存储的人，content内容，amount附言金额，end_time到期时间
    */
    struct FutureMsg {
        // address account;
        string content;
        uint256 amount;
        uint32 depositTime;
        uint32 endTime;
        uint256 tokenId;
        bool isWithdrawed;
        address tokenAddress;
    }

    //定义了每个token对应的msg信息
    mapping(uint => FutureMsg) public fmsgs;

    //消息被存储的event
    event MessageSet(address account, string content , uint amount , uint end_time);

    uint mintPrice;

    string _currentBaseURI = "https://worker.future-piggy-bank.workers.dev/metadata/";

    /**
     * 合约构造函数
     */
    constructor() ERC721("Future Message", "FM"){
        mintPrice   = 0.03 ether;
    }

    function safeMintFM(
        address minter,
        uint32 endTime,
        string memory content,
        address token_address,
        uint amount 
        ) internal returns (uint256) {

        // 获得TokenID
        uint256 supply = totalSupply();
        uint256 tokenId = supply + 1;

        //手续费转账给owner
        payable(owner()).transfer(mintPrice);

        _mint(minter, tokenId);

        //把额外字段写入合约
        FutureMsg storage fmsg = fmsgs[tokenId];
        fmsg.content = content;
        fmsg.endTime = endTime;
        fmsg.amount = amount;
        fmsg.isWithdrawed = false;
        fmsg.tokenId = tokenId;
        fmsg.depositTime = uint32(block.timestamp);
        fmsg.tokenAddress = token_address;

        return tokenId;

    }

    function mintFM(
        address minter,
        uint32 endTime,
        string memory content
        ) external payable returns (uint256){
        
        // require(!_exists(tokenId), "ERC721: token already minted");
        require(minter != address(0), "ERC721: mint to the zero address");
        require(msg.value >= mintPrice, "FM: Insufficient value");
        require(block.timestamp >= (endTime - 315360000 + 3600), "FM: timestamp must less then 10 year");

        // require(block.timestamp <= (endTime - 31536000 + 3600), "FM: timestamp must large then 1 year"); 
        uint256 saveAmount = msg.value - mintPrice;

        //手续费转账给owner
        uint256 tokenId = safeMintFM(minter,endTime,content,address(0),saveAmount);
        return tokenId;
    }

    function mintTokenFM(
        address minter,
        uint32 endTime,
        string memory content,
        address token_address,
        uint amount
        ) external payable returns (uint256){
        
        require(minter != address(0), "ERC721: mint to the zero address");
        require(msg.value >= mintPrice, "FM: Insufficient value");
        require(block.timestamp >= (endTime - 315360000 + 3600), "FM: timestamp must less then 10 year");
        
        // require(block.timestamp <= (endTime - 31536000 + 3600), "FM: timestamp must large then 1 year"); 

        IERC20(token_address).transferFrom(minter, address(this), amount);

        uint256 tokenId = safeMintFM(minter,endTime,content,token_address,amount);
        

        return tokenId;
    }
    function withdrawal(address payable addr,uint256 tokenId) external returns (bool){
        //判断是不是owner
        require(ERC721.ownerOf(tokenId) == addr, "ERC721: transfer from incorrect owner");

        //判断token是否到期
        FutureMsg storage fmsg = fmsgs[tokenId];
        require(fmsg.endTime <= block.timestamp,"FM: the withdrawal time must be greater than the allowable withdrawal time");
       
        //判断是否取款了
        require(fmsg.isWithdrawed == false, "FM: this token is been withdrawed yet");

        //设置状态为已经取款
        fmsg.isWithdrawed = true;

        //取款
        if (fmsg.tokenAddress == address(0)) {
            addr.transfer(fmsg.amount);
        }else {
            IERC20(fmsg.tokenAddress).transfer(addr, fmsg.amount);
        }

        //完成
        return true;
    }

    /**
     * 读取某token的内部信息
     */
    function readMsg(uint256 tokenId) external view returns (FutureMsg memory) {
        require(_exists(tokenId), "ERC721: token is not exist");
        return fmsgs[tokenId];
    }


    /**
     * 获得一个用户的Token列表
     */
    function getTokenListByAddress(address owner,uint256 offset, uint256 limit) external view returns (FutureMsg[] memory result) {

        require(limit <= 20, "FM: limit cannot over 20");
        FutureMsg[] memory tempArr = new FutureMsg[](limit);

        uint i = 0;
        for (i = 0; i<limit; i++) {
            uint index = offset + i;
            uint tokenId = _ownedTokens[owner][index];
            FutureMsg memory fmsg = fmsgs[tokenId];

            if (fmsg.endTime == 0) {
                break;
            }
            tempArr[i] = fmsg;
        }

        if (i == limit) {
            result = tempArr;
        } else {
            result = new FutureMsg[](i);
            uint j = 0;
            for (j = 0; j<i; j++) {
                result[j] = tempArr[j];
            }
        }
        return result;
    }

    function calcBeginAndEndIndex(uint256 total,uint256 offset, uint256 limit) private pure returns (uint256[2] memory) {
        
        uint256 start_index;
        uint256 end_index = total - 1 - offset;
        if (total - 1 - offset < limit) {
            start_index = 0;
        }else {
            start_index = total - offset - limit;
        }
        return [start_index,end_index];

    }

    /**
     *  获得全部的列表
     *  注意：这个方法是倒叙的排列所有的token
     */
    function getTokenList(uint256 offset, uint256 limit) external view returns (FutureMsg[] memory) {
        // require(_exists(tokenId), "ERC721: token is not exist");
        require(limit <= 20, "FM: limit cannot over 20");
        // require(_allTokens.length > offset, "FM: offset must less then alltoken length");

        if (_allTokens.length <= offset) {
            FutureMsg[] memory result = new FutureMsg[](0);
            return result;
        }

        uint256 total_supply = _allTokens.length;
        uint256[2] memory data = calcBeginAndEndIndex(total_supply,offset,limit);
        

        // //获得实际的这个列表长度
        uint256 limit_real = data[1] - data[0] + 1;


        FutureMsg[] memory tempArr = new FutureMsg[](limit_real);

        uint256 i;
        for (i = 0; i<limit_real; i++) {
            uint index = data[1] - i;
            uint tokenId = _allTokens[index];
            
            FutureMsg memory fmsg = fmsgs[tokenId];
            if (fmsg.endTime == 0) {
                break;
            }
            tempArr[i] = fmsg;
        }
        
        return tempArr;
    }


    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory uri) onlyOwner public {
        _currentBaseURI = uri;
    }

}

