// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./IROLL.sol";

contract Scorekeeper
{
    using Strings for uint256;

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct UserData {
        uint64 rollerId;
        uint64 score;
        uint64 timestamp;
        address wallet;
    }

    IROLL public rollToken;
    address public scoreSigner;
    uint256 public rollScorePrice = 100 ether;

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant USERDATA_TYPEHASH = keccak256(
        "UserData(uint64 rollerId,uint64 score,uint64 timestamp,address wallet)"
    );

    bytes32 DOMAIN_SEPARATOR;


    mapping(uint => UserData) public scores;

    constructor() {
        uint256 chainId;
        assembly {
          chainId := chainid()
        }

        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "RetroRollers",
            version: '1',
            chainId: chainId,
            verifyingContract: address(this)
        }));
    }

/** Hashing functions used in verfiying Score messages */
    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(UserData memory score) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            USERDATA_TYPEHASH,
            score.rollerId,
            score.score,
            score.timestamp,
            score.wallet
        ));
    }

/** Score Functions */

    function recordHighScore(uint8 v, bytes32 r, bytes32 s, UserData memory record) public virtual {
        if(rollScorePrice > rollToken.balanceOf(msg.sender)) revert NotEnoughRollToken();
        if(rollScorePrice > rollToken.allowance(msg.sender, address(this))) revert NotEnoughRollToken();

        rollToken.transferFrom(msg.sender, address(this), rollScorePrice);

        bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(record)
        ));

        address signer = ecrecover(digest, v, r, s);

        if(signer != scoreSigner) revert InvalidSignature();
        // require(signer == scoreSigner, "InvalidSignature");
        if(signer == address(0)) revert ECDSAInvalidSignature();
        // require(signer != address(0), "ECDSAInvalidSignature");
        //require(ownerOf(record.rollerId) == msg.sender, "NotOwner");
        if(record.wallet != msg.sender) revert NotScoreWallet();
        // require(record.wallet == msg.sender, "NotScorerWallet");

        if(scores[record.rollerId].score > record.score) revert NotHighScore();

        saveScore(record);
    }

    function saveScore(UserData memory record) internal virtual {
        scores[record.rollerId] = record;
    }

    function getScore(uint _tokenId) public virtual view returns (UserData memory) {
        return scores[_tokenId];
    }
}

error NotHighScore();
error NotEnoughRollToken();
error NotScoreWallet();
error InvalidSignature();
error ECDSAInvalidSignature();

