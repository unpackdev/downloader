// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseNFT.sol";

contract MITNft is BaseNFT {
    struct NftInfo {
        uint256 tokenId ;
        string tokenUri ;
        uint256 gene ;
        address owner ;
    }

    //////////////////////////////////
    //          events
    /////////////////////////////////
    event SetGene(uint256 indexed tokenId, uint256 gen, uint256 srcGen);

    // tokenId => gene
    mapping(uint256 => uint256) public tokenGene ;

    constructor(string memory name, string memory symbol, string memory baseUri, address managerAddr)
    BaseNFT(name, symbol, baseUri, managerAddr) {

    }

    // Set up NFT gene data
    function setGens(uint256 gen, uint256 tokenId) external returns(bool) {
        return _setGens(gen, tokenId) ;
    }

    // batch set up gens data
    function batchSetGens(uint256 [] memory tokenIds, uint256 [] memory genes) external returns(bool) {
        for(uint256 i = 0 ;i < genes.length ; i++) {
            _setGens(genes[i], tokenIds[i]) ;
        }
        return true ;
    }

    function _setGens(uint256 gen, uint256 tokenId) private onlyRole(MANAGER_ROLE) returns(bool) {
        require(_exists(tokenId), "MITNft: setGens query for nonexistent token") ;
//        if(tokenGene[tokenId] == 0) {
        uint256 srcGen = tokenGene[tokenId];
        tokenGene[tokenId] = gen ;
        emit SetGene(tokenId, gen, srcGen) ;
//        }
        return true ;
    }

    function getSpecialSuffix(uint256 tokenId) internal view virtual override returns (string memory) {
        return Strings.toString(tokenGene[tokenId]);
    }

    function _migration(uint256 tokenId, uint256 gene, address owner) internal onlyRole(MANAGER_ROLE) virtual override returns (bool){
        // mint NFT
        _safeMint(owner, tokenId) ;

        // set genes
        tokenGene[tokenId] = gene ;
        return true ;
    }

    // get NFT info
    function getNftInfoById(uint256 tokenId) public view returns(NftInfo memory) {
        NftInfo memory nftInfo ;
        nftInfo.tokenId = tokenId ;
        nftInfo.gene = tokenGene[tokenId] ;
        nftInfo.owner = ownerOf(tokenId) ;
        nftInfo.tokenUri = tokenURI(tokenId) ;
        return nftInfo ;
    }

    // get ed NFT info By TokenIds
    function getNftInfoByIds(uint256 [] memory tokenIds) public view returns(NftInfo [] memory) {
        NftInfo[] memory nftInfoArr = new NftInfo[] (tokenIds.length) ;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            nftInfoArr[i] = getNftInfoById(tokenIds[i]) ;
        }
        return nftInfoArr;
    }

    // get NFT gens
    function getNftOwnerGensByIds(uint256 [] memory tokenIds) public view returns(uint256 [] memory, address [] memory) {
        uint256 [] memory genes = new uint256 [] (tokenIds.length) ;
        address [] memory owners = new address[] (tokenIds.length) ;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            genes[i] = tokenGene[tokenIds[i]] ;
            owners[i] = ownerOf(tokenIds[i]) ;
        }
        return (genes, owners);
    }

    // get ed NFT Info By Page, page start zero
    function getAllNftInfoByPage(uint256 page, uint256 limit) external view returns(NftInfo [] memory, uint256 ) {
        uint256 startIndex = page * limit ;
        uint256 len = totalSupply() - startIndex ;

        if(len > limit) {
            len = limit ;
        }

        if(startIndex >= totalSupply()) {
            len = 0 ;
        }

        NftInfo[] memory nftInfoArr = new NftInfo[] (len) ;
        for(uint256 i = 0 ;i < len; i++) {
            uint256 tokenId = tokenByIndex(startIndex + i) ;
            nftInfoArr[i] = getNftInfoById(tokenId) ;
        }

        return (nftInfoArr, totalSupply());
    }

    //  get ed NFT Info By Page & owner, page start zero
    function getOwnerNftInfoByPage(uint256 page, uint256 limit, address owner) external view returns(NftInfo [] memory, uint256) {
        uint256 startIndex = page * limit ;
        uint256 len = balanceOf(owner) - startIndex ;

        if(len > limit) {
            len = limit ;
        }

        if(startIndex >= balanceOf(owner)) {
            len = 0 ;
        }

        NftInfo[] memory nftInfoArr = new NftInfo[] (len) ;
        for(uint256 i = 0 ;i < len; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, startIndex + i) ;
            nftInfoArr[i] = getNftInfoById(tokenId) ;
        }
        return (nftInfoArr, balanceOf(owner));
    }


}
