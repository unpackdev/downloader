// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC721JsonMetadata.sol";


contract WIFnft is ERC721JsonMetadata, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string internal constant NAME    = 'WhatIsFaster NFT';
    string internal constant SYMBOL  = 'WIFn';

    event Sale(address indexed buyer, bytes32 indexed tokenTypeHash, uint256 nftAmount, uint256 ethAmount);

    struct SaleInfo {
        uint256 start;      // Sale start timestamp
        uint256 end;        // Sale end timestamp
        uint256 price;      // Price of NFT in ETH wei (so if price is 0.02 ETH, then it should be 20000000000000000 wei)
        uint256 cap;        // Max count of NFT's of this type
        uint256 minted;     // How many tokens of this type is already minted. Should always be <= cap
    }

    uint256 internal nextId;
    mapping(uint256=>bytes32) public tokenType;     //Maps token id to a token type hash
    mapping(bytes32=>SaleInfo) public saleProperties;
    uint256 public limitPerAddress;

    constructor() ERC721(NAME, SYMBOL) {
        nextId = 1;
    }



    function sale(bytes32 ttype, uint256 nftAmount) external payable nonReentrant {
        require(limitPerAddress == 0 || nftAmount <= limitPerAddress, "nftAmount too high");

        SaleInfo storage saleInfo = saleProperties[ttype];

        require(
            (saleInfo.start <= block.timestamp) &&      // Sale has to be started
            (saleInfo.end >= block.timestamp),          // Sale has to be not ended
            "Sale not running"
        );

        uint256 available = saleInfo.cap.sub(saleInfo.minted);
        if(available < nftAmount) nftAmount = available;
        require(nftAmount > 0, "nothing to sale");
        uint256 ethAmount = nftAmount.mul(saleInfo.price);
        require(msg.value >= ethAmount, "!enough ETH");

        saleInfo.minted = saleInfo.minted.add(nftAmount);
        if(ethAmount < msg.value){
            uint256 refund = msg.value - ethAmount;
            _msgSender().transfer(refund);
        }
        uint256 newNextId = nextId.add(nftAmount);
        for(uint256 id=nextId; id<newNextId; id++){
            tokenType[id] = ttype;
            _safeMint(_msgSender(), id);
        }
        nextId = newNextId;
        emit Sale(_msgSender(), ttype, nftAmount, ethAmount);
    }

    function setupSale(
        bytes32[] calldata ttypes, 
        uint256[] calldata starts, 
        uint256[] calldata ends, 
        uint256[] calldata prices, 
        uint256[] calldata caps
    ) external onlyOwner {
        require(
            (ttypes.length == starts.length) && 
            (ttypes.length == caps.length) && 
            (ttypes.length == caps.length) && 
            (ttypes.length == caps.length) && 
            (caps.length == ttypes.length), 
            "Wrong array lengths"
        );
        for(uint256 i=0; i < ttypes.length; i++){
            bytes32 ttype = ttypes[i];
            SaleInfo storage si = saleProperties[ttype];
            require(caps[i] >= si.minted, "Can not set cap less than minted");
            require(starts[i] < ends[i], "Can't start before end");
            si.start = starts[i];
            si.end = ends[i];
            si.price = prices[i];
            si.cap = caps[i];
        }
    }

    function setupSale(bytes32 ttype, uint256 start, uint256 end, uint256 price, uint256 cap) external onlyOwner {
        SaleInfo storage si = saleProperties[ttype];
        require(cap >= si.minted, "Can not set cap less than minted");
        require(start < end, "Can't start before end");
        si.start = start;
        si.end = end;
        si.price = price;
        si.cap = cap;
    }

    function setLimitPerAddress(uint256 _limitPerAddress)  external onlyOwner {
        limitPerAddress = _limitPerAddress;
    }

    function saleState(bytes32[] calldata ttypes) external view returns(
        uint256[] memory starts, uint256[] memory ends, uint256[] memory price, uint256[] memory minted, uint256[] memory available
    ) {
        starts = new uint256[](ttypes.length);
        ends = new uint256[](ttypes.length);
        price = new uint256[](ttypes.length);
        minted = new uint256[](ttypes.length);
        available = new uint256[](ttypes.length);
        for(uint256 i=0; i < ttypes.length; i++){
            bytes32 ttype = ttypes[i];
            SaleInfo storage saleInfo = saleProperties[ttype];
            starts[i] = saleInfo.start;
            ends[i] = saleInfo.end;
            price[i] = saleInfo.price;
            minted[i] = saleInfo.minted;
            available[i] = (saleInfo.minted < saleInfo.cap)?saleInfo.cap.sub(saleInfo.minted):0;
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_msgSender(), balance);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        if(limitPerAddress > 0) {
            uint256 toBalance = balanceOf(to);
            require(toBalance < limitPerAddress, "limit reached");
        }
    }
}