// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "./DoomsdayAllianceV2.sol";
import "./ISettlersAlliedV2.sol";

contract DoomsdayDiplomacyV2{


    address immutable settlers;
    address immutable batcher;
    constructor(address _settlers, address _batcher){
        settlers = _settlers;
        batcher = _batcher;
    }

    address[] public alliances;

    event CreateAlliance(string name, string symbol, uint settlementValue, address _address, address indexed creator, uint16 _age);

    function getAge() internal view returns(uint16){
        unchecked{
            (
            bool _itIsTheDawnOfANewAge,
            uint32 _firstSettlement,
            uint16 _age,
            uint80 _creatorEarnings,
            uint80 _relics,
            uint80 _supplies,
            address _creator,
            uint256 _blockNumber
            ) = ISettlersAlliedV2(settlers).currentState();

            _itIsTheDawnOfANewAge;
            _firstSettlement;
            _creatorEarnings;
            _relics;
            _supplies;
            _creator;
            _blockNumber;

            return _age;
        }
    }

    function createAlliance(uint _settlementValue, string memory _name, string memory _symbol, DoomsdayAllianceV2.Contribution _contribution) public returns(address){

        unchecked{
            require(keccak256(abi.encodePacked(_symbol))!=0x217fc9d4f07e3d0aaca833f6b7fc7bb8775a7042e43311edb5c9cc9cf369629d,"symbol");

            uint gasBefore = gasleft();

            uint16 _age = getAge();
            DoomsdayAllianceV2 alliance = new DoomsdayAllianceV2(settlers,batcher,_settlementValue,_name,_symbol,_contribution,_age, msg.sender);
            alliance.initialShares( msg.sender,(gasBefore - gasleft()) * tx.gasprice );

            emit CreateAlliance(_name, _symbol, _settlementValue,address(alliance),msg.sender,_age);

            alliances.push(address(alliance));

            return address(alliance);
        }

    }

}
