pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

abstract contract WolfGang is IERC721 {
    function mint(address receiver) external virtual returns (uint);
    function burn(uint tokenId) external virtual;
}

contract WolfFusion is AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    
    WolfGang _wolfgang = WolfGang(0xC269bDD2975a3D5B23B315dD83B82FDfbf4Ac4d9);
    IERC20 _wolfpawn = IERC20(0xB1838B5059B6Ca3696bb9833c31Fdb4671191945);
    
    EnumerableSet.UintSet _uniqueTokens;
    
    struct TokenData {
        uint tokenA;
        uint tokenB;
        bytes traits;
    }
    
    mapping (uint => TokenData) public tokenTraits;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    uint public fuseFeePawn = 2 ether;
    uint public fuseFeeEther = 0.03 ether;
    uint public fusePawnCashback = 1 ether;
    
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }
    
    event Fuse(uint tokenA, uint tokenB, uint newTokenId, bytes newTraits, address owner);
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }
    
    function fuse(uint tokenA, uint tokenB, bytes memory traits, bool payWithEther) public payable {
        require(tokenA != tokenB, "tokens must be different");
        require(_wolfgang.ownerOf(tokenA) == msg.sender && _wolfgang.ownerOf(tokenB) == msg.sender, "sender does not owns the tokens");
        require(!_uniqueTokens.contains(tokenA) && !_uniqueTokens.contains(tokenB), "cant fuse a unique token");
        if (payWithEther)
            require(msg.value >= fuseFeeEther, "ether value sent is below fuse fee");
        else
            require(_wolfpawn.transferFrom(msg.sender, address(this), fuseFeePawn), "pawn transfer exception");
        
        _wolfgang.burn(tokenA);
        _wolfgang.burn(tokenB);
        uint newTokenId = _wolfgang.mint(msg.sender);
        
        tokenTraits[newTokenId] = TokenData(tokenA, tokenB, traits);
        
        require(_wolfpawn.transfer(msg.sender, fusePawnCashback), "pawn cashback transfer exception");
        
        emit Fuse(tokenA, tokenB, newTokenId, traits, msg.sender);
    }
    
    function setFees(uint fuseFeePawn_, uint fuseFeeEther_, uint fusePawnCashback_) public onlyAdmin {
        fuseFeePawn = fuseFeePawn_;
        fuseFeeEther = fuseFeeEther_;
        fusePawnCashback = fusePawnCashback_;
    }
    
    function addUnique(uint tokenId) public onlyAdmin {
        _uniqueTokens.add(tokenId);
    }
    
    function addUniqueBatch(uint[] memory tokenIds) public onlyAdmin {
        for (uint i = 0; i < tokenIds.length; i++) {
            _uniqueTokens.add(tokenIds[i]);
        }
    }
    
    function uniques() public view returns (uint[] memory) {
        uint[] memory _uniques = new uint[](_uniqueTokens.length());
        for (uint i = 0; i < _uniqueTokens.length(); i++) {
            _uniques[i] = _uniqueTokens.at(i);   
        }
        return _uniques;
    }
    
    function withdrawAll() public onlyAdmin {
        require(payable(msg.sender).send(address(this).balance));
    }
}