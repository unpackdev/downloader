// SPDX-License-Identifier: MIT

//pragma solidity ^0.8.0;
pragma solidity ^0.8.23;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./PullPayment.sol";
import "./IERC20.sol";
import "./ERC165.sol";

/**
 * @title ERC721ChaosCoinClub
 * ERC721ChaosCoinClub - ERC721 contract that
 * has minting functionality to mint with both Eth and a configurable ERC20, 
 * has an allow list for a certain number of Free mints,
 * has multi-mint functionality
 */
abstract contract ERC721ChaosCoinClub is Context, ERC721, PullPayment, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     */ 
    Counters.Counter internal _nextTokenId;
   
    uint256 public mintingFee;
    
    uint256 public maxSupply;
    uint256 public maxMintSize;

    uint256 public mintingChaosFee;

    mapping(address => uint256) public allowList;

    IERC20 public tokenAddress;
    bool mintingWithChaos = true;
    bool internal chaosLock;

modifier chaosGuard() {
     require(!chaosLock);
     chaosLock = true;
      _;
      chaosLock= false;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Caller is a contract");
    _;
  }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mintingFee,
        uint256 _maxSupply,
        uint256 _maxMintSize,
        uint256 _mintingChaosFee

    ) ERC721(_name, _symbol) {
        mintingFee = _mintingFee;
        maxSupply = _maxSupply;
        maxMintSize = _maxMintSize;
        mintingChaosFee = _mintingChaosFee;
        
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        //_initializeEIP712(_name);
    }
    
    function chaosUnlock() external onlyOwner chaosGuard {
        chaosLock = false;
    }

    function checkChaosLock() public view returns (bool) {
      return chaosLock;
    }

    function mintTo(address _to, uint256 _count) external onlyOwner chaosGuard callerIsUser {
        require(totalSupply() + _count < maxSupply+1, "Maximum supply reached. Attempted to mint too many NFTs.");
        require(_count > 0 && _count < maxMintSize + 1, "Exceeds maximum tokens you can mint in a single transaction");        
        for(uint256 i; i < _count; ++i){
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            //_safeMint(_to, currentTokenId);
            _mint(_to, currentTokenId);
        }
    }

    function mint(uint256 _count) external payable chaosGuard callerIsUser {
        require(totalSupply() + _count < maxSupply + 1, "Cannot Mint that many NFTs.");
        require(_count > 0 && _count < maxMintSize + 1, "Exceeds max mint size");
        require(msg.value > (_count * mintingFee) - 1, "Underpayment detected.");
            
        for(uint256 i; i < _count; ++i){
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _mint(msg.sender, currentTokenId);
        }
    }

    function freeMint(uint256 _count) external chaosGuard callerIsUser {
        require(_count > 0, "Count must be > 0");
        require(totalSupply() + _count < maxSupply + 1, "Cannot mint that many.");
        require(allowList[msg.sender] > 0, "Not on allowlist.");
        require(allowList[msg.sender] +1 > _count, "Tried to mint too many.");

        allowList[msg.sender] -= _count;
            
        for(uint256 i; i < _count; ++i){
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _mint(msg.sender, currentTokenId);
        }

    }

    function mintWithChaos(uint256 _count) external chaosGuard callerIsUser {
        require(mintingWithChaos == true, "Minting with ERC20 token is Not Enabled.");
        require( _count > 0, "mintWithChaos _count must be greater than Zero");
        require(totalSupply()+ _count < maxSupply+1, "Maximum supply reached");
        //require(mintingChaosFee > 0, "Minting with ERC20 token is Not Enabled. mintingChaosFee must be greater than zero.");
        uint256 finalPrice = _count * mintingChaosFee;
        
        tokenAddress.transferFrom(msg.sender, address(this), finalPrice);
        for(uint256 i; i < _count; ++i){
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            //_safeMint(msg.sender, currentTokenId);
            _mint(msg.sender, currentTokenId);
        }
    }
    

    
    function setMintingFee(uint256 _newFee) external onlyOwner {
        mintingFee = _newFee;
    }

    function checkMintPrice() public view returns (uint256) {
      return mintingFee;
    }


    function setChaosCoinAddress(address _newAddress) external onlyOwner {
        tokenAddress = IERC20(_newAddress);
    }

    function setMintingChaosFee(uint256 _newFee) external onlyOwner {
        mintingChaosFee = _newFee;
    }

    function setMintingWithChaos(bool _newState) external onlyOwner {
        mintingWithChaos = _newState;
    }

    function checkMintPriceChaos() public view returns (uint256) {
      return mintingChaosFee;
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }


    //changed from pure to view
    function baseTokenURI() virtual public view returns (string memory);

    //changed from pure to view
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }
    

    function addToAllowList(address _address, uint256 _numDiscountMints) external onlyOwner {
        allowList[_address] = _numDiscountMints;
    }

    function addManyToAllowList(address[] memory _addresses, uint256[] memory _numDiscountMints) external onlyOwner {
        uint256 addressesLength = _addresses.length;
        require(addressesLength == _numDiscountMints.length, "Arrays must be same length");

        for (uint256 i; i < addressesLength; ++i) {
            allowList[_addresses[i]] = _numDiscountMints[i];
        }
    }

    function removeFromAllowList(address[] memory _addresses) external onlyOwner {
        uint256 addressesLength = _addresses.length;
        for (uint256 i; i < addressesLength; ++i) {
            delete allowList[_addresses[i]];
        }
    }

    function allowListAmount(address xyz) public view returns (uint256) {
      if (allowList[xyz] > 0) return allowList[xyz]; 
      else return 0;
    }


    function withdrawPayments(address payable payee) public override onlyOwner callerIsUser chaosGuard {
        super.withdrawPayments(payee);
    }

    function withdrawToken() public onlyOwner chaosGuard callerIsUser {
        tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
    }


////////

    function tokensOwnedBy(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = _nextTokenId.current() - 1;       
        if (tokenCount == 0) return new uint256[](0);
        uint256 ownerTokenCount = balanceOf(_owner);
        if (ownerTokenCount == 0) return new uint256[](0);
        
        uint256[] memory tokensId = new uint256[](ownerTokenCount);
        
        uint256 x;
        //first token index 1
        for(uint256 i=1; i < tokenCount+1; ++i ){
            if(ownerOf(i) == _owner)
            {
                tokensId[x] = i;
                ++x;
            }
        }
        

        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) external callerIsUser chaosGuard {
        uint256 tokenIdsLength = _tokenIds.length;
        for (uint256 i; i < tokenIdsLength; ++i) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) external callerIsUser chaosGuard {
        uint256 tokenIdsLength = _tokenIds.length;
        for (uint256 i; i < tokenIdsLength; ++i) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        uint256 tokenIdsLength = _tokenIds.length;
        for(uint256 i; i < tokenIdsLength; ++i ){
            if(ownerOf(_tokenIds[i]) != account)
                return false;
        }

        return true;
    }

}
