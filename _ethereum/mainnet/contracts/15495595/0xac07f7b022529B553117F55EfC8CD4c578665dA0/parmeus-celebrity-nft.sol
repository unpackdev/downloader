// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";

contract ParmeusCelebrity is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using EnumerableSet for EnumerableSet.UintSet;
    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    address private _contractManager;

    constructor() ERC721("Parmeus Celebrity Match", "PCLBM"){
        _tokenIds.increment(); // token id start from 1
        _contractManager = msg.sender;
    }

    function generateReport(string memory _cid, uint8 v, bytes32 r, bytes32 s ) public returns(bool success){
        // reconstruct origin sign message, only correct sender can mint
        string memory originSignMsg = string(abi.encodePacked( Strings.toHexString(msg.sender), _cid));
        _requireSignatureFromManager(originSignMsg, v, r, s);

        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked('ipfs://', _cid)));

        _tokenIds.increment();

        return true;
    }

    function burnNft(uint256 tokenId) public{
        _burn(tokenId);
    }

    /**
     *  get calller's nft
     */
    function getSelfReports() public view returns(string[] memory tokenUris, uint256[] memory tokenIds){
        // If owner has too many fts, gas may out
        if(_holderTokens[msg.sender].length() == 0){
            return (new string[](0), new uint256[](0));
        }
        else{
            string[] memory _tokenUris = new string[](_holderTokens[msg.sender].length());
            uint256[] memory _tokenIds = new uint256[](_holderTokens[msg.sender].length());
            for(uint16 i=0; i< _tokenUris.length; i++){
                _tokenIds[i] = _holderTokens[msg.sender].at(i);
                _tokenUris[i] = tokenURI(_holderTokens[msg.sender].at(i));
            }
            return (_tokenUris, _tokenIds);
        }
    }

    function changeManager(address _targetManager) public {
        require(msg.sender == _contractManager, 'You are not the current manager');
        _contractManager = _targetManager;
    }

    /**
     *  @dev resolve signature 
     */
    function _resolveSignature(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns(address signer) {
        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }
        // Maximum length we support
        require(length <= 999999);
        // The length of the message's length in base-10
        uint256 lengthLength = 0;
        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;
        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                divisor /= 10;
                continue;
                }
            }
            // Found a non-zero digit or non-leading zero digit
            lengthLength++;
            // Remove this digit from the message length's current value
            length -= digit * divisor;
            // Shift our base-10 divisor over
            divisor /= 10;
            
            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }
        // Perform the elliptic curve recover operation
        bytes32 msgHash = keccak256(abi.encodePacked(header, message));
        return ecrecover(msgHash, v, r, s);
    }

    /**
     * @dev easy to use require manager signature
     */
    function _requireSignatureFromManager(string memory message, uint8 v, bytes32 r, bytes32 s) internal view{
        address signer = _resolveSignature(message, v, r, s);
        require(signer == _contractManager, 'Message signer is not the contract manager');
    }


    /**
     * @dev override approve function to prevent approved to other address
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require(false, 'Parmeus Celebrity Match nft can not be delegated');
    }

    /**
     * @dev override setApprovalForAll function to prevent approved to other address
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(false, 'Parmeus Celebrity Match nft can not be delegated');
    }


    /**
     *@dev rewrite before transfer, (need to prevent user burn taits?)
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        require(from == address(0) || to == address(0), 'Parmeus Celebrity Match nft can not be transfered');
    }

    /**
     * @dev rewrite after token transfer
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        if(from != address(0)){
            _holderTokens[from].remove(tokenId);
        }
        if(to != address(0)){
            _holderTokens[to].add(tokenId);
        }
    }
}