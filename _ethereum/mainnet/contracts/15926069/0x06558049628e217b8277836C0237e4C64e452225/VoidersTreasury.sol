// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./AccessControlEnumerable.sol";
import "./ERC721A.sol";

contract VoidersTreasury is AccessControlEnumerable, ERC721A__IERC721Receiver {
    uint8 public constant SIGNATURE_LENGTH = 65;
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    uint256 public nextProposalIndex;
    uint256 public minimumQuorum;

    modifier nonEmptyAddress(address _address) {
        require(_address != address(0), "Address cannot be 0");
        _;
    }

    constructor(address[] memory _owners, uint256 _minimumQuorum) {
        uint256 length = _owners.length;
        for (uint256 i = 0; i < length; i++) {
            require(_owners[i] != address(0), "Owner can't be empty.");
            _grantRole(KEEPER_ROLE, _owners[i]);
        }
        require(_minimumQuorum > 0, "Min quorum should be greater than zero.");
        require(
            _minimumQuorum <= length,
            "Min quorum should be less than owners length."
        );
        minimumQuorum = _minimumQuorum;
    }

    function addKeeper(address _newOwner, bytes memory _concatSignatures)
        external
        onlyRole(KEEPER_ROLE)
        nonEmptyAddress(_newOwner)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(nextProposalIndex, _newOwner)
        );
        _checkSign(_concatSignatures, hash);
        _grantRole(KEEPER_ROLE, _newOwner);
    }

    function transfer721(
        address _token,
        address _to,
        uint256 _tokenId,
        bytes memory _concatSignatures
    )
        external
        onlyRole(KEEPER_ROLE)
        nonEmptyAddress(_token)
        nonEmptyAddress(_to)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(nextProposalIndex, _token, _to, _tokenId)
        );
        _checkSign(_concatSignatures, hash);
        IERC721A(_token).safeTransferFrom(address(this), _to, _tokenId);
    }

    function bulkTransfer721(
        address _token,
        address _to,
        uint256[] calldata _tokenIds,
        bytes memory _concatSignatures
    )
        external
        onlyRole(KEEPER_ROLE)
        nonEmptyAddress(_to)
        nonEmptyAddress(_token)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(nextProposalIndex, _token, _to, _tokenIds)
        );
        _checkSign(_concatSignatures, hash);
        uint256 length = _tokenIds.length;
        for (uint256 i; i < length; i++) {
            IERC721A(_token).safeTransferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function removeKeeper(bytes memory _concatSignatures, address _oldOwner)
        external
        onlyRole(KEEPER_ROLE) nonEmptyAddress(_oldOwner)
    {
        uint256 ownersCount = getRoleMemberCount(KEEPER_ROLE);
        require(
            ownersCount > 1,
            "You are the last owner. Transfer your ownership!"
        );
        require(
            minimumQuorum < ownersCount,
            "Minimum quorum can't be more than owners."
        );
        bytes32 hash = keccak256(abi.encodePacked(nextProposalIndex, _oldOwner));
        _checkSign(_concatSignatures, hash);
        _revokeRole(KEEPER_ROLE, _oldOwner);
    }

    function setMinimumQuorum(bytes memory _concatSignatures, uint256 _quorum)
        external
        onlyRole(KEEPER_ROLE)
    {
        require(_quorum > 0, "Min quorum must be greater than zero.");
        require(
            minimumQuorum <= getRoleMemberCount(KEEPER_ROLE),
            "Min quorum can't be less than keepers count"
        );
        bytes32 hash = keccak256(abi.encodePacked(nextProposalIndex, _quorum));
        _checkSign(_concatSignatures, hash);
        minimumQuorum = _quorum;
    }

    function _checkSign(bytes memory _concatSignatures, bytes32 _hash)
        internal
    {
        uint256 signatureLength = SIGNATURE_LENGTH;
        uint256 concatLength = _concatSignatures.length;
        require(concatLength % signatureLength == 0, "Wrong signature length.");
        uint256 signaturesCount;
        assembly {
            signaturesCount := div(concatLength, signatureLength)
        }
        address[] memory ownersAddresses = new address[](signaturesCount);
        require(
            signaturesCount >= minimumQuorum,
            "Min quorum must be reached."
        );
        for (uint256 i; i < signaturesCount; i++) {
            address ownerAddress = ecOffsetRecover(
                _hash,
                _concatSignatures,
                i * signatureLength
            );
            require(
                hasRole(KEEPER_ROLE, ownerAddress),
                "Signer is not an owner or signed invalid data."
            );

            for (uint256 j; j < i; j++) {
                require(
                    ownerAddress != ownersAddresses[j],
                    "Owner must not be duplicated."
                );
            }
            ownersAddresses[i] = ownerAddress;
        }
        nextProposalIndex++;
    }

    function getSetMinQuorumHash(uint256 _nextProposalIndex, uint256 _quorum)
        public
        pure
        returns (bytes32 signature)
    {
        bytes32 newHash = keccak256(
            abi.encodePacked(_nextProposalIndex, _quorum)
        );
        return newHash;
    }

    function getRemoveKeeperHash(uint256 _nextProposalIndex, address _owner)
        public
        pure
        returns (bytes32 signature)
    {
        bytes32 newHash = keccak256(
            abi.encodePacked(_nextProposalIndex, _owner)
        );
        return newHash;
    }

    function getAddKeeperHash(uint256 _nextProposalIndex, address _owner)
        public
        pure
        returns (bytes32 signature)
    {
        bytes32 newHash = keccak256(
            abi.encodePacked(_nextProposalIndex, _owner)
        );
        return newHash;
    }

    function getTransfer721Hash(
        uint256 _nextProposalIndex,
        address _token,
        address _to,
        uint256 _tokenId
    ) public pure returns (bytes32 signature) {
        bytes32 newHash = keccak256(
            abi.encodePacked(_nextProposalIndex, _token, _to, _tokenId)
        );
        return newHash;
    }

    function getBulkTransfer721Hash(
        uint256 _nextProposalIndex,
        address _token,
        address _to,
        uint256[] calldata _tokenIds
    ) public pure returns (bytes32 signature) {
        bytes32 newHash = keccak256(
            abi.encodePacked(_nextProposalIndex, _token, _to, _tokenIds)
        );
        return newHash;
    }

    function toEthSignedMessageHash(bytes32 hash)
        public
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function ecOffsetRecover(
        bytes32 hash,
        bytes memory signature,
        uint256 offset
    ) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, add(offset, 0x20)))
            s := mload(add(signature, add(offset, 0x40)))
            v := byte(0, mload(add(signature, add(offset, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        }

        // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        // hash = keccak256(abi.encodePacked(prefix, hash));
        // solium-disable-next-line arg-overflow
        return ecrecover(toEthSignedMessageHash(hash), v, r, s);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
