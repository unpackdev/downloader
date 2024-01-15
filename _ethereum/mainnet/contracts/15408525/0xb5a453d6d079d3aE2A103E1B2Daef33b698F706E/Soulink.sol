// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./SignatureChecker.sol";
import "./SoulinkLibrary.sol";
import "./SoulBoundToken.sol";
import "./ISoulink.sol";

contract Soulink is Ownable, SoulBoundToken, EIP712, ISoulink {
    uint128 private _totalSupply;
    uint128 private _burnCount;

    // keccak256("RequestLink(uint256 targetId,uint256 deadline)");
    bytes32 private constant _REQUESTLINK_TYPEHASH = 0xa09d82e5227cc630e060d997b23666070a7c20039c7884fd8280a04dcaef5042;

    mapping(address => bool) public isMinter;
    mapping(uint256 => mapping(uint256 => bool)) internal _isLinked;
    mapping(uint256 => uint256) internal _internalId;
    mapping(bytes32 => bool) internal _notUsableSig;

    string internal __baseURI;

    constructor(address[] memory addrs, uint256[2][] memory connections)
        SoulBoundToken("Soulink", "SL")
        EIP712("Soulink", "1")
    {
        isMinter[msg.sender] = true;

        __baseURI = "https://api.soul.ink/metadata/";

        for (uint256 i = 0; i < addrs.length; ) {
            address user = addrs[i];
            uint256 tokenId = getTokenId(user);
            _mint(user, tokenId);
            _internalId[tokenId] = i + 1;
            unchecked {
                i++;
            }
        }
        _totalSupply = uint128(addrs.length);

        for (uint256 i = 0; i < connections.length; ) {
            uint256[2] memory connection = [connections[i][0], connections[i][1]];

            _setLink(connection[0], connection[1]);
            unchecked {
                i++;
            }
        }
    }

    //ownership functions
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        __baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function setMinter(address target, bool _isMinter) external onlyOwner {
        require(isMinter[target] != _isMinter, "UNCHANGED");
        isMinter[target] = _isMinter;
        emit SetMinter(target, _isMinter);
    }

    function updateSigNotUsable(bytes32 sigHash) external onlyOwner {
        _useSignature(sigHash);
    }

    //external view/pure functions
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply - _burnCount;
    }

    function getTokenId(address owner) public pure returns (uint256) {
        return SoulinkLibrary._getTokenId(owner);
    }

    function isLinked(uint256 id0, uint256 id1) external view returns (bool) {
        if (!_exists(id0) || !_exists(id1)) {
            return false;
        }
        (uint256 iId0, uint256 iId1) = SoulinkLibrary._sort(_internalId[id0], _internalId[id1]);
        return _isLinked[iId0][iId1];
    }

    function isUsableSig(bytes32 sigHash) external view returns (bool) {
        return !_notUsableSig[sigHash];
    }

    //internal functions
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function _getInternalIds(uint256 id0, uint256 id1) internal view returns (uint256 iId0, uint256 iId1) {
        _requireMinted(id0);
        _requireMinted(id1);

        (iId0, iId1) = SoulinkLibrary._sort(_internalId[id0], _internalId[id1]);
    }

    function _checkSignature(
        address from,
        uint256 toId,
        uint256 fromDeadline,
        bytes calldata fromSig
    ) internal view {
        require(
            SignatureChecker.isValidSignatureNow(
                from,
                _hashTypedDataV4(keccak256(abi.encode(_REQUESTLINK_TYPEHASH, toId, fromDeadline))),
                fromSig
            ),
            "INVALID_SIGNATURE"
        );
    }

    function _useSignature(bytes32 sigHash) internal {
        require(!_notUsableSig[sigHash], "USED_SIGNATURE");
        _notUsableSig[sigHash] = true;
    }

    function _setLink(uint256 _id0, uint256 _id1) internal {
        (uint256 iId0, uint256 iId1) = _getInternalIds(_id0, _id1);
        require(!_isLinked[iId0][iId1], "ALREADY_LINKED");
        _isLinked[iId0][iId1] = true;
        emit SetLink(_id0, _id1);
    }

    //external functions
    function mint(address to) external returns (uint256 tokenId) {
        require(isMinter[msg.sender], "UNAUTHORIZED");
        tokenId = getTokenId(to);
        _mint(to, tokenId);
        _totalSupply++;
        _internalId[tokenId] = _totalSupply; //_internalId starts from 1
    }

    function burn(uint256 tokenId) external {
        require(getTokenId(msg.sender) == tokenId, "UNAUTHORIZED");
        _burn(tokenId);
        _burnCount++;
        delete _internalId[tokenId];
        emit ResetLink(tokenId);
    }

    /**
        [0]: from msg.sender
        [1]: from target
    */
    function setLink(
        uint256 targetId,
        bytes[2] calldata sigs,
        uint256[2] calldata deadlines
    ) external {
        require(block.timestamp <= deadlines[0] && block.timestamp <= deadlines[1], "EXPIRED_DEADLINE");

        uint256 myId = getTokenId(msg.sender);

        _checkSignature(msg.sender, targetId, deadlines[0], sigs[0]);
        _useSignature(keccak256(sigs[0]));

        _checkSignature(address(uint160(targetId)), myId, deadlines[1], sigs[1]);
        _useSignature(keccak256(sigs[1]));

        _setLink(myId, targetId);
    }

    function breakLink(uint256 targetId) external {
        uint256 myId = getTokenId(msg.sender);
        (uint256 iId0, uint256 iId1) = _getInternalIds(myId, targetId);
        require(_isLinked[iId0][iId1], "NOT_LINKED");
        delete _isLinked[iId0][iId1];
        emit BreakLink(myId, targetId);
    }

    function cancelLinkSig(
        uint256 targetId,
        uint256 deadline,
        bytes calldata sig
    ) external {
        _checkSignature(msg.sender, targetId, deadline, sig);
        _useSignature(keccak256(sig));
        emit CancelLinkSig(msg.sender, targetId, deadline);
    }
}
