// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract NFTStake1155 is Ownable, Pausable {
    /* Variable */
    using SafeMath for uint256;
    address signerAddress;
    address holderAddress;
    address tokenAddress;
    mapping(address => mapping(uint256 => bool)) internal stakeMap;

    /* Event */
    event Stake1155(address indexed fromAddress, address indexed toAddress, address indexed tokenAddress, uint256[] tokenIds, string nonce);
    event Redeem1155(address indexed fromAddress, address indexed toAddress, address indexed tokenAddress, uint256[] tokenIds, string nonce);

    constructor (){}

    // setup
    function setHolderAddress(address _holderAddress) public onlyOwner {
        holderAddress = _holderAddress;
    }

    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
    //end setup

    function stake1155(uint256[] memory tokenIds, bytes32 hash, bytes memory signature, uint256 blockHeight, string memory nonce) public {
        require(blockHeight >= block.number, "The block has expired!");
        require(hashStakeTransaction(tokenIds, tokenAddress, msg.sender, blockHeight, nonce) == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        ERC1155 stakeNFTContract = ERC1155(tokenAddress);
        uint256[] memory _amounts = _generateAmountArray(tokenIds.length);
        stakeNFTContract.safeBatchTransferFrom(msg.sender, holderAddress, tokenIds, _amounts, abi.encode(msg.sender));
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakeMap[msg.sender][tokenIds[i]] = true;
        }
        emit Stake1155(msg.sender, holderAddress, tokenAddress, tokenIds, nonce);
    }

    function redeem1155(uint256[] memory tokenIds, bytes32 hash, bytes memory signature, uint256 blockHeight, string memory nonce) public {
        require(blockHeight >= block.number, "The block has expired!");
        require(hashRedeemTransaction(tokenIds, tokenAddress, msg.sender, blockHeight, nonce) == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        bool isIn = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            isIn = isIn && stakeMap[msg.sender][tokenIds[i]];
        }
        require(isIn, "No such staking record!");
        assert(_redeem(tokenIds, msg.sender));
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakeMap[msg.sender][tokenIds[i]] = false;
        }
        emit Redeem1155(holderAddress, msg.sender, tokenAddress, tokenIds, nonce);
    }

    function _redeem(uint256[] memory redeemTokenIds, address sender) private returns (bool){
        ERC1155 stakeNFTContract = ERC1155(tokenAddress);
        uint256[] memory _amounts = _generateAmountArray(redeemTokenIds.length);
        stakeNFTContract.safeBatchTransferFrom(holderAddress, sender, redeemTokenIds, _amounts, abi.encode(msg.sender));
        return true;
    }

    function _generateAmountArray(uint256 _arrayLength) internal pure returns (uint256 [] memory){
        uint256[] memory amountArray = new uint256[](_arrayLength);
        for (uint256 i = 0; i < _arrayLength; i++) {
            amountArray[i] = 1;
        }
        return amountArray;
    }

    function checkStakeStatus(address _owner, uint256 _tokenId) public view returns (bool){
        return (stakeMap[_owner][_tokenId]);
    }

    function hashStakeTransaction(uint256[] memory _tokenIds, address _tokenAddress, address sender, uint256 blockHeight, string memory nonce) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_tokenIds, _tokenAddress, sender, blockHeight, nonce, "stake_1155"))
            )
        );
        return hash;
    }

    function hashRedeemTransaction(uint256[] memory tokenIds, address _tokenAddress, address sender, uint256 blockHeight, string memory nonce) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(tokenIds, _tokenAddress, sender, blockHeight, nonce, "redeem_1155"))
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return signerAddress == recoverSigner(hash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function removeByValue(address[] storage array, address value) internal {
        uint index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (isIn) {
            removeByIndex(array, index);
        }
    }

    function firstIndexOf(address[] storage array, address value) internal view returns (bool, uint) {
        if (array.length == 0) {
            return (false, 0);
        }
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeByIndex(address[] storage array, uint index) internal {
        require(index < array.length, "ArrayForAddress: index out of bounds");
        while (index < array.length - 1) {
            array[index] = array[index + 1];
        }
        array.pop();
    }
}
