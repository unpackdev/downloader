pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./EnumerableSet.sol";
import "./Address.sol";

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./Initializable.sol";

interface NFTContract {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function name() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract UglyPool is 
    IERC721ReceiverUpgradeable,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
  {
    using EnumerableSet for EnumerableSet.UintSet;

    struct pool {
        IERC721 registry;
        address owner;
        uint256 price;
        uint256 treasury; 
        uint256 fee; 
        uint256 fees; 
        bool random; 
    }

    pool[] public pools;
    mapping(uint => EnumerableSet.UintSet) tokenIds;
    uint private contractFee;  // percent of pool fees 
    address private contractFeePayee; 

    event PoolBuybackPrice(uint indexed poolId, uint256 newBuybackPrice, address indexed sender);
    event PoolFee(         uint indexed poolId, uint256 newFee, address indexed sender);
    event DepositNFT(      uint indexed poolId, uint256 tokenId, address indexed sender);
    event WithdrawNFT(     uint indexed poolId, uint256 tokenId, address indexed sender);
    event Buyback(         uint indexed poolId, uint NFTId, address indexed sender);
    event DepositEth(      uint indexed poolId, uint amount, address indexed sender);
    event WithdrawEth(     uint indexed poolId, uint amount, address indexed sender);
    event CreatedPool(    uint indexed poolId, address indexed sender);
    event TradeExecuted(  uint indexed poolId, address indexed user, uint256 inTokenId, uint256 outTokenId);

    function initialize() public initializer {
        uint[] memory emptyArray;
        createPool(IERC721(0x0000000000000000000000000000000000000000),emptyArray,0, false, 0);         // set pools[0] to nothing
        contractFeePayee = msg.sender;
        contractFee = 10;

        __Ownable_init();
        __Pausable_init();
    }

// Create Pool

    function createPool(IERC721 _registry, uint[] memory _tokenIds, uint _price, bool _random, uint _fee) public payable whenNotPaused { 
        pool memory _pool = pool({
            registry : _registry,
            owner : msg.sender,
            price : _price,
            treasury : msg.value, 
            fee : _fee, 
            fees : 0, 
            random : _random
        });
        uint _poolId = pools.length;
        pools.push(_pool);
        emit CreatedPool(_poolId, msg.sender);
        for (uint i; i < _tokenIds.length; i++){
            tokenIds[_poolId].add(_tokenIds[i]); 
            _registry.safeTransferFrom(msg.sender,  address(this), _tokenIds[i]);
            emit DepositNFT(_poolId, _tokenIds[i], msg.sender);
        }
    }

// Swaps

    // swaps random ugly
    function swapRandomUgly(uint _poolId, uint _id) public whenNotPaused { 
        require(pools[_poolId].random == true,"Pool is not for random swaps.");
        require(tokenIds[_poolId].length() > 0, "Nothing in pool.");
        uint _randomIndex = uint(generateRandom()) % tokenIds[_poolId].length();
        uint _randomId = tokenIds[_poolId].at(_randomIndex);
        pools[_poolId].registry.safeTransferFrom(msg.sender,  address(this), _id);
        pools[_poolId].registry.safeTransferFrom( address(this), msg.sender, _randomId);
        tokenIds[_poolId].remove(_randomId);
        tokenIds[_poolId].add(_id);
        emit TradeExecuted(_poolId, msg.sender, _id, _randomId); 
    }

    // swaps for specific ugly
    function swapSelectedUgly(uint _poolId, uint _idFromPool, uint _idToPool) public payable whenNotPaused { 
        require(pools[_poolId].random == false,"Pool only allows random swaps.");
        require(tokenIds[_poolId].length() > 0, "Nothing in pool.");
        require(msg.value >= pools[_poolId].fee, "Not enough ETH to pay fee");
        pools[_poolId].registry.safeTransferFrom(msg.sender,  address(this), _idFromPool);
        pools[_poolId].registry.safeTransferFrom( address(this), msg.sender, _idToPool);
        uint _contractFee = msg.value * contractFee / 100;         // Take % for contractRoyaltyPayee
        pools[_poolId].fees += msg.value - _contractFee;
        tokenIds[_poolId].remove(_idToPool);
        tokenIds[_poolId].add(_idFromPool);
        // Address.sendValue(payable(contractFeePayee), _contractFee);
        payable(contractFeePayee).transfer(_contractFee);
        emit TradeExecuted(_poolId, msg.sender, _idFromPool, _idToPool); 
    }

// Deposits

    function depositToTreasury(uint _poolId) public payable whenNotPaused { 
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        pools[_poolId].treasury += msg.value;
        emit DepositEth(_poolId, msg.value, msg.sender);
    }

    function depositNFTs(uint _poolId, uint[] memory _tokenIds) public payable whenNotPaused { 
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        for (uint i; i < _tokenIds.length; i++){
            pools[_poolId].registry.safeTransferFrom(msg.sender,  address(this), _tokenIds[i]);
            tokenIds[_poolId].add(_tokenIds[i]);
            emit DepositNFT(_poolId, _tokenIds[i], msg.sender);
        }
    }

    function buyback(uint _poolId, uint[] memory _ids) public whenNotPaused { 
        uint _price = pools[_poolId].price;
        require(_price > 0, "price not set.");
        require(pools[_poolId].treasury >= _price * _ids.length ,"not enough funds in pool.");
        for (uint i = 0; i < _ids.length;i++){
            pools[_poolId].registry.safeTransferFrom(msg.sender,  address(this), _ids[i]);
            tokenIds[_poolId].add(_ids[i]);
            emit Buyback(_poolId, _ids[i], msg.sender);
        }
        pools[_poolId].treasury -= _price * _ids.length;
        // Address.sendValue(payable(msg.sender), _price * _ids.length);
        payable(msg.sender).transfer(_price * _ids.length);
    }

// Withdrawals

    function withdrawPoolTreasury(uint _poolId, uint _amount) public whenNotPaused { 
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        require(_amount <= pools[_poolId].treasury, "Not enough ETH in pool");
        pools[_poolId].treasury -= _amount;
        // Address.sendValue(payable(msg.sender), _amount);
        payable(msg.sender).transfer(_amount);
        emit WithdrawEth(_poolId, _amount, msg.sender);
    }

    function withdrawPoolNFTs(uint _poolId, uint[] memory _ids) public whenNotPaused { 
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        for (uint i;i < _ids.length;i++){
            require (tokenIds[_poolId].contains(_ids[i]), "NFT is not in your pool.");
           pools[_poolId].registry.safeTransferFrom( address(this), msg.sender, _ids[i]);
           tokenIds[_poolId].remove(_ids[i]);
           emit WithdrawNFT(_poolId, _ids[i], msg.sender);
        }
    }

    function withdrawPoolFees(uint _poolId) public whenNotPaused { 
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        require(pools[_poolId].fees > 0, "There are no fees to withdraw.");
        uint256 fees = pools[_poolId].fees;
        pools[_poolId].fees = 0;
        // Address.sendValue(payable(msg.sender), fees);
        payable(msg.sender).transfer(fees);
    }

// Setters 

    function setPoolBuybackPrice(uint _poolId, uint _newPrice) public {
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        pools[_poolId].price = _newPrice;
        emit PoolBuybackPrice(_poolId, _newPrice, msg.sender);
    }

    function setPoolFee(uint _poolId, uint _newFee) public {
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        pools[_poolId].fee = _newFee;
        emit PoolBuybackPrice(_poolId, _newFee, msg.sender);
    }    

    function setContractFee(uint _percentage) public onlyOwner {
        contractFee = _percentage;
    }

    function setContractFeePayee(address _address) public onlyOwner {
        contractFeePayee = _address;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

// View Functions

    function getPoolNFTIds(uint _poolId) public view returns (uint[] memory){  
        return tokenIds[_poolId].values();
    }

    function poolIdsByOwner(address _owner) public view returns (uint256[] memory) {
        uint poolCount = 0;
        uint[] memory _ids = new uint[](numPoolsByOwner(_owner));
         for (uint i = 0; i < pools.length; i++){
            if (pools[i].owner == _owner){
                _ids[poolCount] = i;
                poolCount++;
            }
        }       
        return _ids;
    }

    function numPoolsByOwner(address _owner) private view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < pools.length; i++){
            if (pools[i].owner == _owner)
                count++;
        }
        return count;
    }

    function numPools() public view returns (uint) {
        return pools.length;
    }

    function getContractFee() public view returns (uint){
        return contractFee;
    }

// View Functions (Balances)

    function poolTreasuryBalance(uint _poolId) public view returns (uint) {
        return pools[_poolId].treasury;
    }

   function poolFeesBalance(uint _poolId) public view returns (uint) { 
        return pools[_poolId].fees;
    }

   function poolFee(uint _poolId) public view returns (uint) { 
        return pools[_poolId].fee;
    }

    function poolNFTBalance(uint _poolId) public view returns (uint) { 
        return tokenIds[_poolId].length();
    }

// Misc

    function onERC721Received( address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function generateRandom() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

// Proxy Methods

    function allNFTsByAddress(address _wallet, address _registry) public view returns(uint[] memory){
        uint[] memory nfts = new uint[](balanceOfNFTs(_wallet, _registry));
        for (uint i = 0; i < nfts.length;i++){
            nfts[i] = tokenOfOwnerByIndex(_wallet, i, _registry);
        }
        return nfts;
    }

    // All NFTs in collection owned by wallet address
    function balanceOfNFTs(address _address, address _registry) private view returns (uint) {
        return NFTContract(_registry).balanceOf(_address);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index, address _registry) private view returns (uint256) {
        return NFTContract(_registry).tokenOfOwnerByIndex(_owner,_index);
    }

    function registryName(address _registry) public view returns (string memory){
        return NFTContract(_registry).name();
    }

    function tokenURI(address _registry, uint256 tokenId) public view returns (string memory){
        return NFTContract(_registry).tokenURI(tokenId);
    }

}