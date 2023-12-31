// SPDX-License-Identifier: MIT
// XEN Contracts v0.6.0
pragma solidity ^0.8.13;


interface IQuorum {

struct TSigner {
    address                         approver;
    uint256                         time;
}

struct TDraftDoc {
    address                         drafter;        //기안자
    uint256                         draftDate;      //작성 날짜

    uint8                           approval;       //동의한 member 수
    mapping( uint8 => TSigner )     signer;         //동의한 account
    mapping( address => uint8 )     indexing;


    bool                            cancellation;   //안건 상정 취소
    bool                            invoked;        //transaction 호출 여부
    uint256                         invokeDate;
    address                         to;    
    bytes                           callData;
    bool                            success;
    bytes                           returnData;
}

struct TDrafeDocViewer {
    address                         drafter;        //기안자
    uint256                         draftDate;      //작성 날짜

    uint8                           approval;       //동의한 member 수
    bool                            cancellation;   //상정 취소 여부
    bool                            invoked;        //transaction 호출 여부
    uint256                         invokeDate;     //실행한 날짜
    address                         to;             //호출 할 contract address -> 0.6.0.2 이상 버전
}

    function invoke( uint256 docId ) external;
    function cancel( uint256 docId ) external;
    
    function inquery( uint256 docId ) external view returns( TDrafeDocViewer memory doc );
    function inqueryApprover( uint256 docId ) external view returns( TSigner[] memory approvers );
    function inqueryCallData( uint256 docId ) external view returns( address, string memory, bytes memory );
    function inqueryReturnData( uint256 docId ) external view returns( bool, bool, bytes memory );

    function inqueryMembers() external view returns( address[] memory members);
    function inqueryNumberOfMembers() external view returns( uint256 );
    function inqueryLatestId() external view returns( uint256 );

}
