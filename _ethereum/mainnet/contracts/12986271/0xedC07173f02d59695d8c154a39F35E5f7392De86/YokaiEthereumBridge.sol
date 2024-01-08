// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "./IERC721Receiver.sol";
import "./Ownable.sol";

interface IYokaiMasks {
    function mintMaskFromBridge(address _to, uint256 _mintIndex) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function tokenExists(uint256 _tokenId) external view returns (bool);
}

contract YokaiMasksEthereumBridge is IERC721Receiver, Ownable {
    // Signer address
    address public signerAddress;

    // Address of the Yokai Masks Ethereum contract
    address public yokaiMasksContract;

    // Nonces for tracking mint transactions
    mapping(address => mapping(uint256 => bool)) public processedNonces;

    event SentToBridge(
        address indexed from,
        uint256 indexed mintIndex,
        uint256 indexed date,
        uint256 nonce,
        bytes signature
    );

    event MaskClaimed(
        address indexed to,
        uint256 indexed mintIndex,
        uint256 indexed date,
        uint256 nonce,
        bytes signature
    );

    constructor() {
        signerAddress = 0x13cacbc303b5d45164e31E6b6d73c1c445b4BA52;
    }

     /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function sendMaskToBridge(uint256 _mintIndex, uint256 _nonce, bytes calldata _signature) external {
        address from = msg.sender;
        bytes32 message = prefixed(keccak256(abi.encodePacked(
            from,
            _mintIndex,
            _nonce
        )));

        require(recoverSigner(message, _signature) == signerAddress, 'Wrong signature');
        require(processedNonces[from][_nonce] == false, 'Transfer already processed');

        processedNonces[from][_nonce] = true;

        IYokaiMasks(yokaiMasksContract).safeTransferFrom(msg.sender, address(this), _mintIndex);
        
        emit SentToBridge(msg.sender, _mintIndex, block.timestamp, _nonce, _signature);
    }

    function claimMask(uint256 _mintIndex, uint256 _nonce, bytes calldata _signature) external {
        address from = msg.sender;
        bytes32 message = prefixed(keccak256(abi.encodePacked(
            from,
            _mintIndex,
            _nonce
        )));

        require(recoverSigner(message, _signature) == signerAddress, 'Wrong signature');
        require(processedNonces[from][_nonce] == false, 'Transfer already processed');

        processedNonces[from][_nonce] = true;

        if (
            IYokaiMasks(yokaiMasksContract).tokenExists(_mintIndex) &&
            IYokaiMasks(yokaiMasksContract).ownerOf(_mintIndex) == address(this)
        ) {
            IYokaiMasks(yokaiMasksContract).safeTransferFrom(address(this), msg.sender, _mintIndex);
        } else {
            IYokaiMasks(yokaiMasksContract).mintMaskFromBridge(msg.sender, _mintIndex);
        }
        
        emit MaskClaimed(msg.sender, _mintIndex, block.timestamp, _nonce, _signature);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            '\x19Ethereum Signed Message:\n32', 
            hash
        ));
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    /**
     * @dev Update signer address by the owner
     */
    function setSigner(address payable _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Set the Yokai Masks Ethereum contract address
     */
    function setYokaiMasksContract(address _address) external onlyOwner {
        yokaiMasksContract = _address;
    }
}
