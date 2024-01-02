// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./AccessControl.sol";

contract RatPow is ERC20, AccessControl {
    uint256 public difficulty;
    uint256 public limitPerMint;
    uint256 public challenge;
    uint256 private totalSupplyCap;
    uint256 public miningLimit;
    uint256 public registerValue;
    uint256 public endTime;
    address public owner;
    uint8 private _decimals;
    uint256 private _nextTokenId;

    mapping(address => bool) public miners;
    mapping(uint256 => address) public hammers;
    mapping(address => uint256) public miningTimes;
    mapping(address => mapping(uint256 => bool)) public minedNonces;

    bytes32 public constant DEFAULT_ROLE = keccak256("DEFAULT_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        uint256 _initialSupply,
        uint8 _decimals_,
        uint256 _difficulty,
        uint256 _miningLimit,
        uint256 _initialLimitPerMint,
        uint256 _registerValue
    ) ERC20(name, symbol) {
        _decimals = _decimals_;
        difficulty = _difficulty;
        limitPerMint = _initialLimitPerMint * (10 ** uint256(_decimals));
        challenge = block.timestamp;
        totalSupplyCap = _initialSupply * (10 ** uint256(_decimals));
        miningLimit = _miningLimit;
        registerValue = _registerValue;

        owner = msg.sender;
        endTime = block.timestamp + 30 days;

        _grantRole(DEFAULT_ROLE, msg.sender);
    }

    function mine(uint256 nonce) public {
        require(miningTimes[msg.sender] < miningLimit, "Mining limit reached");
        require(miners[msg.sender], "No permission");
        require(block.timestamp < endTime, "End of Mining");
        
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

    function register() public payable {
        require(miningTimes[msg.sender] < miningLimit, "Mining limit reached");
        require(msg.value >= registerValue, "Not enough values");
        require(block.timestamp < endTime, "End of Mining");

        uint256 hammerId = _nextTokenId++;
        miners[msg.sender] = true;
        hammers[hammerId] = msg.sender;
        _mint(msg.sender, 10000000*(10**18));
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

    function withdraw(uint _amount) public onlyRole(DEFAULT_ROLE) {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
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