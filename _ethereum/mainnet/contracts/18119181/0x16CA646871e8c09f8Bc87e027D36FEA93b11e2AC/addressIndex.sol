// SPDX-License-Identifier: MIT
// XEN Contracts v0.6.0
pragma solidity ^0.8.13;

import {_CJeffBaseOwnerShip}                    from '../base/jeffBaseOwnerShip.sol';

//index 1 부터 시작 함
contract CAddressIndexing is _CJeffBaseOwnerShip {

    uint256                         internal _mIndexSize;
    mapping(address => uint256)     internal _mAddress;
    mapping(uint256 => address)     internal _mIndex;

    constructor() {
        _mIndexSize = 1;
    }

    function _addIndex( address account ) internal returns(bool res){
      assembly {
        function getSlotAddress(acc) -> a {
            mstore(0, acc)
            mstore(32, _mAddress.slot)
            a := keccak256(0, 64)
        }
        function getSlotIndex(idx) -> a {
            mstore(0, idx)
            mstore(32, _mIndex.slot)
            a := keccak256(0, 64)
        }            

        let slotAccount   := getSlotAddress( account )
        let slotIndexSize := _mIndexSize.slot

        let accountIndex  := sload(slotAccount) 
        let indexSize     := sload(slotIndexSize)

        if or( eq(indexSize, 1), iszero( accountIndex )) {
          let slotIndex := getSlotIndex(indexSize)
          sstore(slotAccount, indexSize)
          sstore(slotIndex, account)
          sstore(slotIndexSize, add(indexSize,1))
          res := 1
        }
      }
      return res;
    }    
    
    function _removeIndex( address account ) internal {
      assembly {
        function getSlotAddress(acc) -> a {
            mstore(0, acc)
            mstore(32, _mAddress.slot)
            a := keccak256(0, 64)
        }
        function getSlotIndex(idx) -> a {
            mstore(0, idx)
            mstore(32, _mIndex.slot)
            a := keccak256(0, 64)
        }        

        let slotIndexSize := _mIndexSize.slot
        let indexSize     := sload(slotIndexSize)

        let slotAccount   := getSlotAddress( account )
        let accountIndex  := sload(slotAccount) 

        let lastIdx       := sub( indexSize, 1 )
        let slotLastIndex := getSlotIndex(lastIdx)

        if gt( accountIndex, 0 ) {
          switch eq( lastIdx, accountIndex ) 
          case 0 {
            let slotIndex := getSlotIndex(accountIndex)
            let lastAddress := sload(slotLastIndex)
            sstore( slotIndex, lastAddress )
            
            let slotLastAddress := getSlotAddress( lastAddress )
            sstore( slotLastAddress, accountIndex )
          }
          sstore( slotAccount, 0 )
          sstore( slotLastIndex, 0 )
          sstore( slotIndexSize, lastIdx )
        }
      }
    }

    function _getIndex( address val ) internal view returns( uint256 ){
        return _mAddress[ val ];
    }

    //index: 1부터 시작
    function _getAddress( uint256 index ) internal view returns( address ){
        return _mIndex[index];
    }

    function _getIndexedSize() internal view returns( uint256 ) {
        return _mIndexSize -1;
    }

    ////////////////////////////////////////////////////////////////////////////////
    //public
    function addIndex( address val ) public onlyOwner returns(bool) {
        return _addIndex( val );
    }
    
    function removeIndex( address val ) public onlyOwner {
        _removeIndex( val );
    }

    function getIndex( address val ) public view returns( uint256 ){
        return _getIndex( val );
    }

    function getAddress( uint256 index ) public view returns( address ){
        return _getAddress( index );
    }

    function getIndexedSize() public view returns( uint256 ) {
        return _getIndexedSize();
    }

}