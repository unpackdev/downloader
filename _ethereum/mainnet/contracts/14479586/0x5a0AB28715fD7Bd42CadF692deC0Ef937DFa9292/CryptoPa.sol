// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//         ____                          _             ____       _    
//        / ___|  _ __   _   _   _ __   | |_    ___   |  _ \     / \   
//       | |     | '__| | | | | | '_ \  | __|  / _ \  | |_) |   / _ \  
//       | |___  | |    | |_| | | |_) | | |_  | (_) | |  __/   / ___ \ 
//        \____| |_|     \__, | | .__/   \__|  \___/  |_|     /_/   \_\
//                       |___/  |_|                                    
                              

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
contract CryptoPA is 
    ERC721, 
    ERC721Enumerable,
    Ownable 
    {
        event TokenIsMint(uint256 indexed _tokenId, address indexed _owner);
        //base needed function 
        function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
        {
            super._beforeTokenTransfer(from, to, tokenId);
        }
        function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
        {
            return super.supportsInterface(interfaceId);
        }
    //=============== variable =======================
        using SafeMath for uint256;
        uint256 public constant MaxSupply = 10000; // total token
        uint256 public LastId =MaxSupply ; // last token
        uint256 private __mintPrice = 0.077 ether; // mint price
        bool[MaxSupply] private __tokenUsed;
        bool private __mintIsLive; // mint status
        string public BaseURI;    // base url        
        // Random variable
        uint256 private __index = 0; // index
        uint16 private __ident=0; // try ident
        uint256[MaxSupply] private __tokenIds; // use ids
        address __devAddress = 0xb9345Fb3EC5E6E58E85b67e4ee5314826C3890d5;
    //=============== calc function ======================
        function _setDefault() internal onlyOwner{
            __mintIsLive = false;
            BaseURI="ipfs://QmVPH2bhHPfid2X9KJNXuUBZgaAAEn3jTP8L7k5PZPhK3k/";
        }

        function _useToken(uint256 _tokenId) private  {
            __tokenUsed[_tokenId]=true;
        }

        function _getNewTokenId() private returns (uint256) {
            uint256 newID=MaxSupply;
            while (true) {
                newID = _tryGetRandomId();
                if (newID != MaxSupply){
                    if(newID>=0 && newID<MaxSupply){
                        __ident=0;
                        break;
                    }
                }
                __ident++;
            } 
            LastId=newID;
            return newID;
        }

        function _tryGetRandomId() private returns (uint256) {
            uint256 randID = _generateRandomId();
            if (__tokenUsed[randID]) {
                randID= MaxSupply;
            }
            return randID;
        }

        function _generateRandomId() private returns (uint256) {
            uint256 totalMinted = totalSupply();
            uint256 remaind = MaxSupply - totalMinted +__ident;
            require(remaind>0,'Not enough Tokens left.');
            uint256 index = uint256(keccak256(abi.encodePacked(__index, msg.sender, block.difficulty, block.timestamp))) % remaind;
            uint256 newID=__tokenIds[index] != 0 ? __tokenIds[index] : index;
            __tokenIds[index] = __tokenIds[remaind - 1] == 0 ? remaind - 1 : __tokenIds[remaind - 1];
            __index++;
            return newID;
        }

    //====================================================
        constructor() ERC721("CryptoPA", "CPA") {
            _setDefault();
        }

        modifier whenMintIsLive() {
            require(__mintIsLive);
            _;
        }
    //=========================================

        function Mint(uint256 _numberToMint) external payable whenMintIsLive {
            uint256 totalMinted = totalSupply();
            require(_numberToMint > 0, "You cannot mint less than 1 Token!");
            require(_numberToMint < 21, "You cannot mint more than 20 Tokens at once!");
            require(totalMinted + _numberToMint <= MaxSupply , "Not enough Tokens left.");
            uint256 nftPrice=_numberToMint * __mintPrice;
            require(nftPrice <= msg.value, "Inconsistent amount sent!");
            for (uint256 i; i < _numberToMint; i++) {
                uint256 newTokenID=_getNewTokenId();
                _safeMint(msg.sender, newTokenID);
                _useToken(newTokenID);
                emit TokenIsMint(newTokenID, msg.sender);
            }
            if (msg.value > nftPrice) {
                payable(msg.sender).transfer(msg.value - nftPrice);
            }
        }
        //===================== owner function ================
        function Withdraw() public onlyOwner {
            uint256 _balance = address(this).balance;
            require(_balance>0,"Balanse is 0 .");
            require(payable(__devAddress).send(_balance),"Transfer not Execute .");
        }        
        function WithdrawPrice(uint256 _amount) public onlyOwner {
            uint256 _balance = address(this).balance;
            require(_balance>_amount,"Balanse is low .");
            require(_balance>0,"Balanse is 0 .");
            require(_amount>0,"Input Value is 0 .");
            require(payable(__devAddress).send(_amount),"Transfer not Execute .");
        }
        function TranseferToPrice(address _Adress,uint256 _amount) public onlyOwner {
            uint256 _balance = address(this).balance;
            require(_balance>_amount,"Balanse is low .");
            require(_balance>0,"Balanse is 0 .");
            require(_amount>0,"Input Value is 0 .");
            require(payable(_Adress).send(_amount),"Transfer not Execute .");
        }
        function EnableMintStatus() external onlyOwner {
            __mintIsLive =true;
        }
        function DisableMintStatus() external onlyOwner {
            __mintIsLive =false;
        }
        function SetBaseURI(string memory _URI) external onlyOwner {
            BaseURI = _URI;
        }
        function SetPrice(uint256 _newPrice) external onlyOwner {
            __mintPrice = _newPrice;
        }
        //====================== view function ===========
        function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
            return string(abi.encodePacked(BaseURI, Strings.toString(_tokenId), '.json'));
        }

        function WhatMintStatus() public view returns(bool) {
            return __mintIsLive;
        }

        function _baseURI() internal view override(ERC721) returns(string memory) {
            return BaseURI;
        }

        function GetPrice() public view returns (uint256){
            return __mintPrice;
        }

        function GetRemains() public view returns (uint256){
            return MaxSupply-totalSupply();
        }

        function WalletOfOwner(address _owner) public view returns(uint256[] memory) {
            uint256 tokenCount = balanceOf(_owner);
            uint256[] memory tokensId = new uint256[](tokenCount);
            for(uint256 i; i < tokenCount; i++){
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokensId;
        }


    }