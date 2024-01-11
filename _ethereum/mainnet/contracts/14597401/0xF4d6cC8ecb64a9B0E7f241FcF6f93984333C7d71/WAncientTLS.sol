// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";

import "./IToken.sol";

contract WAncientTLS is Ownable {
    uint256 public tokenId;

    bool public isPrivateTwoMint = true;
    bool public isPublicMint;

    //PRICES
    uint256 public mintPriceBundleEth = 0.17 ether; //0.17 ether;
    //TBD
    uint256 public mintPriceBundleWrld = 3000 ether;

    bytes32 public whitelistMerkleRoot;

    address public foundersWallet;

    IToken public WRLD_TOKEN;

    event BundleMintEth(address indexed player, uint256 indexed tokenId, uint256 numberOfTokens);
    event BundleMintWrld(address indexed player, uint256 indexed tokenId, uint256 numberOfTokens);

    constructor(){
        foundersWallet = 0x02367e1ed0294AF91E459463b495C8F8F855fBb8;
        WRLD_TOKEN = IToken(0xD5d86FC8d5C0Ea1aC1Ac5Dfab6E529c9967a45E9);
        whitelistMerkleRoot = 0x23b56d3d5fdb3794dbde2d8b4ddb588f3d3a26564ee14a099fa2dbaa303f51fa;
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
    
    function setPrice(uint256 mintPriceBundleEth_, uint256 mintPriceBundleWrld_) external onlyOwner{
        mintPriceBundleEth = mintPriceBundleEth_;
        mintPriceBundleWrld = mintPriceBundleWrld_;
    }

    function setPrivateTwoMint(bool isPrivateMint_) external onlyOwner{
        isPrivateTwoMint = isPrivateMint_;
    }

    function setPublicMint(bool isPublicMint_) external onlyOwner{
        isPublicMint = isPublicMint_;
    }

    modifier onlyMinter(address player, uint256 _numberOfTokens,  bytes32[] calldata merkleProof){
        require(isPrivateTwoMint || isPublicMint, "Mint not open");
        require(_numberOfTokens <= 3, "max 3 blds");

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

    function mint(address player, uint256 _numberOfTokens,  bytes32[] calldata merkleProof) external payable onlyMinter(player, _numberOfTokens, merkleProof){

        require(msg.value >= mintPriceBundleEth * _numberOfTokens, "inc-pol-val");

        
        emit BundleMintEth(player, tokenId, _numberOfTokens);
        tokenId += _numberOfTokens;
        
    }

    function mintWrld(address player, uint256 _numberOfTokens,  bytes32[] calldata merkleProof) external payable onlyMinter(player, _numberOfTokens, merkleProof){
        require(mintPriceBundleWrld * _numberOfTokens <= WRLD_TOKEN.balanceOf(player), "low-balance-wrld");
        require(mintPriceBundleWrld * _numberOfTokens <= WRLD_TOKEN.allowance(player, address(this)), "low-allowance-wrld");

        
        emit BundleMintWrld(player, tokenId, _numberOfTokens);
        tokenId += _numberOfTokens;
        
        WRLD_TOKEN.transferFrom(player, foundersWallet, mintPriceBundleWrld * _numberOfTokens);
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        payable(foundersWallet).transfer(_balance);
    }

}