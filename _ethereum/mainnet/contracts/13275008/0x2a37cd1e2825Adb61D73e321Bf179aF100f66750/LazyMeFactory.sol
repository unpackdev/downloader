// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./LazyMe.sol";
import "./LootBoxRandomness.sol";

contract LazyMeFactory is FactoryERC721, Ownable, Factory, ReentrancyGuard {
    using LootBoxRandomness for LootBoxRandomness.LootBoxRandomnessState;
    using Strings for string;

    LootBoxRandomness.LootBoxRandomnessState state;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    address public creatureAddress;
    address private ramdomAddress;
    string public baseURI;

    mapping (uint256 => uint256) public _boxMap;
    mapping (uint256=> uint256) public _supplyMap;

    uint256 BOX_MAX_NUM = 1;
    uint256 NUM_OPTIONS = 4;

    mapping (uint256 => bool) public _pauseSale;

    constructor(address _proxyRegistryAddress, address _creatureAddress, address _ramdomAddress, string memory _baseURI) {
        proxyRegistryAddress = _proxyRegistryAddress;
        baseURI = _baseURI;
        creatureAddress = _creatureAddress;
        ramdomAddress = _ramdomAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() external pure override returns (string memory) {
        return "LazyMe Lootbox";
    }

    function symbol() external pure override returns (string memory) {
        return "LAZY_FAC";
    }

    function supportsFactoryInterface() public pure override returns (bool) {
        return true;
    }

    function numOptions() public view override returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setCreatureAddress(address _creatureAddress) public onlyOwner {
        creatureAddress = _creatureAddress;
    }

    function setBoxMaxNum(uint256 _boxNum) public onlyOwner {
        BOX_MAX_NUM = _boxNum;
    }

    function setPauseSale(uint256 _optionId, bool _isPause) public onlyOwner {
        _pauseSale[_optionId] = _isPause;
    }

    function getPauseSale(uint256 _optionId) public view onlyOwner returns (bool pauseSale){
        return _pauseSale[_optionId];
    }

    function setBoxNum(uint256 _optionId, uint256 _boxnum) public onlyOwner {
        _boxMap[_optionId] = _boxnum;
    }

    function getBoxNum(uint256 _optionId) public view onlyOwner returns (uint256 _boxnum){
        return _boxMap[_optionId];
    }

    function setSupplyLimit(uint256 _boxnum, uint256 amount) public onlyOwner {
        _supplyMap[_boxnum] = amount;
    }

    function getSupplyLimit(uint256 _boxnum) public view onlyOwner returns (uint256 amount){
        return _supplyMap[_boxnum];
    }

    function mint(uint256 _optionId, address _toAddress) public override nonReentrant(){
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert( address(proxyRegistry.proxies(owner())) == _msgSender() || owner() == _msgSender());

        uint256 _tokenId;
        uint256 _classId;
        uint256 _boxnum = _boxMap[_optionId];

        require(!_pauseSale[_optionId],"This optionID is Pause sale");
        
        if(_optionId == 0) {
            require(canMint(_boxnum, 1),"CreatureFactory#_mint: CANNOT_MINT_MORE");
            (_tokenId, _classId) = LootBoxRandomness._normalMint(state, _optionId , _boxnum);
            mintItem(_boxnum, _tokenId, _toAddress, _classId);
        } else {
            speacialMint(_optionId, _toAddress);
        }
    }

    function speacialMint(uint256 _optionId, address _toAddress) private {
        uint256 _tokenId;
        uint256 _classId;
        uint256 _boxnum = _boxMap[_optionId];

        LootBoxRandomness.OptionSettings memory settings = state.optionToSettings[_optionId];
        uint256 amount = state.optionToSettings[_optionId].maxQuantityPerOpen;
        require(
            canMint(_boxnum, amount),
            "CreatureFactory#_mint: CANNOT_MINT_MORE"
        );

        uint256 guaranteeAmount = 0;
        for (uint256 randClassId = 0; randClassId < settings.guarantees.length; randClassId++) {
            uint256 quantityOfGuaranteed = settings.guarantees[randClassId];
            if (quantityOfGuaranteed > 0) {
                for (uint256 j = 0; j < quantityOfGuaranteed; j++) {
                    if(guaranteeAmount < amount) {
                        (_tokenId, _classId) = LootBoxRandomness._mint(state, _optionId, randClassId, true, _boxnum);
                        mintItem(_boxnum, _tokenId, _toAddress, _classId);
                        guaranteeAmount += 1;
                    }
                }
            }
        }

        for (uint256 randAmount = 0 + guaranteeAmount; randAmount < amount; randAmount++) {
                (_tokenId, _classId) = LootBoxRandomness._mint(state, _optionId, 0, false , _boxnum);
                mintItem(_boxnum, _tokenId, _toAddress, _classId);
        }
    }
    
    function mintBox(uint256 _optionId, address _toAddress) public onlyOwner {
        emit Transfer(address(0), _toAddress, _optionId);
    }

    function mintItem(uint256 _boxnum, uint256 _tokenId, address _toAddress, uint256 _classId) private {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert( address(proxyRegistry.proxies(owner())) == _msgSender() || owner() == _msgSender());
        require(
            canMint(_boxnum, 1),
            "CreatureFactory#_mint: CANNOT_MINT_MORE"
        );

        LazyMe lazyMeCreature = LazyMe(
            creatureAddress
        );
        lazyMeCreature.mintTo(_toAddress, _boxnum, _tokenId, _classId);
    }

    function balanceOf(uint256 _boxTokenId, uint256 _boxnum)
        public
        view
        override
        returns (bool)
    {
        LazyMe lazyMeCreature = LazyMe(
            creatureAddress
        );
        address owner = lazyMeCreature.checkOwnerOf(_boxnum, _boxTokenId);
        if(owner != address(0)){
            return false;
        } else {
            return true;
        }
    }
    
    function tokenURI(uint256 _optionId)
        external
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    function setState(
        address _factoryAddress,
        uint256 _numOptions,
        uint256 _numClasses,
        uint256 _numBox,
        uint256 _seed
    ) public onlyOwner {
        LootBoxRandomness.initState(
            state,
            _factoryAddress,
            _numOptions,
            _numClasses,
            _numBox,
            _seed
        );
    }

    function setTokenIdsForClass(uint256 _optionId, uint256 _classId, uint256 _tokenIds)
        public
        onlyOwner
    {
        LootBoxRandomness.setTokenIdsForClass(state, _optionId, _classId, _tokenIds);
    }

    function getQuantityPerOpen(
        uint256 _option
    ) public onlyOwner returns (uint256){
        return LootBoxRandomness.getQuantityPerOpen(
            state,
            _option
        );
    }

    function getQuantityGarantee(
        uint256 _option,
        uint256 classId
    ) public onlyOwner returns (uint256){
        return LootBoxRandomness.getQuantityGarantee(
            state,
            _option,
            classId
        );
    }

    function setOptionSettings(
        uint256 _option,
        uint256 _maxQuantityPerOpen,
        uint256[] memory _classProbabilities,
        uint256[] memory _guarantees
    ) public onlyOwner {
        LootBoxRandomness.setOptionSettings(
            state,
            _option,
            _maxQuantityPerOpen,
            _classProbabilities,
            _guarantees
        );
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    function canMint(uint256 _boxnum, uint256 _amount) public view override returns (bool) {
        if (_boxnum >= BOX_MAX_NUM) {
            return false;
        }

        uint256 _supplyMax = _supplyMap[_boxnum];

        LazyMe lazyMeCreature = LazyMe(
            creatureAddress
        );
        uint256 creatureSupply = lazyMeCreature.checkTotalSupply(_boxnum);

        return creatureSupply < ( _supplyMax - _amount);
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
