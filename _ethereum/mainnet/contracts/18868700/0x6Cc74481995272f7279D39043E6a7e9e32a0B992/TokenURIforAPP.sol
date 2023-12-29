// SPDX-License-Identifier: MIT

/*
 * Created by masataka.eth (@masataka_net)
 */

import "./ITokenURIforAPP.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

pragma solidity >=0.7.0 <0.9.0;

contract TokenURIforAPP is ITokenURIforAPP,AccessControl{
    using Strings for uint256;

    struct WalletMng {
        uint128 burninIndex;
        uint128 burninCount;
    }

    IERC721 public burninNFT;

    address public constant WITHDRAW_ADDRESS = 0x62314D5A0F7CBed83Df49C53B9f2C687d2c18289;
    
    mapping(uint256 => uint256) public burninIndexTokenId;
    mapping(address => WalletMng) public _walletMng;

    uint128 public currentBurninIndex = 1; // First time burnin is 1 and original is 0.
    bool public paused = true;
    // uint256 public cost = 0.001 ether;
    uint256 public cost = 0 ether;
    bytes32 public merkleRoot;
    string public baseURI;
    string public baseURI_lock;
    string public baseExtension = ".json";
    string public beforeRevealURI;

    event Registory(uint256 indexed burningIndex, address indexed owner, uint256 tokenId);

    error OnlyOperatedByTokenOwner(uint256 tokenId, address operator);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // default
        baseURI = "https://nft.aopanda.ainy-llc.com/site/app/metadata/";
        baseURI_lock = "https://nft.aopanda.ainy-llc.com/site/app_lock/metadata/";
        beforeRevealURI = "https://nft.aopanda.ainy-llc.com/site/app/reveal/metadata/";
    }
    // modifier
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }
    // onlyAdmin
    function setBurninNFT(IERC721 _address) external onlyAdmin {
        burninNFT = _address;
    }
    function setCost(uint256 _value) external onlyAdmin {
        cost = _value;
    }
    function setMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
        merkleRoot = _merkleRoot;
    }
    function setBaseURI(string memory newURI) external virtual onlyAdmin {
        baseURI = newURI;
    }
    function setBaseURI_lock(string memory newURI) external virtual onlyAdmin {
        baseURI_lock = newURI;
    }
    function setBaseExtension(string memory newExt) external virtual onlyAdmin {
        baseExtension = newExt;
    }
    function setBeforeRevealURI(string memory newURI) external virtual onlyAdmin {
        beforeRevealURI = newURI;
    }
    function IncBurninIndex() external onlyAdmin {
        currentBurninIndex += 1;
    }
    function setPaused(bool _value) external onlyAdmin {
        paused = _value;
    }
    function withdraw() external onlyAdmin {
        (bool os, ) = payable(WITHDRAW_ADDRESS).call{value: address(this).balance}("");
        require(os);
    }

    // external
    function burninRegistory
    (uint256[] memory _burnTokenIds,uint256 _alAmountMax,bytes32[] calldata _merkleProof) 
        external payable{
        require(paused == false,"sale is not active");
        require(tx.origin == msg.sender,"the caller is another controler");
        require(getALAuth(msg.sender,_alAmountMax,_merkleProof) == true,"You don't have a Allowlist!");
        require(_burnTokenIds.length > 0, "need to burnin at least 1 NFT");
        require(_burnTokenIds.length <= _getRemainWithCheck(msg.sender,_alAmountMax), "claim is over max amount");
        if(cost > 0){
            require(msg.value >= cost * _burnTokenIds.length, "not enough eth");
        }
        
        _walletMng[msg.sender].burninCount += uint128(_burnTokenIds.length);

        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            if(burninNFT.ownerOf(tokenId) != msg.sender) revert OnlyOperatedByTokenOwner(tokenId, msg.sender);
            burninIndexTokenId[tokenId] = currentBurninIndex;
            emit Registory(currentBurninIndex,msg.sender,tokenId);
        }
    }

    function getALAuth(address _address,uint256 _wlAmountMax,bytes32[] calldata _merkleProof)
    public view returns (bool) {
        bool _exit = false;
        bytes32 _leaf = keccak256(abi.encodePacked(_address,_wlAmountMax));   
        if(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, _leaf) == true){
            _exit = true;
        }
        return _exit;
    }

    function getRemain(address _address,uint256 _alAmountMax,bytes32[] calldata _merkleProof
    ) external view returns (uint256) {
        uint256 _Amount = 0;
        if(paused == false){
            if(getALAuth(_address,_alAmountMax,_merkleProof) == true){
                _Amount = _getRemain(_address,_alAmountMax);
            }
        }
        return _Amount;
    }

    function tokenURI_future(uint256 _tokkenId,uint256 _locked) external view
    returns(string memory URI){
        if(burninIndexTokenId[_tokkenId] < currentBurninIndex){
            string memory _baseURI = baseURI;
            if(_locked == 1){
                // locked
                _baseURI = baseURI_lock;
            }
            // Show Image
            if(burninIndexTokenId[_tokkenId] == 0){
                // original
                URI = string.concat(
                _baseURI,
                _tokkenId.toString(),
                baseExtension
                );
            }else{
                // burnin
                URI = string.concat(
                _baseURI,
                burninIndexTokenId[_tokkenId].toString(),
                "/",
                _tokkenId.toString(),
                baseExtension
                );
            }
        }else{
            // before rebeal
            string memory _metadata = "0.json";
            if(_locked == 1){
                // locked
                _metadata = "1.json";
            }
            URI = string.concat(
                beforeRevealURI,
                _metadata
            );
        }
    }

    // @dev Call carefully to avoid blockgaslimit
    function isBurnin(uint256[] calldata _tokenIds) external view returns(bool[] memory){
        bool[] memory _isBurnin = new bool[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _isBurnin[i] = (burninIndexTokenId[_tokenIds[i]] == currentBurninIndex);
        }
        return _isBurnin;
    }

    // internal
    function _resetCount(address _owner) internal{
        if(_walletMng[_owner].burninIndex < currentBurninIndex){
            _walletMng[_owner].burninIndex = currentBurninIndex;
             _walletMng[_owner].burninCount = 0;
        }
    }

    function _getRemain(address _address,uint256 _alAmountMax) internal  view returns  (uint256){
        uint256 _Amount = 0;
        if(_walletMng[_address].burninIndex < currentBurninIndex){
            _Amount = _alAmountMax;
        }else{
            _Amount = _alAmountMax - _walletMng[_address].burninCount;
        }
        return _Amount;
    }

    function _getRemainWithCheck(address _address,uint256 _alAmountMax) internal returns (uint256){
        _resetCount(_address);  // Always check reset
        return _getRemain(_address,_alAmountMax);
    }
}