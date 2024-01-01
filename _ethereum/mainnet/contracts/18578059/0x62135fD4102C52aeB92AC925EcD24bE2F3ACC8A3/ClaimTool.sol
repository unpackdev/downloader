// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./MintInterface.sol";
import "./MintBatchInterface.sol";

contract ClaimTool is Ownable, EIP712 {
    bytes32 public constant CLAIM_TOKEN_CALL_HASH_TYPE =
    keccak256('Claim(address receiver,string id,uint256 amount)');
    bytes32 public constant CLAIM_NFT_CALL_HASH_TYPE =
    keccak256('Claim(address receiver,string id,uint256[] ids)');

    mapping(uint8 => uint8) private locked;

    mapping(string => bool) public claimed;
    address public signer;
    address public tokenAddress;
    address public nftAddress;

    constructor(address _tokenAddress, address _nftAddress) EIP712('Claim', '1') {
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner{
        tokenAddress = _tokenAddress;
    }

    function setNFTAddress(address _nftAddress) public onlyOwner{
        nftAddress = _nftAddress;
    }

    event ClaimToken(
        address indexed sender,
        string id,
        uint256 amount
    );

    event ClaimNFT(
        address indexed sender,
        string id,
        uint256[] ids
    );

    modifier lock(uint8 id) {
        require(locked[id] == 0, 'LOCKED');
        locked[id] = 1;
        _;
        locked[id] = 0;
    }

    function claimToken(
        string memory id,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external lock(0) {
        require(!claimed[id], 'Claimed');
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(CLAIM_TOKEN_CALL_HASH_TYPE, _msgSender(), keccak256(bytes(id)), amount))
        );
        require(
            signer != address(0) && ECDSA.recover(digest, v, r, s) == signer,
            'Invalid signer'
        );
        MintInterface(tokenAddress).mint(_msgSender(), amount);
        claimed[id] = true;
        emit ClaimToken(_msgSender(), id, amount);
    }

    function claimNFT(
        string memory id,
        uint256[] memory ids,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external lock(1) {
        require(!claimed[id], 'Claimed');
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(CLAIM_NFT_CALL_HASH_TYPE, _msgSender(), keccak256(bytes(id)), keccak256(abi.encodePacked(ids))))
        );
        require(
            signer != address(0) && ECDSA.recover(digest, v, r, s) == signer,
            'Invalid signer'
        );
        MintBatchInterface(nftAddress).mintBatch(_msgSender(), ids);
        claimed[id] = true;
        emit ClaimNFT(_msgSender(), id, ids);
    }

    function setSigner(address _signer) public onlyOwner {
        require(signer != _signer, 'Signer is same with previous one');
        signer = _signer;
    }
}
