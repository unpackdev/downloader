// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

contract IpsumOfLOREMNFT is Ownable {
    struct Ipsum {
        address creator;
        bool nsfw;
        bool ownerflip;
        bool adminflip;
        string ipsumMetadataURI;
    }

    mapping(address => mapping(uint256 => Ipsum[])) public tokenIpsum;
    mapping(address => bool) public IpsumTokenContract;
 
    event IpsumAdded(address tokenContract, uint256 tokenId, uint256 ipsumIdx);
    event IpsumUpdated(address tokenContract, uint256 tokenId, uint256 ipsumIdx);
    event IpsumUpdatednsfw(address tokenContract, uint256 tokenId, uint256 ipsumIdx);

    modifier onlyAllowedTokenContract(address tokenContract) {
        require(IpsumTokenContract[tokenContract],"tokenContract is not on the allowlist");
        _;
    }

    address public adminSigner;
 
    constructor(){}

    function numIpsum(address tokenContract, uint256 tokenId) public view returns (uint256){
        return tokenIpsum[tokenContract][tokenId].length;
    }

    function IpsumFor(address tokenContract, uint256 tokenId) public view returns (Ipsum[] memory){
        return tokenIpsum[tokenContract][tokenId];
    }

    function IpsumAt(address tokenContract, uint256 tokenId, uint256 startIdx, uint256 endIdx
    ) public view returns (Ipsum[] memory) {
        Ipsum[] memory l = new Ipsum[](endIdx - startIdx + 1);
        uint256 length = endIdx - startIdx + 1;

        for (uint256 i = 0; i < length; i++) {
            l[i] = tokenIpsum[tokenContract][tokenId][startIdx + i];
        }
        return l;
    }

    function isCCOtoken(uint256 tokenId) public pure returns(bool){
        return tokenId>=9900 && tokenId<=9999;

    }

    function isownerOf(address tokenContract, address tokenOwner,  uint256 tokenId) public view onlyAllowedTokenContract(tokenContract) returns(bool){
        return IERC721(tokenContract).ownerOf(tokenId) == tokenOwner;
    }

    function addIpsum(address tokenContract, uint256 tokenId, string memory ipsumMetadataURI) 
    public onlyAllowedTokenContract(tokenContract) {
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(tokenOwner == _msgSender() || isCCOtoken(tokenId), "not token owner");
        tokenIpsum[tokenContract][tokenId].push(
            Ipsum(_msgSender(), false, true, true, ipsumMetadataURI)
            );
        emit IpsumAdded(tokenContract, tokenId, tokenIpsum[tokenContract][tokenId].length - 1);
    }

    function addIpsumWithSignature(bytes memory signature, address tokenContract, uint256 tokenId, uint256 ipsumIdx, string memory ipsumMetadataURI
    ) public onlyAllowedTokenContract(tokenContract) {

        bytes32 messageDigest = keccak256(abi.encodePacked(tokenContract, _msgSender(), tokenId, ipsumIdx));
        bytes32 ethHashMessage = ECDSA.toEthSignedMessageHash(messageDigest);
        address signer = ECDSA.recover(ethHashMessage, signature);
        require(signer == adminSigner,"auth fail");
        require(numIpsum(tokenContract, tokenId) == ipsumIdx,"ipsumIdx does not exist");

        tokenIpsum[tokenContract][tokenId].push(
            Ipsum(_msgSender(), false, true, true, ipsumMetadataURI)
        );
        emit IpsumAdded(tokenContract, tokenId, tokenIpsum[tokenContract][tokenId].length - 1);
    }

    function updateIpsumMetadataURI(
        address tokenContract,
        uint256 tokenId,
        uint256 ipsumIdx,
        string memory newipsumMetadataURI
    ) public onlyAllowedTokenContract(tokenContract) {

        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(tokenIpsum[tokenContract][tokenId][ipsumIdx].creator == _msgSender(), "not ipsumIdx creator");
        require(tokenOwner == _msgSender() || isCCOtoken(tokenId), "not token owner");
        tokenIpsum[tokenContract][tokenId][ipsumIdx].ipsumMetadataURI = newipsumMetadataURI;
        emit IpsumUpdated(tokenContract, tokenId, ipsumIdx);
    }
    function updateIpsumnsfw(
        address tokenContract,
        uint256 tokenId,
        uint256 ipsumIdx,
        bool newnsfw)
        public onlyAllowedTokenContract(tokenContract) {

        // address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        // require(tokenOwner!=address(0), "token does not exist");
        require(ipsumIdx < numIpsum(tokenContract, tokenId)  ,"ipsumidx does not exist");
        tokenIpsum[tokenContract][tokenId][ipsumIdx].nsfw = newnsfw;
        emit IpsumUpdatednsfw(tokenContract, tokenId, ipsumIdx);
    }
    function updateIpsumOwnerflip(
        address tokenContract,
        uint256 tokenId,
        uint256 ipsumIdx,
        bool newownerflip
    ) public onlyAllowedTokenContract(tokenContract) {

        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(tokenOwner == _msgSender() || owner() == _msgSender(), "not token owner");
        tokenIpsum[tokenContract][tokenId][ipsumIdx].ownerflip = newownerflip;
        emit IpsumUpdated(tokenContract, tokenId, ipsumIdx);
    }
    
    //onlyOwner
    function updateIpsumAdminflip(
        address tokenContract,
        uint256 tokenId,
        uint256 ipsumIdx,
        bool newadminflip
    ) public onlyAllowedTokenContract(tokenContract) onlyOwner {

        tokenIpsum[tokenContract][tokenId][ipsumIdx].adminflip = newadminflip;
        emit IpsumUpdated(tokenContract, tokenId, ipsumIdx);
    }

    function setIpsumTokenContract(address tokenContract, bool isListed) public onlyOwner{
        IpsumTokenContract[tokenContract] = isListed;
    }

    function setSigner(address newSigner) external onlyOwner {
        adminSigner = newSigner;
    }
}