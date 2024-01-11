// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Ownable.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";
import "./ZenCats.sol";


contract ZenCatsMarket is Ownable,IERC721Receiver {
    using Strings for string;
    address public nftAddress;

    struct tokenData{
        uint tokenId;
        uint price;
        bool is_for_sale;
        bool sold;
    }

    mapping(uint => bool) public hasToken;
    uint[] public tokens;
    mapping(uint => tokenData) public tokenDatas;

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
    }

    function fundTransfer(address payable etherreceiver, uint256 amount) external onlyOwner {
        require(etherreceiver != address(0) , "Can not Send To Zero");
        etherreceiver.transfer(amount)   ;
    }
    function transferNFTS(address _toAddress) external onlyOwner
    {
        ZenCats zencatContract = ZenCats(nftAddress);
        uint balance  = zencatContract.balanceOf(address(this));  

        uint[] memory myTokens = new uint[](balance);
        for (uint256 index = 0; index < balance; index++) {
            myTokens[index] = zencatContract.tokenOfOwnerByIndex(address(this), index);
        }

        for (uint256 index = 0; index < balance; index++) {
            zencatContract.safeTransferFrom(address(this), _toAddress, myTokens[index]);
        }
    }
    
    function reloadInventory() public onlyOwner {
        ZenCats zencatContract = ZenCats(nftAddress);
        uint balance  = zencatContract.balanceOf(address(this));        
        for (uint256 index = 0; index < balance; index++) {
            uint token = zencatContract.tokenOfOwnerByIndex(address(this), index);
            if (!hasToken[token])
            {
                hasToken[token] = true;
                tokens.push(token);
                tokenDatas[token] = tokenData(token,0,false,false);
            }
        }
    }

    function editInventory(tokenData[] memory array) public onlyOwner{
        for (uint256 index = 0; index < array.length; index++) {
            uint token = array[index].tokenId;
            if (hasToken[token])
            {
                tokenDatas[token] = array[index];
            }
        }

    }
    function buy(address _toAddress,uint tokenId) payable public{

        require(hasToken[tokenId],"Contract can not sell this token");
        require(tokenDatas[tokenId].is_for_sale,"Token is not for sale");
        require(!tokenDatas[tokenId].sold,"Token is sold");
        require(tokenDatas[tokenId].price  <= msg.value, "wrong price");
        ZenCats zencatContract = ZenCats(nftAddress);
        zencatContract.safeTransferFrom(address(this), _toAddress, tokenId);
        tokenDatas[tokenId].sold = true;

    }
    function allocateNFTs(uint count,uint level) external onlyOwner {

        require(count > 0,"Invalid count");

        ZenCats zencatContract = ZenCats(nftAddress);
        for (uint256 index = 0; index < count; index++) {
            zencatContract.mintTo(address(this),level);
        }
        reloadInventory();
    }

    function getTokens() view public returns(uint[] memory)
    {
        return tokens;
    }
    function getAllTokenData() view public returns(tokenData[] memory)
    {
        tokenData[] memory _nfts = new tokenData[](tokens.length);
        
        for (uint256 index = 0; index < tokens.length; index++) {
            _nfts[index] = tokenDatas[tokens[index]]; 
        }
        return _nfts;
    }

    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public override returns (bytes4) {
            return this.onERC721Received.selector;
    }

}