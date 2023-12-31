// SPDX-License-Identifier: MIT
// XEN Contracts v0.6.0
pragma solidity ^0.8.13;

import {_CReentrancyGuards}                     from '../security/reentrancyGuards.sol';
import {CAddressIndexing}                       from '../index/addressIndex.sol';
import {IQuorum}                                from './iQuorum.sol';

contract CQuorum is _CReentrancyGuards, IQuorum {

    uint256                                    private                 _idTracker;
    uint256                                    internal                _expirationPeriod;   //안건 유효 기간 (오늘 포함 된 기간)
    uint256                                    internal                _minimumMembers;     //최소 구성원 수
    CAddressIndexing                           internal                _memberIndex;
    mapping( uint256 => TDraftDoc )            internal                _doc;
    address                                    internal                _creator;

    event eventAddMember( address newMember );
    event eventRemoveMember( address member );
    event eventProposal( address drafter, uint256 docId, address toContract, bytes callData, bool invokable );
    event eventApproval( address approvor, uint256 docId, bool invokable );
    event eventCancel( uint256 docId );
    event eventInvoke( address sender, uint256 docId, bytes returnData );

    constructor() {
        _memberIndex        = new CAddressIndexing();
        _idTracker          = 1;  
        _expirationPeriod   = 3;    //3 days
        _minimumMembers     = 2;    //2 명
        _creator            = msg.sender;
    }

    modifier onlyMember() {
        if( _memberIndex.getIndexedSize() < _minimumMembers ) { //최소 맴버 인원을 충족하지 못 할 경우 contract owner만 호출 가능하다
            require( msg.sender == _creator, "onlyMember: If less than the minimum number of members, caller must be a contract owner");
        } else {
            require( _memberIndex.getIndex( msg.sender ) > 0, "onlyMember: caller is not member");
        }
        _;
    }

    modifier onlyQuorum( uint256 docId ) {
        /*
            승인된 후 invoke 호출한적이 없어야 야 한다.
            기안작성자가 invoke를 호출 하여야 한다.
            기안작성일로 부터 3일 이내에 호출되어야 한다.
            2명 미만 인경우 contract 생성자만 호출 가능
        */
        require( !_doc[ docId ].cancellation, "onlyQuorum: cancelled");
        require( !_doc[ docId ].invoked, "onlyQuorum: already invoked");
        require( _doc[ docId ].drafter == msg.sender, "onlyQuorum: caller is not drafter");
        require( (_doc[ docId ].draftDate + ( _expirationPeriod * 86400) ) > block.timestamp, "onlyQuorum: approval period has expired" );

        uint256 numberOfMembers = _memberIndex.getIndexedSize();
        if( _minimumMembers == 0 || numberOfMembers < _minimumMembers ) { //최소 인원 이하이면 contract owner만 호출 가능하다
             require( msg.sender == _creator, "onlyMember: If less than the minimum number of members, caller must be a contract owner");
        } else { //최소 인원 이상인 경우
            uint256 minimumApproval = (numberOfMembers / 2) + 1; 
            require( _doc[ docId ].approval >= minimumApproval, "onlyQuorum: approval count must be at least (number of members / 2) + 1");
        } 
        _;
    }

    function _revertReason (bytes memory revertData) internal pure returns (string memory reason) {
        uint l = revertData.length;
        if (l < 68) return "";
        uint t;
        assembly {
            revertData := add (revertData, 4)
            t := mload (revertData)
            mstore (revertData, sub (l, 4))
        }
        reason = abi.decode (revertData, (string));
        assembly {
            mstore (revertData, t)
        }
    }
    
    function _isInvokable( uint256 docId ) internal view returns( bool ) {
        if( _doc[ docId ].invoked ) 
            return false;
        if( (_doc[ docId ].draftDate + ( _expirationPeriod * 86400) ) < block.timestamp)
            return false;

        uint256 numberOfMembers = _memberIndex.getIndexedSize();
        if( _minimumMembers == 0 || numberOfMembers < _minimumMembers ) {
            if( _creator != msg.sender ) {
               return false;
            }
        } else { //최소 인원 이상인 경우
            uint256 minimumApproval = (numberOfMembers / 2) + 1;
            if( _doc[ docId ].approval < minimumApproval ) {
                return false;
            }
        } 
        return true;
    }

    function cancel( uint256 docId ) public noReentrancy override {
        require( _doc[ docId ].drafter == msg.sender, "cancel: caller is not the drafter" );
        require( !_doc[ docId ].cancellation, "cancel: already cancelled");
        require( (_doc[ docId ].draftDate + ( _expirationPeriod * 86400) ) > block.timestamp, "cancel: approval period has expired" );
        require( !_doc[ docId ].invoked, "_approval: already invoked" );

        _doc[ docId ].cancellation = true;
        emit eventCancel( docId );
    }

    function invoke( uint256 docId ) public onlyQuorum(docId) noReentrancy override {
        (string memory func, bytes memory param )   = abi.decode( _doc[docId].callData, ( string, bytes ) );  
        bytes4          FUNC_SELECTOR               = bytes4( keccak256(bytes(func)) );
        bytes memory    packedData                  = abi.encodePacked( FUNC_SELECTOR, param );

        ( _doc[docId].success, _doc[docId].returnData) = address(_doc[ docId ].to).call( packedData );
        if( !_doc[docId].success ) {
            revert( _revertReason(_doc[docId].returnData) );
        }
        _doc[docId].invoked     = true;
        _doc[docId].invokeDate  = block.timestamp;
        emit eventInvoke( msg.sender, docId, _doc[docId].returnData );        
    }

    function inquery( uint256 docId ) public view override returns( TDrafeDocViewer memory doc ) {
        doc.drafter         = _doc[docId].drafter;
        doc.draftDate       = _doc[docId].draftDate;
        doc.approval        = _doc[docId].approval;
        doc.cancellation    = _doc[docId].cancellation; 
        doc.invoked         = _doc[docId].invoked; 
        doc.invokeDate      = _doc[docId].invokeDate;
        doc.to              = _doc[docId].to;
        return doc;
    }

    function inqueryApprover( uint256 docId ) public view override returns( TSigner[] memory approvers ) {
        uint8 approval = _doc[docId].approval;
        if( approval > 0 ) {
           approvers      = new TSigner[]( approval );
            uint8 i = 0;
            for( ; i<approval; i++ ) {
               approvers[i] = _doc[ docId ].signer[i];
            } 
        }
    }

    function inqueryCallData( uint256 docId ) public view override returns( address, string memory, bytes memory ) {
        (string memory func, bytes memory param )   = abi.decode( _doc[docId].callData, ( string, bytes ) );
        return ( _doc[docId].to, func, param );
    }    

    function inqueryReturnData( uint256 docId ) public view override returns( bool, bool, bytes memory ) {
        return ( _doc[docId].invoked, _doc[docId].success, _doc[docId].returnData );
    }    

    function inqueryMembers() public view override returns( address[] memory members) {
        uint256 size = _memberIndex.getIndexedSize();
        members = new address[](size);
        uint256 i = 0;
        for( ; i<size; i++ ) {
            members[i] = _memberIndex.getAddress( i + 1 );
        }
        return members;
    }

    function inqueryNumberOfMembers() public view override returns( uint256 ) {
        return _memberIndex.getIndexedSize();
    }    

    function inqueryLatestId() public view override returns( uint256 ) {    
        return _idTracker-1;
    }

    function _proposal( address toContract, bytes memory callData ) internal returns( uint256 ) {
        uint256 docId = _idTracker;
        _doc[ docId ].drafter        = msg.sender;
        _doc[ docId ].draftDate      = (block.timestamp / 86400 ) * 86400;
        
        TSigner memory tSigner;
        tSigner.approver            = msg.sender;
        tSigner.time                = block.timestamp;

        _doc[ docId ].indexing[msg.sender]              = _doc[ docId ].approval;
        _doc[ docId ].signer[_doc[ docId ].approval]    = tSigner;

        _doc[ docId ].to             = toContract;        
        _doc[ docId ].callData       = callData;

        _doc[ docId ].approval++;   //drafter는 기본으로 approve 한 상태로 간주 한다         
        _idTracker++;        
        emit eventProposal( msg.sender, docId, toContract, callData, _isInvokable( docId ) ) ;
        return docId;
    }

    function _approval( uint256 docId ) internal {
        /*
            기안자는 sign을 할 수 없다
            안건 상정 취소된 문건은 승인 불가 하다
            기안작성 날짜로 부터 금일 포함 _expirationPeriod 일 이내에 승인 하여야 한다.
            구성원만이 sign을 할 수 있다
            sign한 구성원은 중복 승인을 할 수 없다
            invoke된 기안은 sign 할 수 없다.
            drafter는 기본으로 approve 한 상태로 간주 한다.
        */
        require( _doc[ docId ].drafter != msg.sender, "_approval: the drafter and signer must be different" );
        require( !_doc[ docId ].cancellation, "onlyQuorum: cancelled");
        require( (_doc[ docId ].draftDate + ( _expirationPeriod * 86400) ) > block.timestamp, "_approval: approval period has expired" );
        require( _memberIndex.getIndex( msg.sender ) > 0, "_approval: caller is not member" );
        require( _doc[ docId ].indexing[msg.sender] == 0, "_approval: already approved" );
        require( !_doc[ docId ].invoked, "_approval: already invoked" );

        TSigner memory tSigner;
        tSigner.approver    = msg.sender;
        tSigner.time        = block.timestamp;

        _doc[ docId ].indexing[msg.sender]              = _doc[ docId ].approval;
        _doc[ docId ].signer[_doc[ docId ].approval]    = tSigner;
        _doc[ docId ].approval++;        
        emit eventApproval( msg.sender, docId, _isInvokable( docId ) );        
    }

    function _addMember( address newMember ) internal {
        _memberIndex.addIndex( newMember );
        emit eventAddMember( newMember ) ;
    }

    function _removeMember( address member ) internal {
        require( _memberIndex.getIndexedSize() > 2, "_removeMember: must have at least 3 members" );
        _memberIndex.removeIndex( member );
        emit eventRemoveMember( member ) ;
    }
}