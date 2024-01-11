// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";

import "./IToken.sol";

contract WAncientFisherman is Ownable {

    bool public isPrivateMint;
    bool public isPublicMint;

    
    uint256 public mintPriceEth = 0.03 ether; 
    uint256 public mintPriceBundleEth = 0.12 ether; 
    
    uint256 public mintPriceWrld = 1000 ether;
    uint256 public mintPriceBundleWrld = 4000 ether;
    
    bytes32 public whitelistMerkleRoot;

    address public foundersWallet;

    IToken public WRLD_TOKEN;

    event MintEth(address indexed player, bool bundle, uint256 numberOfTokens);
    event MintWrld(address indexed player, bool bundle, uint256 numberOfTokens);

    mapping(address => uint256) private maxMintsPerAddress;

    constructor(){
        foundersWallet = 0x02367e1ed0294AF91E459463b495C8F8F855fBb8;
        WRLD_TOKEN = IToken(0xD5d86FC8d5C0Ea1aC1Ac5Dfab6E529c9967a45E9); 
    }
    

    function setFoundersWallet(address newFoundersWallet) external onlyOwner{
        foundersWallet = newFoundersWallet;
    }

    //CONTROL FUNCTIONS
    function updateWhitelistMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _newMerkleRoot;
    }
    
    function setPrice(uint256 mintPriceBundleEth_, uint256 mintPriceBundleWrld_, uint256 mintPriceEth_, uint256 mintPriceWrld_) external onlyOwner{
        mintPriceBundleEth = mintPriceBundleEth_;
        mintPriceBundleWrld = mintPriceBundleWrld_;
        mintPriceEth = mintPriceEth_;
        mintPriceWrld = mintPriceWrld_;
    }

    function setPublicMint(bool isPublicMint_) external onlyOwner{
        isPublicMint = isPublicMint_;
    }

    function setPrivateMint(bool isPrivateMint_) external onlyOwner{
        isPrivateMint = isPrivateMint_;
    }

    modifier onlyMinter(address player, uint256 _numberOfTokens, bool bundle, bytes32[] calldata merkleProof){
        require(isPrivateMint || isPublicMint, "Mint not open");
        require(_numberOfTokens > 0, "Token must be grt than 0");
        if(isPrivateMint){
            if(bundle){
                require(_numberOfTokens <= 1, "max 1 bundle");
                require((maxMintsPerAddress[player] + _numberOfTokens * 5) <= 5, "max 1 bundle");
                
            }else{
                require(_numberOfTokens <= 5, "max 5 blds");
                require((maxMintsPerAddress[player] + _numberOfTokens) <= 5, "max 5 blds");
                
            }
        }else{
            if(bundle){
                require(_numberOfTokens <= 5, "max 5 bundle");
            }else{
                require(_numberOfTokens <= 25, "max 25 blds");
            }
        }
        

        if(!isPublicMint){
            bool isWhitelisted = MerkleProof.verify(
                merkleProof, //routeProof
                whitelistMerkleRoot, //root
                keccak256(abi.encodePacked(player)/* leaf */)
            );
            require(isWhitelisted, "invalid-proof");
        }
        _;
    }

    function mintEth(address player, uint256 _numberOfTokens, bool bundle, bytes32[] calldata merkleProof) external payable onlyMinter(player, _numberOfTokens, bundle, merkleProof){
        if(bundle){
            require(msg.value >= mintPriceBundleEth * _numberOfTokens, "inc-bnd-val");
            maxMintsPerAddress[player] += _numberOfTokens * 5;
        }else{
            require(msg.value >= mintPriceEth * _numberOfTokens, "inc-eth-val");
            maxMintsPerAddress[player] += _numberOfTokens;
        }

        emit MintEth(player, bundle, _numberOfTokens);
        
        
    }

    function mintWrld(address player, uint256 _numberOfTokens, bool bundle, bytes32[] calldata merkleProof) external payable onlyMinter(player, _numberOfTokens, bundle, merkleProof){
        if(bundle){
            require(mintPriceBundleWrld * _numberOfTokens <= WRLD_TOKEN.balanceOf(player), "low-balance-bnd-wrld");
            require(mintPriceBundleWrld * _numberOfTokens <= WRLD_TOKEN.allowance(player, address(this)), "low-allowance-bnd-wrld");

            WRLD_TOKEN.transferFrom(player, foundersWallet, mintPriceBundleWrld * _numberOfTokens);

            maxMintsPerAddress[player] += _numberOfTokens * 5;
        }else{
            require(mintPriceWrld * _numberOfTokens <= WRLD_TOKEN.balanceOf(player), "low-balance-wrld");
            require(mintPriceWrld * _numberOfTokens <= WRLD_TOKEN.allowance(player, address(this)), "low-allowance-wrld");

            WRLD_TOKEN.transferFrom(player, foundersWallet, mintPriceWrld * _numberOfTokens);

            maxMintsPerAddress[player] += _numberOfTokens;
        }
        
        emit MintWrld(player, bundle, _numberOfTokens);
        
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        payable(foundersWallet).transfer(_balance);
    }

}