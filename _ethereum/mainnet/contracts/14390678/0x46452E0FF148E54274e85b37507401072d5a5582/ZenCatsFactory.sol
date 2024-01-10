// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Ownable.sol";
import "./Strings.sol";
import "./ZenCats.sol";
import "./WhiteList.sol";


contract ZenCatsFactory is Ownable,WhiteList {
    using Strings for string;

    address public nftAddress;

    uint256 public ZENCATS_SUPPLY;
    uint public constant MAX_LEVEL = 3;

    
    bool public publicMintActive = false;
    bool public privateMintActive = false;
    
    mapping(uint => uint) public level_supply;
    mapping(uint => bool) public allowed_mint_size;
    mapping(uint => uint) public public_mint_price;
    mapping(uint => uint) public private_mint_price;

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        level_supply[0] = 3996;
        level_supply[1] = 1430;
        level_supply[2] = 286;
        ZENCATS_SUPPLY =  5712;

        allowed_mint_size[1] = true;
        allowed_mint_size[2] = true;
        allowed_mint_size[4] = true;
        allowed_mint_size[7] = true;

        private_mint_price[1] =  0.08 ether;
        private_mint_price[2] =  0.16 ether;
        private_mint_price[4] =  0.3 ether;
        private_mint_price[7] =  0.54 ether;

        public_mint_price[1] =  0.1 ether;
        public_mint_price[2] =  0.20 ether;
        public_mint_price[4] =  0.37 ether;
        public_mint_price[7] =  0.67 ether;
    }
    function setPrivateMintActive(bool value) external onlyOwner {
        privateMintActive = value;
    }

    function setPublicMintActive(bool value) external onlyOwner {
        publicMintActive = value;
    }
    function fundtransfer(address payable etherreceiver, uint256 amount) external onlyOwner {
        require(etherreceiver != address(0) , "Can not Send To Zero");
        etherreceiver.transfer(amount)   ;
    }
    function random(uint seed) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,seed,msg.sender, block.timestamp)));
    } 

    function randomMint(address _toAddress) private {
        ZenCats zencatContract = ZenCats(nftAddress);
        uint level = random(block.timestamp) % 3;
        for(uint i = 0 ; i< MAX_LEVEL ; i++)
        {
            uint temp = (level+i) % MAX_LEVEL;
            if (level_supply[temp] > 0)
            {
                level = temp;
                break;
            }
        }
        require(level_supply[level] > 0,"No Supply for this level");
        zencatContract.mintTo(_toAddress,level);
        level_supply[level]--;
        ZENCATS_SUPPLY--;
    }

    function _mint(uint256 mint_size, address _toAddress) internal {
            for (uint256 i = 0;i < mint_size; i++) {
                randomMint(_toAddress);
            }

    }
    function mint(uint mint_size, address _toAddress)  external payable {
        // Must be sent from the owner proxy or owner.
        require(publicMintActive,"PUBLIC MINT IS NOT ACTIVE");
        require(mint_size > 0,"Invalid Mint Size");
        require(canMint(mint_size));
        initQouta(_toAddress);
        require(public_mint_price[mint_size]  <= msg.value, "wrong value");
        require(mint_size <= publicQouta[msg.sender], "NO QOUTA");
        
        publicQouta[msg.sender]-=mint_size;

        
        _mint(mint_size,_toAddress);
    }


    function mintPrivate(uint mint_size, address _toAddress)  external payable {
        // Must be sent from the owner proxy or owner.
        require(privateMintActive,"PRIVATE MINT IS NOT ACTIVE");        
        require(mint_size > 0,"Invalid Mint Size");    
        require(canMintPrivate(mint_size));
        require(whiteListSecond[msg.sender] || whiteList[msg.sender],"You are not in any whitelist");
        require(mint_size <= publicQouta[msg.sender], "NO QOUTA FOR MINT");

        if (whiteList[msg.sender]) {
            require(private_mint_price[mint_size]  <= msg.value, "wrong value");
            publicQouta[msg.sender]-=mint_size;
        } else if (whiteListSecond[msg.sender]) {
            require(public_mint_price[mint_size]  <= msg.value, "wrong value");
            publicQouta[msg.sender]-=mint_size;
        } 
        _mint(mint_size,_toAddress);

    }

    function mintFree(address _toAddress)  external payable {
        // Must be sent from the owner proxy or owner.
        require(privateMintActive,"PRIVATE MINT IS NOT ACTIVE");        
        require(canMintFree(1));


        require(1 <= whiteListFreeQouta[msg.sender],"NO QOUTA FOR FREE PACK MINT");
        whiteListFreeQouta[msg.sender]--;
    
        _mint(1,_toAddress);

    }
    function canMintPrivate(uint256 mint_size)  public view returns (bool) {
        return canMint(mint_size);
    }
    function canMintFree(uint256 mint_size)  public view returns (bool) {
        return canMint(mint_size);
    }
    function canMint(uint256 mint_size)  public view returns (bool) {
        if (!allowed_mint_size[mint_size]) {
            return false;
        }

        ZenCats zencatContract = ZenCats(nftAddress);
        
        if(zencatContract.paused())
            return false;

        return mint_size <= ZENCATS_SUPPLY;
    }

}