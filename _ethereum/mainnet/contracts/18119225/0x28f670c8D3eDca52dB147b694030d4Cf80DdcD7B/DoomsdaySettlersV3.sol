// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "./IERC721TokenReceiver.sol";
import "./IDoomsdaySettlersDarkAge.sol";
import "./IDoomsdaySettlersMetadata.sol";
import "./IDoomsdaySettlersBlacklist.sol";

contract DoomsdaySettlersV3 {

    struct Settlement{
        uint32 settleBlock;
        uint24 supplyAtMint;
        uint16 age;
        uint8 settlementType;
        uint80 relics;
        uint80 supplies;
    }

    uint80 constant CREATOR_PERCENT = 15;
    uint80 constant DESTRUCTION_FEE = 0.01 ether;
    uint80 constant DAMAGE_FEE      = 0.008 ether;
    uint80 constant REINFORCE_PERCENT_WINNER  = 85;
    uint80 constant REINFORCE_PERCENT_CREATOR = 15;
    uint256 constant BLOCK_TIME = 12 seconds;
    uint256 constant DISASTER_BLOCK_INTERVAL = 75;

    uint256 immutable BASE_DIFFICULTY;
    uint256 immutable DIFFICULTY_RAMP;
    uint256 immutable DIFFICULTY_COOLDOWN;
    uint256 immutable DIFFICULTY_COOLDOWN_SLOPE;
    address immutable DARK_AGE;
    uint256 immutable COLLAPSE_INITIAL;
    uint256 immutable COLLAPSE_RAMP;
    uint256 immutable COLLAPSE_MIN;



    uint16 age = 3;
    uint32 firstSettlement;

    uint32 abandoned;


    bool itIsTheDawnOfANewAge;

    address public owner;
    address creator;
    address confirmer;
    uint80 supplies;
    uint80 relics;

    uint80 mintFee;
    uint80 creatorEarnings;
    bytes32[] hashes;

    mapping( uint32 => Settlement) public settlements;

    event Settle(uint32 _tokenId, bytes32 _hash, address _settler, uint24 _newSupply, uint80 _newMintFee, uint32 _collapseBlock, uint8 _settlementType, address indexed _data, uint32 _blockNumber);
    event Abandon(uint32 indexed _tokenId, bytes32 _hash, uint80 _growth, uint24 _supplyAtMint, uint32 _newAbandoned, uint80 _newMintFee, uint80 _eth, uint32 _settled, bool _itIsTheDawnOfANewAge, uint32 _blockNumber);
    event Reinforce(uint32 indexed _tokenId, uint8 _type);
    event Disaster(uint32 indexed _tokenId, uint8 _type, bool _destroyed, bool _darkAgeOver);
    event Fund(uint amount);


    constructor(
        address _darkAge,
        uint256 _BASE_DIFFICULTY,
        uint256 _DIFFICULTY_RAMP,
        uint256 _DIFFICULTY_COOLDOWN,
        uint256 _DIFFICULTY_COOLDOWN_SLOPE,
        uint256 _COLLAPSE_INITIAL,
        uint256 _COLLAPSE_RAMP,
        uint256 _COLLAPSE_MIN
    ) payable {

        BASE_DIFFICULTY     = _BASE_DIFFICULTY;
        DIFFICULTY_RAMP     = _DIFFICULTY_RAMP;
        DIFFICULTY_COOLDOWN = _DIFFICULTY_COOLDOWN;
        DIFFICULTY_COOLDOWN_SLOPE = _DIFFICULTY_COOLDOWN_SLOPE;
        COLLAPSE_INITIAL    = _COLLAPSE_INITIAL;
        COLLAPSE_RAMP       = _COLLAPSE_RAMP;
        COLLAPSE_MIN        = _COLLAPSE_MIN;

        DARK_AGE = _darkAge;

        require(msg.value == DESTRUCTION_FEE,"destruction");

        // ERC165 stuff
        supportsInterface[0x80ac58cd] = true; //ERC721
        supportsInterface[0x5b5e139f] = true; //ERC721Metadata
        supportsInterface[0x01ffc9a7] = true; //ERC165

        owner = msg.sender;
        creator = msg.sender;

        bytes32 _hash = blockhash(block.number - 1);
        uint256 _settlementType = settlementType(_hash,0);

        _mint(1,msg.sender,_hash);

        settlements[1] = Settlement(uint32(block.number),0,age,uint8(_settlementType), 0,0);

        mintFee += uint80((uint88(2363029719748390562045450) >> _settlementType * 9)%uint88(512))  * uint80(0.000002 ether);
        firstSettlement = 1;
    }

    receive() external payable{
        require(address(this).balance < type(uint80).max,"balance overflow");
        relics += uint80(msg.value);
        emit Fund(msg.value);
    }


    function _settle(uint32 tokenId, bytes32 _hash, uint32 index, uint supply, uint32 collapseBlock, address data) internal returns(uint cost){

        cost = uint256(mintFee) + DESTRUCTION_FEE;
        uint80 creatorFee = uint80(cost * CREATOR_PERCENT / 100);
        creatorEarnings += creatorFee;
        cost += creatorFee;

        bytes32 hash = keccak256(abi.encodePacked(
                _hash,
                index
            ));

        uint8 _settlementType = uint8(settlementType(hash,supply));

        hash = keccak256(abi.encodePacked(hash,block.prevrandao));

        settlements[tokenId] = Settlement( uint32(block.number), uint24(supply), age, _settlementType, 0, 0);

        relics += mintFee/2;

        mintFee +=    uint80((uint88(2363029719748390562045450) >> _settlementType * 9)%uint88(512))  * uint80(0.000002 ether);

        _mint(tokenId,msg.sender,hash);

        emit Settle(tokenId, hash, msg.sender, uint24(supply + 1), mintFee, collapseBlock, _settlementType,  data, uint32(block.number));

        return cost;

    }

    function settle(uint256 location, uint8 count, address data) external payable {
        require(!isDarkAge(),"dark age");
        require(count != 0,"count min");
        require(count <= 20,"count max");

        unchecked{
            require(address(this).balance < type(uint80).max,"balance overflow");

            uint32 tokenId = uint32(hashes.length + 1);

            if(itIsTheDawnOfANewAge){
                ++age;
                firstSettlement = tokenId;
                itIsTheDawnOfANewAge = false;
            }

    //        uint256 supply = (hashes.length - destroyed.length - abandoned);
            uint256 supply = (hashes.length - abandoned);
            uint256 difficulty = BASE_DIFFICULTY - (DIFFICULTY_RAMP * supply);
            uint256 lastSettleBlock = settlements[uint32(hashes.length )].settleBlock;

            require(block.number > lastSettleBlock,"lastSettleBlock");
            uint256 blockDif = (block.number - lastSettleBlock);

            if(blockDif < DIFFICULTY_COOLDOWN){
                difficulty /= DIFFICULTY_COOLDOWN_SLOPE * (DIFFICULTY_COOLDOWN - blockDif);
            }

            bytes32 hash = keccak256(abi.encodePacked(
                    msg.sender,
                    hashes[hashes.length - 1],
                    location
                ));

            require(uint256(hash) < difficulty,"difficulty");

            uint32 collapseBlock;
            if((supply + count) * COLLAPSE_RAMP <  COLLAPSE_INITIAL - COLLAPSE_MIN){
                collapseBlock = uint32(block.number + (COLLAPSE_INITIAL - (supply + count) * COLLAPSE_RAMP) / BLOCK_TIME);
            } else{
                collapseBlock = uint32(block.number + COLLAPSE_MIN / BLOCK_TIME);
            }

            uint256 cost;
            for(uint32 i = 0; i < uint32(count); ++i){
                cost += _settle(tokenId + i, hash,i,supply + i,collapseBlock,data);
            }

            require(msg.value >= cost,"cost");
            require(gasleft() > 10000,"gas");
            if(msg.value > cost){
                payable(msg.sender).transfer(msg.value - cost);
            }
        }
    }

    function abandon(uint32[] calldata _tokenIds, uint32 _data) external {
        unchecked{
            require(_tokenIds.length != 0,"tokenIds");
            uint256 total;
            for(uint256 i = 0; i < _tokenIds.length; ++i){
                total += _abandon(_tokenIds[i],_data);
            }
            payable(msg.sender).transfer(total);
        }
    }

    function confirmDisaster(uint32 _tokenId, uint32 _data) external {
        require(isDarkAge(),"dark age");
        require(_isValidToken(_tokenId),"invalid");
        uint256 eliminationWindow = (block.number % DISASTER_BLOCK_INTERVAL);


        if(eliminationWindow < 20){
            require(msg.sender == ownerOf(_tokenId),"owner");
        }else if(eliminationWindow < 40){
            require(msg.sender == ownerOf(_tokenId)
                || msg.sender == confirmer
            ,"sender");
        }else if(eliminationWindow < 60){
            require(balanceOf[msg.sender] != 0,"balance");
        }

        uint8 _type;
        bool _destroyed;

        uint minted = hashes.length;
//        uint supply = minted - destroyed.length - abandoned;
        uint supply = minted - abandoned;

        unchecked{
            (_type, _destroyed) =
            IDoomsdaySettlersDarkAge(DARK_AGE).disaster(_tokenId, supply);
        }

        bool darkAgeOver = false;
        uint80 disaster_fee;

        if(_destroyed){
            unchecked{
                uint80 tokenFee = uint80((uint88(2363029719748390562045450) >> settlements[_tokenId].settlementType * 9)%uint88(512))  * uint80(0.000002 ether);
                uint80 growth;
                if(_tokenId >= firstSettlement){
                    growth = uint80(minted - _tokenId);
                }else{
                    growth = uint80(minted - firstSettlement) + 1;
                }
                uint80 _relics = growth * tokenFee;

                relics += _relics/2 +
                settlements[_tokenId].relics +
                settlements[_tokenId].supplies +
                IDoomsdaySettlersDarkAge(DARK_AGE).getUnusedFees(_tokenId) * DAMAGE_FEE;

    //            destroyed.push(_tokenId);
                ++abandoned;

                _burn(_tokenId);
                --supply;

                if(supply == 1){
                    _processWinner(_data);
                    darkAgeOver = true;
                }
            }

            disaster_fee = DESTRUCTION_FEE;
        }else{
            disaster_fee = DAMAGE_FEE;
        }

        emit Disaster(_tokenId,_type, _destroyed, darkAgeOver);
        payable(msg.sender).transfer(disaster_fee);
    }

    function reinforce(uint32 _tokenId, bool[4] memory _resources) external payable{
        require(msg.sender == ownerOf(_tokenId),"ownerOf");
        unchecked{
            require(address(this).balance < type(uint80).max,"balance overflow");
            uint80 cost = IDoomsdaySettlersDarkAge(DARK_AGE).reinforce(
                _tokenId,
                hashOf(_tokenId),
                _resources,
                isDarkAge()
            );
            uint80 total;
            for(uint256 i = 0; i < 4; ++i){
                if(_resources[i]){
                    total += DAMAGE_FEE;
                    emit Reinforce(_tokenId,uint8(i));
                }
            }
            require(total != 0,"empty");

            cost *= mintFee / uint80(4);
            total += cost;

            require(total <= msg.value,"msg.value");

            creatorEarnings += cost * REINFORCE_PERCENT_CREATOR / 100;
            supplies        += cost * REINFORCE_PERCENT_WINNER  / 100;

            require(gasleft() > 10000,"gas");
            if(msg.value > total){
                payable(msg.sender).transfer(msg.value - total);
            }
        }
    }

    function miningState() external view returns(
        bytes32 _lastHash,
        uint32 _settled,
        uint32 _abandoned,
        uint32 _lastSettleBlock,
        uint32 _collapseBlock,
        uint80 _mintFee,
        uint256 _blockNumber
    ){
        unchecked{

            uint256 collapseBlock = settlements[uint32(hashes.length )].settleBlock;
            uint32 collapseSupply = settlements[uint32(hashes.length)].supplyAtMint + 1;

            if(collapseSupply * COLLAPSE_RAMP <  COLLAPSE_INITIAL - COLLAPSE_MIN){
                collapseBlock += ( COLLAPSE_INITIAL - collapseSupply * COLLAPSE_RAMP ) / BLOCK_TIME;
            } else{
                collapseBlock +=  COLLAPSE_MIN / BLOCK_TIME;
            }
            return (
            hashes[hashes.length - 1],
            uint32(hashes.length),
    //        uint32(destroyed.length) + abandoned,
            abandoned,
            settlements[uint32(hashes.length)].settleBlock,
            uint32(collapseBlock),
            mintFee,
            block.number
            );
        }

    }

    function currentState() external view returns(
        bool _itIsTheDawnOfANewAge,
        uint32 _firstSettlement,
        uint16 _age,
        uint80 _creatorEarnings,
        uint80 _relics,
        uint80 _supplies,
        address _creator,
        uint256 _blockNumber
    ){
        return (
        itIsTheDawnOfANewAge,
        firstSettlement,
        age,
        creatorEarnings,
        relics,
        supplies,
        creator,
        block.number
        );
    }


    function settlementType(bytes32 hash, uint256 _supplyAtMint) private pure returns(uint256){
        unchecked{
            uint256 settlementTypeMax = _supplyAtMint / 450 + 2 ;
            if(settlementTypeMax > 8) settlementTypeMax = 8;
            return (uint256(hash)%100)**2 * ( settlementTypeMax + 1 ) / 1_00_00;
        }
    }

    function isDarkAge() public view returns(bool){
        unchecked{
            uint minted = hashes.length;
    //        uint256 supply = (minted - destroyed.length - abandoned);
            uint256 supply = (minted - abandoned);
            uint256 collapseBlock = settlements[uint32(minted)].settleBlock;
            uint32 collapseSupply = settlements[uint32(minted)].supplyAtMint + 1;

            if(collapseSupply * COLLAPSE_RAMP <  COLLAPSE_INITIAL - COLLAPSE_MIN){
                collapseBlock += ( COLLAPSE_INITIAL - collapseSupply * COLLAPSE_RAMP ) / BLOCK_TIME;
            } else{
                collapseBlock +=  COLLAPSE_MIN / BLOCK_TIME;
            }
            return supply > 1 && (block.number > collapseBlock );
        }
    }


    function hashOf(uint32 _tokenId) public view returns(bytes32){
        require(_isValidToken(_tokenId),"invalid");
        unchecked{
            return hashes[_tokenId - 1];
        }
    }


    function _processWinner(uint32 _winner) private{
        require(_isValidToken(_winner),"invalid");
        unchecked{
            settlements[_winner].relics     += relics;
            settlements[_winner].supplies   += supplies;

            uint80 tokenFee = uint80((uint88(2363029719748390562045450) >> settlements[_winner].settlementType * 9)%uint88(512))  * uint80(0.000002 ether);
            uint80 growth;
            if(_winner > firstSettlement){
                growth = uint80(hashes.length) - uint80(_winner);
            }else{
                growth = (uint80(hashes.length) - uint80(firstSettlement)) + 1;
            }
            uint80 _relics = growth * tokenFee;
            settlements[_winner].relics += _relics / 2;
            relics = 0;
            supplies = 0;
            mintFee = tokenFee;
            itIsTheDawnOfANewAge = true;
        }
    }

    function _abandon(uint32 _tokenId, uint32 _data) private returns(uint256){
        unchecked{
            require(msg.sender == ownerOf(_tokenId),"ownerOf");
            bytes32 hash = hashes[_tokenId - 1];
            uint80 growth;
            if(_tokenId >= firstSettlement){
                growth = uint80(hashes.length - _tokenId);
            }else{
                growth = uint80(hashes.length) - uint80(firstSettlement) + 1;
            }
            uint80 _relics;
            if(!itIsTheDawnOfANewAge){
                _relics = growth * uint80((uint88(2363029719748390562045450) >> settlements[_tokenId].settlementType * 9)%uint88(512))  * uint80(0.000002 ether);
            }

            bool _isDarkAge = isDarkAge();
            if(_isDarkAge){
                require(!IDoomsdaySettlersDarkAge(DARK_AGE).checkVulnerable(_tokenId),"vulnerable");
                _relics /= 2;
                uint __abandoned;
                uint __settled;

                if(age > 3){
                    ++__abandoned;
                    ++__settled;
                }

    //            __abandoned += uint80(destroyed.length + abandoned) - (uint80(firstSettlement) - 1);
                __abandoned += uint(abandoned) - (uint(firstSettlement) - 1);
                __settled   += hashes.length - (uint(firstSettlement) - 1);

    //            uint80 spoils = uint80 ( uint(relics) / (hashes.length - destroyed.length - uint(abandoned))
                uint80 spoils = uint80 ( uint(relics) / (hashes.length - uint(abandoned))
                            * (10_000_000_000 + ( 30_000_000_000 * __abandoned / __settled  ))  / 40_000_000_000 );



                _relics += spoils;
                relics -= spoils;
            }else if(!itIsTheDawnOfANewAge){
                relics -= _relics / 2;
                mintFee -= uint80((uint88(2363029719748390562045450) >> settlements[_tokenId].settlementType * 9)%uint88(512))  * uint80(0.000002 ether);
            }

            ++abandoned;
            _relics +=
                DESTRUCTION_FEE + IDoomsdaySettlersDarkAge(DARK_AGE).getUnusedFees(_tokenId) * DAMAGE_FEE
                + settlements[_tokenId].relics
                + settlements[_tokenId].supplies;

            _burn(_tokenId);
            if(_isDarkAge){
    //            if(hashes.length - destroyed.length - abandoned == 1){
                if(hashes.length - abandoned == 1){
                    _processWinner(_data);
                }
            }
            emit Abandon(
                _tokenId,
                hash,
                growth,
                settlements[_tokenId].supplyAtMint,
    //            uint32(destroyed.length) + abandoned,
                abandoned,
                mintFee,
                _relics,
                uint32(hashes.length),
                itIsTheDawnOfANewAge,
                uint32(block.number)
            );
            return _relics;
        }
    }



    //////===721 Standard
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //////===721 Implementation

    mapping(address => uint256) public balanceOf;
    mapping (uint256 => address) internal allowance;
    mapping (address => mapping (address => bool)) public isApprovedForAll;

    mapping(uint256 => address) owners;

    //    METADATA VARS
    string constant public name = "Doomsday: Settlers of the Wasteland";
    string constant public symbol = "SETTLEMENT";

    address private __metadata;
    function _mint(uint256 _tokenId,address _to, bytes32 _hash) private{
        unchecked{
            owners[_tokenId] = msg.sender;
            ++balanceOf[_to];
            hashes.push(_hash);
            emit Transfer(address(0),_to,_tokenId);
        }
    }
    function _burn(uint256 _tokenId) private{
        unchecked{
            address _owner = owners[_tokenId];
            --balanceOf[ _owner ];
            delete owners[_tokenId];
            emit Transfer(_owner,address(0),_tokenId);
        }
    }

    function _isValidToken(uint256 _tokenId) internal view returns(bool){
        return owners[_tokenId] != address(0);
    }

    function ownerOf(uint256 _tokenId) public view returns(address){
        require(_isValidToken(_tokenId),"invalid");
        return owners[_tokenId];
    }

    function approve(address _approved, uint256 _tokenId)  external{
        _noBlocked(_approved);

        address _owner = ownerOf(_tokenId);
        require( _owner == msg.sender
            || isApprovedForAll[_owner][msg.sender]
        ,"permission");
        emit Approval(_owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_isValidToken(_tokenId),"invalid");
        return allowance[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        _noBlocked(_operator);
        emit ApprovalForAll(msg.sender,_operator, _approved);
        isApprovedForAll[msg.sender][_operator] = _approved;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        address _owner = ownerOf(_tokenId);
        if(isDarkAge()){
            require(!IDoomsdaySettlersDarkAge(DARK_AGE).checkVulnerable(uint32(_tokenId)),"vulnerable");
        }
        if(_from != msg.sender){
            _noBlocked(msg.sender);
        }

        require ( _owner == msg.sender
            || allowance[_tokenId] == msg.sender
            || isApprovedForAll[_owner][msg.sender]
        ,"permission");

        require(_owner == _from,"owner");
        require(_to != address(0),"zero");

        emit Transfer(_from, _to, _tokenId);
        owners[_tokenId] =_to;
        --balanceOf[_from];
        ++balanceOf[_to];

        if(allowance[_tokenId] != address(0)){
            delete allowance[_tokenId];
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        transferFrom(_from, _to, _tokenId);

        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size != 0){
//        if(address(_to).code.length != 0){

            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(0x150b7a02),"receiver");
        }


    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from,_to,_tokenId,"");
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory){
        ownerOf(_tokenId);
        return IDoomsdaySettlersMetadata(__metadata).tokenURI(
            _tokenId
        );
    }

    function totalSupply() external view returns (uint256){
        unchecked{
    //        return hashes.length - destroyed.length - abandoned;
            return hashes.length - abandoned;
        }
    }
    ///==End 721

    ///////===165 Implementation
    mapping (bytes4 => bool) public supportsInterface;
    ///==End 165

    //// ==== Admin
    function _onlyOwner() private view{
        require(msg.sender == owner,"owner");
    }
    function _onlyCreator() private view{
        require(msg.sender == creator,"creator");
    }

    function setOwner(address newOwner) external  {
        _onlyOwner();
        owner = newOwner;
    }

    function setMetadata(address _metadata) external {
        _onlyOwner();
        __metadata = _metadata;
    }

    function creatorWithdraw() external {
        _onlyCreator();
        uint256 toWithdraw = creatorEarnings;
        delete creatorEarnings;
        payable(msg.sender).transfer(toWithdraw);
    }

    function setCreator(address newCreator) external {
        _onlyCreator();
        creator = newCreator;
    }

    function setConfirmer(address _newConfirmer) external{
        _onlyOwner();
        confirmer = _newConfirmer;
    }

    //OPERATOR FILTER
    IDoomsdaySettlersBlacklist blacklist;
    function _noBlocked(address _addr) private view{
        unchecked{

            uint32 size;
            address _blacklist = address(blacklist);
            assembly {
                size := extcodesize(_blacklist)
            }
            if(size != 0){
//            if (address(blacklist).code.length != 0) {
                try blacklist.checkBlocked(_addr) returns (bool result){
                    require(!result,"blocked");
                } catch {
                    //External error, let them cook
                }
            }
        }
    }

    function setBlacklist(address _newBlacklist) external{
        _onlyOwner();
        blacklist = IDoomsdaySettlersBlacklist(_newBlacklist);
    }



}