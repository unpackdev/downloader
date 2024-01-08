pragma solidity ^0.6.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract Carton {
    using Counters for Counters.Counter;
    Counters.Counter private _boxIds;
    ERC721 public YaytsoInterface;

    struct Box {
        uint256 id;
        bytes32 lat;
        bytes32 lon;
        bool locked;
        bool created;
        uint256 nonce;
    }

    mapping(uint256 => Box) public Boxes;
    mapping(uint256 => address) public idToKey;
    mapping(uint256 => uint256) public boxIdToTokenId;

    event BoxCreated(uint256 id);
    event BoxFilled(uint256 id, uint256 tokenId, uint256 nonce);
    event YaytsoClaimed(uint256 id, uint256 tokenId, address claimer);

    constructor(address _YaytsoAddress) public {
        YaytsoInterface = ERC721(_YaytsoAddress);
    }

    function createBox(bytes32 _lat, bytes32 _lon) public {
        _boxIds.increment();
        uint256 _boxId = _boxIds.current();
        Box memory _box = Box(_boxId, _lat, _lon, false, true, 0);
        Boxes[_boxId] = _box;
        emit BoxCreated(_boxId);
    }

    function fillBox(
        uint256 _boxId,
        address _key,
        uint256 _tokenId
    ) public {
        Box memory _box = Boxes[_boxId];
        require(_box.created == true, "BOX_NOT_EXIST");
        require(_box.locked == false, "BOX_IS_LOCKED");
        address _tokenOwner = YaytsoInterface.ownerOf(_tokenId);
        require(_tokenOwner == _key, "KEY_MUST_BE_OWNER");
        require(
            YaytsoInterface.getApproved(_tokenId) == address(this),
            "CARTON_MUST_BE_APPROVED"
        );
        _box.locked = true;
        _box.nonce += 1;
        idToKey[_boxId] = _key;
        Boxes[_boxId] = _box;
        boxIdToTokenId[_boxId] = _tokenId;
        emit BoxFilled(_boxId, _tokenId, _box.nonce);
    }

    function getMessageHash(uint256 _id, uint256 _nonce)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_id, _nonce));
    }

    function verify(
        address _signer,
        uint256 _id,
        uint256 _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_id, _nonce);
        bytes32 ethSignedMessageHash =
            ECDSA.toEthSignedMessageHash(messageHash);

        return ECDSA.recover(ethSignedMessageHash, signature) == _signer;
    }

    function claimYaytso(
        uint256 _boxId,
        uint256 _nonce,
        bytes memory signature
    ) public {
        Box memory _box = Boxes[_boxId];
        require(_nonce == _box.nonce, "NONCE_MISMATCH");
        require(_box.locked == true, "BOX_NOT_LOCKED");
        address _key = idToKey[_boxId];
        require(verify(_key, _boxId, _nonce, signature), "INVALID_CLAIM");
        uint256 _yaytsoId = boxIdToTokenId[_boxId];
        address _yaytsoOwner = YaytsoInterface.ownerOf(_yaytsoId);
        require(_yaytsoOwner == _key, "SIGNATURE_NOT_OWNER");
        YaytsoInterface.transferFrom(_key, msg.sender, _yaytsoId);
        _box.locked = false;
        boxIdToTokenId[_boxId] = 0;
        Boxes[_boxId] = _box;
        emit YaytsoClaimed(_boxId, _yaytsoId, msg.sender);
    }
}
