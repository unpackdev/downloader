// SPDX-License-Identifier: DBAD
pragma solidity ^0.8.13;


/************************************/	contract Journal {
/*                                  */	    address public owner;
/*             (｡◕‿‿◕｡)             */	    address[] public signers;
/*                                  */	    mapping(bytes32 => address) public messages;
/*                                  */	
/*                                  */	    event NewEntry(bytes32 indexed msg, address indexed signer);
/*-. .-.-.  .-.-.  .-.-.  .-.-.  .-.*/	    event NewSigner(address indexed signer);
/*.'=`. .'==`. .'==`. .'==`. .'==`. */	
/*"    "      "      "      "      "*/	    error Unauthorized();
/*                                  */	
/*-. .-.-.  .-.-.  .-.-.  .-.-.  .-.*/	    modifier ownerOnly() {
/*.'=`. .'==`. .'==`. .'==`. .'==`. */	        if(msg.sender != owner)
/*"    "      "      "      "      "*/	            revert Unauthorized();
/*                                  */	
/*                                  */	         _;
/*      w e l c o m e               */	    }
/*        t o                       */	
/*          m y                     */	    modifier signerOnly() {
/*            j o u r n a l         */	        bool exists = false;
/*                                  */	        for(uint i=1; i<=signers.length; i++) {
/*                                  */	            if(signers[i-1] == msg.sender) {
/*      i                           */	                exists = true;
/*       p o s t                    */	            }
/*        c o m m i t m e n t       */	        }
/*          h a s h e s             */	
/*            f r o m               */	        if(!exists)
/*              m y                 */	            revert Unauthorized();
/*      a c c o u n t s             */	            
/*        t o                       */	        _;
/*          t h i s                 */	    }
/*             j o u r n a l        */	
/*               b o o k            */	    constructor() {
/*                                  */	        owner = msg.sender;
/*                                  */          signers.push(msg.sender);
/*                                  */	    }
/*                                  */	
/*                                  */	    function getOwner() public view returns(address) {
/*                                  */	        return owner;
/*-. .-.-.  .-.-.  .-.-.  .-.-.  .-.*/	    }
/*.'=`. .'==`. .'==`. .'==`. .'==`. */	
/*"    "      "      "      "      "*/	    function changeOwner(address _owner) public ownerOnly() {
/*                                  */	        owner = _owner;
/*-. .-.-.  .-.-.  .-.-.  .-.-.  .-.*/	    }
/*.'=`. .'==`. .'==`. .'==`. .'==`. */	
/*"    "      "      "      "      "*/	    function addSigner(address _signer) public ownerOnly() {
/*                                  */	        signers.push(_signer);
/*-. .-.-.  .-.-.  .-.-.  .-.-.  .-.*/	        emit NewSigner(_signer);
/*.'=`. .'==`. .'==`. .'==`. .'==`. */	    }
/*"    "      "      "      "      "*/	
/*                                  */	    function removeSigner(address _signer) public ownerOnly() {
/*-. .-.-.  .-.-.  .-.-.  .-.-.  .-.*/	        for(uint i=1; i<=signers.length; i++) {
/*.'=`. .'==`. .'==`. .'==`. .'==`. */	            if(signers[i-1] == _signer) {
/*"    "      "      "      "      "*/	                delete signers[i-1];
/*                                  */	            }
/*-. .-.-.  .-.-.  .-.-.  .-.-.  .-.*/	        }
/*.'=`. .'==`. .'==`. .'==`. .'==`. */	    }
/*"    "      "      "      "      "*/	
/*-. .-.-.  .-.-.  .-.-.  .-.-.  .-.*/	    function isSigner(address _signer) public view returns(bool) {
/*.'=`. .'==`. .'==`. .'==`. .'==`. */	        bool exists = false;
/*"    "      "      "      "      "*/	        for(uint i=1; i<=signers.length; i++) {
/*                                  */	            if(signers[i-1] == _signer) {
/*                                  */	                exists = true;
/*           hacks4egirls           */	            }
/*                                  */	        }
/*                                  */	
/*  ⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⊱⊰⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯  */	        return exists;
/*                                  */	    }
/*                                  */	
/*         (＾◡＾)っ( • )( • )       */	    function write(bytes32 _msg) public signerOnly() {
/*                                  */	        messages[_msg] = msg.sender;
/*                                  */	        emit NewEntry(_msg, msg.sender);
/*                                  */	    }
/*************************************/	}