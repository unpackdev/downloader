// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

interface NInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getFirst(uint256 tokenId) external view returns (uint256);
    function getSecond(uint256 tokenId) external view returns (uint256);
    function getThird(uint256 tokenId) external view returns (uint256);
    function getFourth(uint256 tokenId) external view returns (uint256);
    function getFifth(uint256 tokenId) external view returns (uint256);
    function getSixth(uint256 tokenId) external view returns (uint256);
    function getSeventh(uint256 tokenId) external view returns (uint256);
    function getEight(uint256 tokenId) external view returns (uint256);
}

contract MatrixFromN is ERC721Enumerable, Ownable, ReentrancyGuard  {
    using Strings for uint256;
    uint256 public constant NOWNER_PRICE = 0.03 ether;
    uint256 public constant REGULAR_PRICE = 0.08 ether;

    bool private _saleIsActive = false;
    bool private _presaleIsActive = true;

    uint256 public _tokenId;

    address private _nAddr = 0x05a46f1E545526FB803FF974C790aCeA34D1f2D6;

    NInterface nContract = NInterface(_nAddr);

    constructor() ERC721("Matrix from N", "M") Ownable() {}

    function getMatrix(uint256 tokenId) public view returns (uint8[64] memory) {
        uint256[8] memory n;
        uint8[64] memory m;
        
        n[0] = nContract.getFirst(tokenId);
        n[1] = nContract.getSecond(tokenId);
        n[2] = nContract.getThird(tokenId);
        n[3] = nContract.getFourth(tokenId);
        n[4] = nContract.getFifth(tokenId);
        n[5] = nContract.getSixth(tokenId);
        n[6] = nContract.getSeventh(tokenId);
        n[7] = nContract.getEight(tokenId);
        
        uint256 n1 = 0;
        uint256 n2 = 0;
        uint256 n3 = 0;
        uint256 n3i = 0;

        for(uint256 i = 0; i < 8; i++) {
            for(uint256 j = 0; j < 8; j++) {

                n1 = n[i];
                if (i < 7)
                    n2 = n[i + 1];
                else
                    n2 = n[0];
                n3i = (i + 2);
                if (n3i > 7)
                    n3i -= 8;
                n3 = n[n3i];
                m[i * 8 + 0] = uint8((n1 + n2 + n3) % 10);
                m[i * 8 + 1] = uint8((n1 * n2 + n3) % 10);
                m[i * 8 + 2] = uint8((n1 + n2 * n3) % 10);
                m[i * 8 + 3] = uint8((n1 * n3 + n2) % 10);
                m[i * 8 + 4] = uint8((n1 * n2 * n3 + n1) % 10);
                m[i * 8 + 5] = uint8((n1 * n2 + n2 * n1 + n3 * n2) % 10);
                m[i * 8 + 6] = uint8((n1 * n3 * n2 + n1 + n2) % 10);
                m[i * 8 + 7] = uint8((n1 * n3 + n2 * n1 + n1) % 10);
            }
        }
        return m;
    }
    function isNOwner(uint256 tokenId) public view returns (bool) {
        require(tokenId > 0 && tokenId < 8889, "Token ID invalid");
        if(nContract.ownerOf(tokenId) == msg.sender)
            return true;
        return false;
    }
    //function _baseURI() internal view virtual override returns (string memory) {
    //    return _baseURL;
    //}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        //string memory baseURI = _baseURI();
        //return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        return string(abi.encodePacked('https://ipfs.io/ipfs/QmPcooHJA56PoG7XzW6bSPGZFFvL11QwjesTKW6fSkebMf/', tokenId.toString(), '.json'));
    }

    function mintWithN(uint256 tokenId) public payable nonReentrant  {
        require(tokenId > 0 && tokenId < 8889, "Token ID invalid");
        require(!_exists(tokenId), "TOKEN TAKEN");
        require(_presaleIsActive, "PRESALE_INACTIVE");
        require(NOWNER_PRICE <= msg.value, "INSUFFICIENT_ETH");
        require(nContract.ownerOf(tokenId) == msg.sender, "NOT_N_OWNER");
        _safeMint(msg.sender, tokenId);
    }

    function mint(uint256 tokenId) public payable nonReentrant  {
        require(tokenId > 0 && tokenId < 8889, "Token ID invalid");
        require(!_exists(tokenId), "TOKEN_TAKEN");
        require(_saleIsActive, "SALE_INACTIVE");
        require(REGULAR_PRICE <= msg.value, "INSUFFICIENT_ETH");
        _safeMint(msg.sender, tokenId);
    }
    function tokenAvailable(uint256 tokenId) public view returns(bool) {
        if(_exists(tokenId))
            return false;
        return true;
    }
    //function getMintedTokens() public view returns(uint256[] memory) {
        //return _allTokens;
    //}
    function getPresaleActive() public view returns (bool) {
        return _presaleIsActive;
    }

    function getPublicSaleActive() public view returns (bool) {
        return _saleIsActive;
    }
    //admin
    function setPresaleActive(bool val) public onlyOwner {
        _presaleIsActive = val;
    }

    function setPublicSaleActive(bool val) public onlyOwner {
        _saleIsActive = val;
    }
    //function setBaseURI(string memory url) onlyOwner public {
    //    _baseURL = url;
    //}
    //function getBaseURI() onlyOwner public view returns (string memory) {
    //    return _baseURL;
    //}
    //function setNAddr(address val) onlyOwner public {
    //    _nAddr = val;
    //    nContract = NInterface(_nAddr);
    //}
    //function getNAddr() onlyOwner public view returns (address) {
    //    return _nAddr;
    //}
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
}
