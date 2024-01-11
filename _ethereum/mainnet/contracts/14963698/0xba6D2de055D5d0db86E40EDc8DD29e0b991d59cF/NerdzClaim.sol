// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface iCryptoNerdz {
    function balanceOf(address owner) external view returns(uint256);
    function transferFrom(address, address, uint) external;
    function ownerOf(uint) external;
}

contract NerdzClaim is Ownable {
    iCryptoNerdz public CryptoNerdz;

    bool public claimPaused = true;
    address public signerAddress;
    address public nerdzWallet;
    uint256 private nextToken;
    mapping(address => bool) public claimed;

    constructor(address cnAddress)  {
        CryptoNerdz = iCryptoNerdz(cnAddress);
    }

    /*
     * @dev Requires msg.sender to have valid claim.
     * @param _qty Amount msg.sender can claim.
     * @param _v ECDSA signature parameter v.
     * @param _r ECDSA signature parameters r.
     * @param _s ECDSA signature parameters s.
     */
    modifier onlyValidClaims( uint256 _qty, bytes32 _r, bytes32 _s, uint8 _v) {
        require(isValidClaim(msg.sender, _qty, _r, _s, _v), "SignatureMismatch");
        _;
    }

    function claimNerdz(uint256 qty, bytes32 r, bytes32 s, uint8 v) external onlyValidClaims(qty,r,s,v) {
        require(!claimPaused, "ClaimingPaused"); 
        require(!claimed[msg.sender], "NoneAvailableForAddress");
        uint currToken = nextToken;

        for(uint i=0; i<qty; i++) {
            if(currToken == 1262 || currToken == 1555) {
                currToken++;
            }

            CryptoNerdz.transferFrom(nerdzWallet, msg.sender, currToken);
            currToken++;
        }

        nextToken = currToken;
        claimed[msg.sender] = true;
    }

    function checkClaimed(address user) external view returns(bool) {
        return claimed[user];
    }

    function setNerdzWallet(address wallet) external onlyOwner {
        nerdzWallet = wallet;
    }

    function setStartToken(uint token) external onlyOwner{
        nextToken = token;
    }

    function setSignerWallet(address wallet) external onlyOwner {
        signerAddress = wallet;
    }

    function toggleClaim() external onlyOwner {
        claimPaused = !claimPaused;
    }

    /*
     * @dev Verifies if message was signed by owner to give access to _add for this contract.
     *      Assumes Geth signature prefix.
     * @param _add Address of agent with access.
     * @param _qty Amount available to claim.
     * @param _v ECDSA signature parameter v.
     * @param _r ECDSA signature parameters r.
     * @param _s ECDSA signature parameters s.
     * @return Validity of access message for a given address.
     */
    function isValidClaim( address _add, uint256 _qty, bytes32 _r, bytes32 _s, uint8 _v) public view returns (bool) {
        bytes32 hash = keccak256(abi.encode(owner(), _add, _qty));
        bytes32 message = keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address sig = ecrecover(message, _v, _r, _s);
        return signerAddress == sig;
    }
}
