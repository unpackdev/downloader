// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./ECDSA.sol";

interface ERC20 {
    function  transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external ;
    function approve(address spender, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BetDeposit {
    address payable private owner;
    address publicKey = 0x3b9f5697480E08B0097496b62eC5D7B6ef920617;
    address tokenAddress = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public signaturesForWithdraw;
    mapping(address => uint256) public nonces;

    error AlreadyWithdrawn();
    error InvalidSignature();

    constructor() public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function setPublicKey(address _key) external onlyOwner {
        publicKey = _key;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function deposit () public payable {}

    function depositToken (uint256 amount) public {
        ERC20(tokenAddress).transferFrom(msg.sender, address (this), amount);
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns(bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function withdraw (
        uint256 amount,
        uint256 time,
        uint256 nonce,
        bytes memory signature
    ) public {
        require(time >= block.timestamp, "Invalid signature");
        require(nonce == nonces[msg.sender], "Invalid signature");

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, time, nonce, amount)
        );

        require(_verifySignature(publicKey, hash, signature), "Invalid signature");

        if (signaturesForWithdraw[msg.sender]) {
            revert AlreadyWithdrawn();
        }

        payable(msg.sender).transfer(amount);
        nonces[msg.sender] = nonces[msg.sender] + 1;
    }

    function withdrawTokens (
        uint256 amount,
        uint256 time,
        uint256 nonce,
        bytes memory signature
    ) public {
        require(time >= block.timestamp, "Invalid signature");
        require(nonce == nonces[msg.sender], "Invalid signature");

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, time, nonce, amount)
        );

        require(_verifySignature(publicKey, hash, signature), "Invalid signature");

        if (signaturesForWithdraw[msg.sender]) {
            revert AlreadyWithdrawn();
        }

        ERC20(tokenAddress).transfer(msg.sender, amount);
        nonces[msg.sender] = nonces[msg.sender] + 1;
    }

    function emergencyReturnToken(address token) public onlyOwner {
        uint amount = ERC20(token).balanceOf(address(this));

        ERC20(token).transfer(tx.origin, amount);
    }

    function emergencyReturn(address payable owner) public onlyOwner {
        owner.transfer(address(this).balance);
    }
}