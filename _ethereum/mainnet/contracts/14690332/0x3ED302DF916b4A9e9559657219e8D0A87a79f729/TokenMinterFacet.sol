// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./ITokenMinter.sol";
import "./IERC1155Mint.sol";
import "./IERC1155Burn.sol";

import "./LibAppStorage.sol";
import "./LibDiamond.sol";

contract TokenMinterFacet {

    // application storage
    AppStorage internal s;

    event GemToken(address indexed receiver, uint256 indexed tokenId, uint256 indexed auditHash, string giaNumber, uint256 amount);
    event GemTokenBurn(address indexed target, uint256 indexed tokenId, uint256 indexed amount);

    modifier onlyController {
        require(msg.sender == LibDiamond.contractOwner()  || msg.sender == address(this), "only the contract owner can mint");
        _;
    }

    function setToken(address token) external onlyController {
        s.tokenMinterStorage.token = token;
    }

    /// @notice mint a token associated with a collection with an amount
    /// @param target the mint receiver
    /// @param id the collection id
    /// @param amount the amount to mint
    function burn(string memory secret, address target, uint256 id, uint256 amount) external onlyController {

        // rebuild the audit hash
        bytes32 auditHash =  keccak256(abi.encodePacked(
            secret,
            id
        ));
        // make sure it matches the stored hash
        require(s.tokenMinterStorage.tokenAuditHashes[id] == uint256(auditHash), "token not valid");

        // delete the stored hash
        delete s.tokenMinterStorage.tokenAuditHashes[id];
        delete s.tokenMinterStorage.tokenGiaNumbers[id];

        // burn the token
        IERC1155Burn(s.tokenMinterStorage.token).burn(target, id, amount);

        // emit the event
        emit GemTokenBurn(target, id, amount);
    }

    function mint(string memory secret, address receiver, string memory giaNumber, uint256 amount) external onlyController returns(bytes32 publicHash)  {

        // require all string inputs to have a value
        require(bytes(secret).length != 0, "secret cannot be empty");
        require(bytes(giaNumber).length != 0, "giaNumber cannot be empty");

        // require amount be nonzero
        require(amount != 0, "amount cannot be zero");

        // require receiver not be the zero address
        require(receiver != address(0x0), "receiver cannot be the zero address");

        // create a keccak256 hash using the contract address, the collection, and the gia number
        publicHash =  keccak256(abi.encodePacked(
            address(this),
            giaNumber
        ));

        // create an audit hash using the secret, contract address, the collection, and the gia number
        bytes32 auditHash =  keccak256(abi.encodePacked(
            secret,
            publicHash
        ));

        // require that this token is not already minted
        require(s.tokenMinterStorage.tokenAuditHashes[uint256(publicHash)] == 0, "token already minted");

        // mint the token to the receiver using the public hash
        IERC1155Mint(s.tokenMinterStorage.token).mint(
            receiver,
            uint256(publicHash),
            amount,
            ""
        );

        // store the audit hash
        s.tokenMinterStorage.tokenAuditHashes[uint256(publicHash)] = uint256(auditHash);
        s.tokenMinterStorage.tokenGiaNumbers[uint256(publicHash)] = giaNumber;

        // emit the event
        emit GemToken(receiver, uint256(publicHash), uint256(auditHash), giaNumber, amount);
    }

    function getAuditHash(uint256 id) external view returns (uint256) {
        return s.tokenMinterStorage.tokenAuditHashes[id];
    }

    function getGiaNumber(uint256 id) external view returns (string memory) {
        return s.tokenMinterStorage.tokenGiaNumbers[id];
    }

}
