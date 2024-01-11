// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";

contract vFlix {

    address public admin;

    modifier onlyAdmin()
    {
        require( msg.sender == admin, "Caller is not admin" );
        _;
    }

    constructor()
    {
        admin = msg.sender;
    }

    function pay( address payee, uint256 fee, uint256 cost, uint8 v, bytes32 r, bytes32 s ) 
        external payable
    {
        bytes memory message = abi.encode( payee, fee, cost );
        bool validSignature = _signatureIsValid( message, v, r, s );
        require( validSignature, "Invalid signature" );

        require( msg.value == cost, "Insufficient payment" );

        uint256 commission = cost * fee / 1000;
        payable( payee ).transfer( cost - commission );
        payable( admin ).transfer( commission );
    }

    function payToken( IERC20 token, address payee, uint256 fee, uint256 cost, uint8 v, bytes32 r, bytes32 s ) 
        external
    {
        bytes memory message = abi.encode( token, payee, fee, cost );
        bool validSignature = _signatureIsValid( message, v, r, s );
        require( validSignature, "Invalid signature" );

        require( token.balanceOf( msg.sender ) >= cost, "Insufficient balance" );

        uint256 commission = cost * fee / 1000;
        bool successPayee = token.transferFrom( msg.sender, payee, cost - commission );
        bool successAdmin = token.transferFrom( msg.sender, admin, commission );
        require( successPayee && successAdmin, "Token transfer failed. Missing approval?" );
    }

    function setAdmin( address _admin ) 
        external onlyAdmin
    {
        admin = _admin;
    }

    function withdraw() 
        external onlyAdmin 
    {
        uint256 amount = address( this ).balance;
        require( amount > 0, "Balance is zero" );
        payable( admin ).transfer( amount );
    }

    function _signatureIsValid( bytes memory message, uint8 v, bytes32 r, bytes32 s ) 
        internal view returns ( bool )
    {
        bytes32 messageHash = keccak256( message );
        bytes32 messageHashed = keccak256( abi.encodePacked( "\x19Ethereum Signed Message:\n32", messageHash ) );
        return ecrecover( messageHashed, v, r, s ) == admin;
    }

    receive() external payable {}
    fallback() external payable {}
}
