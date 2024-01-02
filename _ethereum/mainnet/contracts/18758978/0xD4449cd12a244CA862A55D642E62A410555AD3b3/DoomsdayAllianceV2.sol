// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "./ISettlersAlliedV2.sol";
import "./IBatcher.sol";

contract DoomsdayAllianceV2{
    ISettlersAlliedV2 immutable settlers;
    IBatcher immutable batcher;

    receive() external payable{
        if(
            msg.sender != address(settlers) &&
            msg.sender != address(batcher)
        ){
            payable(msg.sender).transfer(msg.value);
        }
    }

    event Fund(address indexed _funder, uint value);
    event Contribute(address indexed _contributor, uint _tokenId);
    event Member(address indexed _member);
    event Leader(address indexed _leader, bool promoted);

    string public name;
    string public symbol;

    uint16 immutable age;
    mapping(address => bool) members;
    mapping(address => bool) leaders;
    address[] public memberList;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    uint public constant decimals = 18;
    uint80 constant PRICE_MIN   = 0.0148 ether;
    uint80 constant CREATOR_MIN = 0.0052 ether;
    uint80 constant LATEST_FEE  = 0.01 ether;
    uint80 constant CREATOR_PERCENT = 15;
    uint80 constant DESTRUCTION_FEE = 0.01 ether;


    uint immutable settlementValue;
    bool winningTokenBurned;
    address acquired;
    address[] pricesSet;
    mapping(address => uint) acquisitionPrices;

    function data() public view returns(
        uint _settlementValue,
        bool _winningTokenBurned,
        address _acquired,
        Contribution _contribution,
        uint _acquisitionPrice,
        uint16 _age
    ){
        return (
            settlementValue,
            winningTokenBurned,
            acquired,
            contribution,
            getAcquisitionPrice(),
            age
        );
    }

    function memberData(address _address) public view returns (
        bool _member,
        bool _leader,
        uint _acquisitionPrice
    ){
        return (
            members[_address],
            leaders[_address],
            acquisitionPrices[_address]
        );
    }

    enum Contribution{PRIVATE,FUNDING,SETTLEMENTS}
    Contribution immutable contribution;

    constructor(address _settlers, address _batcher, uint _settlementValue, string memory _name, string memory _symbol, Contribution _contribution, uint16 _age , address _founder){
        settlers = ISettlersAlliedV2(_settlers);
        batcher = IBatcher(_batcher);
        settlementValue = _settlementValue;

        settlers.setApprovalForAll(_batcher,true);

        name = _name;
        symbol = _symbol;

        contribution = _contribution;

        age = _age;

        members[_founder] = true;
        leaders[_founder] = true;
        memberList.push(_founder);


        emit Member(_founder);
        emit Leader(_founder,true);
    }

    function initialShares(address _founder, uint value) external{
        require(totalSupply == 0,"has value");

        totalSupply = value;
        balanceOf[_founder] = value;
        emit Transfer(address(0),_founder,value);

    }

    modifier onlyLeader(){
        require(leaders[msg.sender],"leader");
        _;
    }
    modifier onlyMember(){
        require(members[msg.sender],"member");
        _;
    }

    function requireGameOver(bool _isOver) internal view{
        (
            bool _itIsTheDawnOfANewAge,
            uint32 _firstSettlement,
            uint16 _age,
            uint80 _creatorEarnings,
            uint80 _relics,
            uint80 _supplies,
            address _creator,
            uint256 _blockNumber
        ) = settlers.currentState();

        _firstSettlement;
        _creatorEarnings;
        _relics;
        _supplies;
        _creator;
        _blockNumber;

        require(
            (!_itIsTheDawnOfANewAge && _age == age)
                != _isOver
            ,"game over");
    }

    modifier notAcquired(){
        require(acquired == address(0),"acquired");
        _;
    }

    modifier canContribute(bool _isSettlement){
        if(!members[msg.sender]){
            if(contribution == Contribution.PRIVATE){
                revert("private");
            }else if(contribution == Contribution.FUNDING){
                require(!_isSettlement,"contribution");
            }
        }
        _;
    }


    function addMember(address _member) public onlyLeader{
        members[_member] = true;
        memberList.push(_member);

        emit Member(_member);
    }
    function promoteMember(address _member, bool _promote) public onlyLeader{
        require(members[_member],"member");
        require(_member != msg.sender,"self");
        leaders[_member] = _promote;

        emit Leader(_member,_promote);
    }

    function getMintCost() internal view returns(uint80){
        (
            bytes32 _lastHash,
            uint32 _settled,
            uint32 _abandoned,
            uint32 _lastSettleBlock,
            uint32 _collapseBlock,
            uint80 _mintFee,
            uint256 _blockNumber
        ) = settlers.miningState();

        _lastHash;
        _settled;
        _abandoned;
        _lastSettleBlock;
        _collapseBlock;
        _blockNumber;

        if(_mintFee < PRICE_MIN){
            return 0.04 ether;
        }else{
            uint80 cost = _mintFee + DESTRUCTION_FEE + LATEST_FEE;
            uint80 creatorFee = cost * CREATOR_PERCENT / 100;
            cost += creatorFee;
            return cost;
//            return uint80( )
//            return uint80((uint(_mintFee) + uint(0.01 ether)) * 115 / 100);
        }

//        unchecked{
//            return uint80((uint(_mintFee) + uint(0.01 ether)) * 115 / 100);
//        }
    }

    function addSettlements(uint[] calldata _tokenIds) public canContribute(true) notAcquired {
//        unchecked{
            requireGameOver(false);
            uint _shareValue;
            if(settlementValue == 0){
                //get mint cost
                _shareValue = getMintCost() * _tokenIds.length;
            }else{
                _shareValue = settlementValue * _tokenIds.length;
            }

            for(uint i = 0; i < _tokenIds.length; i++){
                settlers.transferFrom(msg.sender,address(this),_tokenIds[i]);
                emit Contribute(msg.sender,_tokenIds[i]);
            }

            totalSupply += _shareValue;
            balanceOf[msg.sender] += _shareValue;
            emit Transfer(address(0),msg.sender,_shareValue);
//        }
    }

    function fundAlliance() public payable canContribute(false) notAcquired{
//        unchecked{
            requireGameOver(false);
            totalSupply += msg.value;
            balanceOf[msg.sender] += msg.value;

            emit Fund(msg.sender,msg.value);
            emit Transfer(address(0),msg.sender,msg.value);
//        }
    }

//    function reinforce(uint32 _tokenId, bool[4] calldata _resources, uint _cost) external payable onlyMember{
//        if(msg.value > 0){
//            fundAlliance();
//        }
//        settlers.reinforce{value:_cost}(_tokenId,_resources);
//    }
    function multiTokenReinforce(uint32[] memory _tokenIds, uint80[4][] memory _currentLevels, uint80[4][] memory _extraLevels, uint8[] memory _highest, uint80 _baseCost, uint _cost) external payable onlyMember notAcquired{
        if(msg.value > 0){
            fundAlliance();
        }
        batcher.multiTokenReinforce{value:_cost}(_tokenIds, _currentLevels, _extraLevels, _highest, _baseCost);
    }
//    function multiLevelReinforce(uint32 _tokenId, uint80[4] memory _currentLevels, uint80[4] memory _extraLevels, uint80 _highest, uint80 _baseCost, uint _cost) external payable onlyMember notAcquired{
//        if(msg.value > 0){
//            fundAlliance();
//        }
//        batcher.multiLevelReinforce{value:_cost}(_tokenId, _currentLevels, _extraLevels, _highest, _baseCost);
//    }

    function setAcquisitionPrice(uint _price) public onlyMember{
        require(_price > 0,"zero");
        if(acquisitionPrices[msg.sender] == 0){
            pricesSet.push(msg.sender);
        }
        acquisitionPrices[msg.sender] = _price;
    }
    function getAcquisitionPrice() internal view returns(uint){
//        unchecked{
            uint _max;
            for(uint i = 0; i < pricesSet.length; i++){
                uint _price = acquisitionPrices[pricesSet[i]];
                if(_price > _max){
                    _max = _price;
                }
            }
            return _max;
//        }
    }


    function acquire() notAcquired payable external{
//        unchecked{
            requireGameOver(false);
            require(pricesSet.length > 0,"no price");
            require(msg.value == getAcquisitionPrice(),"msg.value");
            acquired = msg.sender;

            (
                bool _itIsTheDawnOfANewAge,
                uint32 _firstSettlement,
                uint16 _age,
                uint80 _creatorEarnings,
                uint80 _relics,
                uint80 _supplies,
                address _creator,
                uint256 _blockNumber
            ) = settlers.currentState();

            _itIsTheDawnOfANewAge;
            _firstSettlement;
            _age;
            _creatorEarnings;
            _relics;
            _supplies;
            _blockNumber;


            payable(_creator).transfer(msg.value * 5 / 100);

//        }
    }
    function removeTokens(uint[] calldata _tokenIds) public{
//        unchecked{
            require(msg.sender == acquired,"sender");
            for(uint i = 0; i < _tokenIds.length; i++){
                settlers.transferFrom(
                    address(this),
                    msg.sender,
                    _tokenIds[i]
                );
            }
//        }
    }

    function abandonWinningToken(uint32 _tokenId,uint32 _data) public onlyMember notAcquired{
        (
//            uint32 _settleBlock,
            uint24 supplyAtMint,
            uint16 _age,
            uint8 settlementType,
            uint80 relics,
            uint80 supplies
        ) = settlers.settlements(_tokenId);

//        _settleBlock;
        supplyAtMint;
        _age;
        settlementType;

        require (supplies > 0 || relics > 0,"victory");


        uint32[] memory _tokenIds = new uint32[](   1   );
        _tokenIds[0] = _tokenId;

        settlers.abandon(_tokenIds,_data);
    }

    function cashOut() public {
//        unchecked{
            if(acquired == address(0)){
                requireGameOver(true);
            }

            uint _balanceOf = balanceOf[msg.sender];
            require(_balanceOf > 0,"share count");

            uint _payout = address(this).balance * _balanceOf / totalSupply;

            delete balanceOf[msg.sender];
            totalSupply -= _balanceOf;

    //        if(_payout > address(this).balance){
    //            _payout = address(this).balance;
    //        }

            emit Transfer(msg.sender,address(0),_payout);
            payable(msg.sender).transfer(_payout);

//        }
    }

    function confirmDisaster(uint32 _tokenId, uint32 _data, uint _data2) public onlyMember notAcquired{
        settlers.confirmDisaster(_tokenId,_data,_data2);
        try settlers.ownerOf(_tokenId) returns (address _owner){
            //Still alive
            _owner;
            payable(msg.sender).transfer(0.008 ether);
        }catch{
            //Destroyed
            payable(msg.sender).transfer(0.01 ether);
        }
    }


    // ERC20
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => mapping(address => uint)) public allowance;

    function transfer(address _to, uint256 _value) public returns (bool success){
        _transferFrom(msg.sender,_to,_value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(msg.sender == _from || allowance[_from][msg.sender] >= _value,"permission");
        if(_from != msg.sender){
            allowance[_from][msg.sender] -= _value;
        }
        _transferFrom(_from,_to,_value);
        return true;
    }
    function _transferFrom(address _from, address _to, uint256 _value) private{
        require(balanceOf[_from] >= _value,"balance");
        require(_to != address(0),"zero");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from,_to,_value);
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}