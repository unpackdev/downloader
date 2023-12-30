pragma solidity ^0.5.15;

import "./Poap.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract PoapDelegatedMint is Ownable, Pausable {

    event VerifiedSignature(
        bytes _signedMessage
    );

    string public name = "POAP Delegated Mint";

    // POAP Contract - Only Mint Token function
    Poap POAPToken;

    // POAP valid token minter
    address public validSigner;

    // Processed signatures
    mapping(bytes => bool) public processed;

    mapping(uint256 => bool) public processedTokens;

    constructor (address _poapContractAddress, address _validSigner) public{
        validSigner = _validSigner;
        POAPToken = Poap(_poapContractAddress);
    }

    function _recoverSigner(bytes32 message, bytes memory signature) private pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(signature);
        return ecrecover(message, v, r, s);
    }

    function _splitSignature(bytes memory signature) private pure returns (uint8, bytes32, bytes32) {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
        // second 32 bytes
            s := mload(add(signature, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }

    function renouncePoapAdmin() public onlyOwner {
        POAPToken.renounceAdmin();
    }

    function _isValidData(uint256 _eventId, uint256 _tokenId, address _receiver, bytes memory _signedMessage) private view returns(bool) {
        bytes32 message = keccak256(abi.encodePacked(_eventId, _tokenId, _receiver));
        return (_recoverSigner(message, _signedMessage) == validSigner);
    }

    function mintToken(uint256 eventId, uint256 tokenId, address receiver, bytes memory signedMessage) public whenNotPaused returns (bool) {
        // Check that the signature is valid
        require(_isValidData(eventId, tokenId, receiver, signedMessage), "Invalid signed message");
        // Check that the signature was not already processed
        require(processed[signedMessage] == false, "Signature already processed");
        // Check that the token was not already processed
        require(processedTokens[tokenId] == false, "Token already processed");

        processed[signedMessage] = true;
        processedTokens[tokenId] = true;
        emit VerifiedSignature(signedMessage);
        return POAPToken.mintToken(eventId, tokenId, receiver);
    }
}
