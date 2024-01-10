// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract TokenTransaction is Pausable, Ownable {
    using SafeMath for uint256;
    address internal divideWalletAddress;
    address internal signerAddress;
    mapping(string => bool) internal hasExecuted;

    constructor() {}

    event TokenPay(
        address indexed operatorAddress,
        address indexed toAddress,
        uint256 indexed amount,
        address tokenAddress,
        uint256 divideAmount,
        string nonce
    );
    event TokenCollect(
        address indexed operatorAddress,
        address indexed fromAddress,
        uint256 indexed amount,
        address tokenAddress,
        string nonce
    );
    event StakeSuccess(
        address indexed operatorAddress,
        address indexed toAddress,
        uint256 indexed amount,
        address tokenAddress,
        string nonce
    );
    event RedeemSuccess(
        address indexed operatorAddress,
        address indexed fromAddress,
        uint256 indexed amount,
        address tokenAddress,
        string nonce
    );

    //******SET UP******
    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    function setDivideWalletAddress(address _divideWalletAddress) public onlyOwner {
        divideWalletAddress = _divideWalletAddress;
    }
    //******END SET UP******/

    function tokenPay(
        uint256 amount,
        address tokenAddress,
        address toAddress,
        uint256 divideAmount,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) public whenNotPaused {
        require(!hasExecuted[nonce], "The method has been executed!");
        hasExecuted[nonce] = true;
        require(amount > 0, "The amount must more than 0!");
        require(
            hashTokenPay(msg.sender, amount, tokenAddress, toAddress, divideAmount, blockHeight, nonce) == hash,
            "Invalid hash!"
        );
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        require(blockHeight >= block.number, "The block has expired!");
        ERC20 tokenContract = ERC20(tokenAddress);
        if (divideAmount != 0) {
            require(tokenContract.transferFrom(msg.sender, divideWalletAddress, divideAmount));
            require(tokenContract.transferFrom(msg.sender, toAddress, amount.sub(divideAmount)));
        } else {
            require(tokenContract.transferFrom(msg.sender, toAddress, amount));
        }
        emit TokenPay(msg.sender, toAddress, amount, tokenAddress, divideAmount, nonce);
    }

    function tokenCollect(
        uint256 amount,
        address tokenAddress,
        address fromAddress,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) public whenNotPaused {
        require(!hasExecuted[nonce], "The method has been executed!");
        hasExecuted[nonce] = true;
        require(amount > 0, "The amount must more than 0!");
        require(
            hashTokenCollect(msg.sender, amount, tokenAddress, fromAddress, blockHeight, nonce) == hash,
            "Invalid hash!"
        );
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        require(blockHeight >= block.number, "The block has expired!");
        ERC20 tokenContract = ERC20(tokenAddress);
        tokenContract.transferFrom(fromAddress, msg.sender, amount);
        emit TokenCollect(msg.sender, fromAddress, amount, tokenAddress, nonce);
    }

    function stakeToken(
        uint256 amount,
        address tokenAddress,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) public whenNotPaused {
        require(!hasExecuted[nonce], "The method has been executed!");
        hasExecuted[nonce] = true;
        require(
            stakeRedeemHash(amount, msg.sender, tokenAddress, blockHeight, nonce, "stake_token") == hash,
            "Invalid hash!"
        );
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        require(blockHeight >= block.number, "The block has expired!");
        require(_stakeToken(tokenAddress, amount), "Stake token failed!");
        emit StakeSuccess(msg.sender, divideWalletAddress, amount, tokenAddress, nonce);
    }

    function _stakeToken(address tokenAddress, uint256 amount) internal returns (bool) {
        ERC20 tokenContract = ERC20(tokenAddress);
        tokenContract.transferFrom(msg.sender, divideWalletAddress, amount);
        return true;
    }

    function redeemToken(
        uint256 amount,
        address tokenAddress,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) public whenNotPaused {
        require(!hasExecuted[nonce], "The method has been executed!");
        hasExecuted[nonce] = true;
        require(
            stakeRedeemHash(amount, msg.sender, tokenAddress, blockHeight, nonce, "redeem_token") == hash,
            "Invalid hash!"
        );
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        require(blockHeight >= block.number, "The block has expired!");
        require(_redeemToken(tokenAddress, amount), "UnStake token failed!");
        emit RedeemSuccess(msg.sender, divideWalletAddress, amount, tokenAddress, nonce);
    }

    function _redeemToken(address tokenAddress, uint256 amount) internal returns (bool) {
        ERC20 tokenContract = ERC20(tokenAddress);
        tokenContract.transferFrom(divideWalletAddress, msg.sender, amount);
        return true;
    }

    function hashTokenPay(
        address _operatorAddress,
        uint256 _amount,
        address _tokenAddress,
        address _toAddress,
        uint256 _divideAmount,
        uint256 _blockHeight,
        string memory _nonce
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        _operatorAddress,
                        _amount,
                        _tokenAddress,
                        _toAddress,
                        _divideAmount,
                        _blockHeight,
                        _nonce,
                        "token_pay"
                    )
                )
            )
        );
        return hash;
    }

    function hashTokenCollect(
        address _operatorAddress,
        uint256 _amount,
        address _tokenAddress,
        address _fromAddress,
        uint256 _blockHeight,
        string memory _nonce
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        _operatorAddress,
                        _amount,
                        _tokenAddress,
                        _fromAddress,
                        _blockHeight,
                        _nonce,
                        "token_collect"
                    )
                )
            )
        );
        return hash;
    }

    function stakeRedeemHash(
        uint256 amount,
        address sender,
        address tokenAddress,
        uint256 blockNumber,
        string memory nonce,
        string memory key
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(amount, sender, tokenAddress, blockNumber, nonce, key))
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
        return signerAddress == recoverSigner(hash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
