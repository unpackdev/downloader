// SPDX-License-Identifier: MIT
// XEN Contracts v0.6.0
pragma solidity ^0.8.13;

import {CQuorum}                                from './dao/quorum.sol';

contract CTeamVault is CQuorum {

    constructor() {
    }

    modifier onlyInterCall() {
        require( address(this) == msg.sender, "onlyInterCall: caller is not this");
        _;
    }

    function approval( uint256 docId ) public onlyMember noReentrancy {
        _approval( docId );
    }

    function proposalRecommend( address newMember ) public onlyMember noReentrancy returns( uint256 ) {
        require( _memberIndex.getIndex( newMember ) == 0, "proposalRecommend: already a member" );
        bytes memory param      = abi.encode( newMember );
        bytes memory packed     = abi.encode( "recommend(address)", param );
        return _proposal( address(this), packed );
    }
 
    function proposalExpulsion( address member ) public onlyMember noReentrancy returns( uint256 ) {
        require( _memberIndex.getIndexedSize() > 2, "proposalExpulsion: must have at least 3 members" );
        require( _memberIndex.getIndex( member ) > 0, "proposalExpulsion: not a member" );
        require( _creator != member, "proposalExpulsion: Can't banish creator");
        bytes memory param      = abi.encode( member );
        bytes memory packed     = abi.encode( "expulsion(address)", param );
        return _proposal( address(this), packed );
    }

    function proposalTransfer20( address toContract, address to, uint256 amount ) public onlyMember noReentrancy returns( uint256 ) {
        bytes memory param      = abi.encode( to, amount );
        bytes memory packed     = abi.encode( "transfer(address,uint256)", param );
        return _proposal( toContract, packed );           
    }     

    function proposalTransfer721( address toContract, address to, uint256 tokenId ) public onlyMember noReentrancy returns( uint256 ) {
        bytes memory param      = abi.encode( address(this), to, tokenId );
        bytes memory packed     = abi.encode( "transferFrom(address,address,uint256)", param );
        return _proposal( toContract, packed );           
    }      

    function proposalTransfer1155( address toContract, address to, uint256 tokenId, uint256 amount ) public onlyMember noReentrancy returns( uint256 ) {
        bytes memory param      = abi.encode( address(this), to, tokenId, amount, "" );
        bytes memory packed     = abi.encode( "safeTransferFrom(address,address,uint256,uint256,bytes)", param );
        return _proposal( toContract, packed );           
    }    

    //ERC20.ERC721
    function proposalApprove( address toContract, address spender, uint256 value ) public onlyMember noReentrancy returns( uint256 ) {
        bytes memory param      = abi.encode( spender, value );
        bytes memory packed     = abi.encode( "approve(address,uint256)", param );
        return _proposal( toContract, packed );           
    }       

    function proposal( address toContract, string calldata funcSignatrue, bytes calldata funcParams ) public onlyMember noReentrancy returns( uint256 ) {
        bytes memory packed     = abi.encode( funcSignatrue, funcParams );
        return _proposal( toContract, packed );       
    }

    ////////////////////////////////////////////////////////////////////////////////
    //invoke funtion

    function recommend( address newMember ) public onlyInterCall {
        _addMember( newMember );
    }

    function expulsion( address member ) public onlyInterCall {
        _removeMember( member );
    }
 
}
