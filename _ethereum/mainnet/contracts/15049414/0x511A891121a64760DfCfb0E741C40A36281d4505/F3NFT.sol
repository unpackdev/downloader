// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721PresetMinterPauserAutoId.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract F3NFT is ERC721PresetMinterPauserAutoId {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    // Count the amount mint
    Counters.Counter private _tokenCounter;
    EnumerableSet.UintSet private _tokenList;
    // limit  mint max 10000
    uint256 constant totalNumber = 10240;
    mapping(address=>EnumerableSet.UintSet)  private userTokens;
    address immutable dead = 0x000000000000000000000000000000000000dEaD;
    //base
    string private baseTokenURI = "ipfs://bafybeigvwebps7nchb3xaljqnknkbfz6k22mtc4racernp4fsfnk42wyte/";
    bytes32 public constant SUPER_ROLE = keccak256("SUPER_ROLE");
    constructor() ERC721PresetMinterPauserAutoId("Hash Eagle", "Eagle", "") {
        _setupRole(SUPER_ROLE, _msgSender());
    }
    uint256 constant openTotal = 7000;
    uint256 constant foundTotal = 3240;
    EnumerableSet.UintSet _superTokens;
    EnumerableSet.UintSet _openMints;
    EnumerableSet.UintSet _foundMints;
    /* ==================================== EVENT START ======================================== */
    event SafeMint(address indexed sender,address indexed to, uint256 tokenId,  uint256 createtime);
    event ChangeURI(address indexed sender, string oldUri, string newUri, uint256 createtime);
    event Burn(address indexed sender, address owner,uint256 tokenId, uint256 createtime);
    event AddSuperId(address indexed sender, uint256[] tokenIds, uint256 createtime);
    /* ==================================== EVENT END ======================================== */

    /* ==================================== ERROR START ======================================== */
    error Unauthorized();
    /* ==================================== ERROR END ======================================== */


    /* =================================== Mutable Functions START ================================ */
    function safeMint(address _to, uint256 _tokenId) public onlyRole(MINTER_ROLE){
        require(_openMints.length()<openTotal,"total limit mint 7000");
        require(!_superTokens.contains(_tokenId),"is not super tokenId");
        _saMinit(_to,_tokenId);
        require(_openMints.add(_tokenId),"_openMints add error");
    }
    function _saMinit(address _to, uint256 _tokenId)  internal {
        require(_tokenId>0,"tokenId can not zero");
        require(mintCount()<totalNumber,"mint  limit");
        require(!_tokenList.contains(_tokenId),"cannot repeat mint");
        require(_tokenList.length()<totalNumber,"token  mint limit 10240");
        //mint（If _tokenId already exists, the call will return with an error）
        _mint(_to, _tokenId);
        
        require(userTokens[_to].add(_tokenId),"userTokens add error");
        require(_tokenList.add(_tokenId),"_tokenList add error");
        emit SafeMint(_msgSender(),_to,_tokenId,block.timestamp);
    }
    function safeMintSuperId(address _to, uint256 _tokenId) public onlyRole(SUPER_ROLE){
        require(_foundMints.length()<foundTotal,"total limit mint 3240");
        // require(_superTokens.contains(_tokenId),"is not super tokenId");
        _saMinit(_to,_tokenId);
        require(_foundMints.add(_tokenId),"_foundMints add error");
    }

    function changeURI(string calldata _tokenURI) external onlyRole(MINTER_ROLE) {
        require(keccak256(abi.encodePacked(_tokenURI)) != keccak256(abi.encodePacked(baseTokenURI)), "same tokenURI");
        emit ChangeURI( _msgSender(), baseTokenURI, _tokenURI, block.timestamp);
        baseTokenURI = _tokenURI;
    }


    function addSuperId(uint256[] calldata tokenIds) public  onlyRole(SUPER_ROLE){
        require(tokenIds.length>0 && tokenIds.length<=30 ,"length must >0 or length <=30");
        uint256 total = 0;
        total = total.add(_foundMints.length()).add(tokenIds.length).add(_superTokens.length());
        require(total<=foundTotal,"limit 3240");
        for(uint256 i=0;i<tokenIds.length;i++){
            require(tokenIds[i]>0,"tokenId can not zero");
            require(!_exists(tokenIds[i]),"It's already cast");
            require(!_superTokens.contains(tokenIds[i]),"It's already cast");
            require(_superTokens.add(tokenIds[i]),"_superTokens add error");
        }
        emit AddSuperId(_msgSender(), tokenIds, block.timestamp);
    }

    //get mint count
    function mintCount() view public returns(uint256){
        return _tokenList.length();
    }
    function mint(address /*to*/) public virtual override(ERC721PresetMinterPauserAutoId){
        revert Unauthorized();
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        address owner = ERC721.ownerOf(tokenId);
        transferFrom(owner, dead, tokenId);
        emit Burn(_msgSender(), owner,tokenId, block.timestamp);
    }
    /* =================================== Mutable Functions END ================================ */

    /* ====================================== View Functions START ================================ */
    function getMyNFT() external view returns(uint256[] memory) {
        return userTokens[_msgSender()].values();
    }
    function getSuperIds() public view  returns (uint256[] memory) {
        return _superTokens.values();
    }
    function totalSupply() public view virtual override(ERC721Enumerable) returns (uint256) {
        return totalNumber;
    }

    function getOpenMints() public view  returns (uint256[] memory) {
        return _openMints.values();
    }
    function getFoundMints() public view  returns (uint256[] memory) {
        return _foundMints.values();
    }

    function _baseURI() internal view virtual override(ERC721PresetMinterPauserAutoId) returns(string memory)
    {
        return baseTokenURI;
    }
    /* ====================================== View Functions END ================================ */
}