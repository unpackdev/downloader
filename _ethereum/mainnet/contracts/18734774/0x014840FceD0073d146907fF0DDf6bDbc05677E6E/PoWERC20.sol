// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PoWERC20 is ERC20 {
    uint256 public difficulty;
    uint256 public limitPerMint;
    uint256 public challenge;
    uint256 public totalSupplyCap;
    uint256 public miningLimit;
    uint8 private _decimals;

    mapping(address => uint256) public miningTimes;
    mapping(address => mapping(uint256 => bool)) public minedNonces;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _initialSupply,
        uint8 _decimals_,
        uint256 _difficulty,
        uint256 _miningLimit,
        uint256 _initialLimitPerMint
    ) ERC20(name, symbol) {
        _decimals = _decimals_;
        difficulty = _difficulty;
        limitPerMint = _initialLimitPerMint * (10 ** uint256(_decimals));
        challenge = block.timestamp;
        totalSupplyCap = _initialSupply * (10 ** uint256(_decimals));
        miningLimit = _miningLimit;
    }

    function mine(uint256 nonce) public {
        require(miningTimes[msg.sender] < miningLimit, "Mining limit reached");
        require(
            totalSupply() + limitPerMint <= totalSupplyCap,
            "Total supply cap exceeded"
        );
        require(
            !minedNonces[msg.sender][nonce],
            "Nonce already used for mining"
        );

        uint256 hash = uint256(
            keccak256(abi.encodePacked(challenge, msg.sender, nonce))
        );
        require(
            hash < ~uint256(0) >> difficulty,
            "Hash does not meet difficulty requirement"
        );

        _mint(msg.sender, limitPerMint);

        miningTimes[msg.sender]++;
        minedNonces[msg.sender][nonce] = true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(
            totalSupply() >= totalSupplyCap,
            "Transfer not allowed until max supply is reached"
        );
        return super.transfer(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function getLimitPerMint() public view returns (uint256) {
        return limitPerMint;
    }

    function getRemainingSupply() public view returns (uint256) {
        return totalSupplyCap - totalSupply();
    }
}