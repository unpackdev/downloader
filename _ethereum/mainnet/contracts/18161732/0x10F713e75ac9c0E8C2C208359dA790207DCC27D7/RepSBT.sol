// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1238URIStorage.sol";
import "./Address.sol";

contract RepSBT is ERC1238, ERC1238URIStorage {
    using Address for address;
    address public owner;
    mapping(address => uint256) private _addressToIds;
    uint256 private _num = 0;
    address private _signer;

    constructor(address owner_, string memory baseURI_) ERC1238(baseURI_) {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: sender is not the owner");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1238, ERC1238URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        uint64 _point,
        string memory _uri,
        bytes memory _signedData,
        bytes calldata data
    ) external {
        require (_balances[_addressToIds[msg.sender]][msg.sender] == 0, "Not allowed users to get more than 1 NFTs");

        bytes32 hashData = keccak256(abi.encodePacked(_uri));
        bytes32 sigHash = keccak256(abi.encodePacked(hashData, _point));
        require (verifySignature(sigHash, _signedData, _signer) == true, 'signed permit test error');

        _num = _num + 1;
        _mint(msg.sender, _num, 1, data);
        _setTokenURI(_num, _uri);
        _addressToIds [msg.sender] = _num;
    }

    function burn() external {
        _burnAndDeleteURI(msg.sender, _addressToIds [msg.sender], 1);
    }

    function setTokenURI(uint64 _point, string memory _uri, bytes memory _signedData) external {
        bytes32 hashData = keccak256(abi.encodePacked(_uri));
        bytes32 sigHash = keccak256(abi.encodePacked(hashData, _point));
        require (verifySignature(sigHash, _signedData, _signer) == true, 'signed permit test error');

        _setTokenURI (_addressToIds[msg.sender], _uri);
    }

    function getTokenURI(address _account) external view returns (string memory) {
        return tokenURI(_addressToIds[_account]);
    }

    function getTokenId(address _account) external view returns (uint256) {
        return _addressToIds[_account];
    }

    function setSignedAddress(address signer_) external onlyOwner {
        _signer = signer_;
    }

    /**
     * @dev Destroys `amount` of tokens with id `id` owned by `from` and deletes the associated URI.
     *
     * Requirements:
     *  - A token URI must be set.
     *  - All tokens of this type must have been burned.
     */
    function _burnAndDeleteURI(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        super._burn(from, id, amount);

        _deleteTokenURI(id);
    }

    function verifySignature(bytes32 hash, bytes memory signature, address signer) internal pure returns (bool) {
        require(signature.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        address addr = ecrecover(prefixedHash, v, r, s);
        return addr == signer;
    }
}