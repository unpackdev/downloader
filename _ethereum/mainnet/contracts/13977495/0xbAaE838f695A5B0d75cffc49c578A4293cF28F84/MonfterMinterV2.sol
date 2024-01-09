// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

interface MonfterNFT {
    function safeMint(address) external;
}

contract MonfterMinterV2 is ReentrancyGuard, EIP712 {
    using SafeMath for uint256;

    uint256 public MAX_PUB_MINT = 6202;
    MonfterNFT public monfterNft =
        MonfterNFT(0x5aD0F6563f83b68B69eD3db5Dc69E0748A8A2e5c);
    address payable public wallet =
        payable(0xcded06320383a335a377E26F4fF815631b55A075);

    address public immutable signer =
        address(0xBf1B0912F22bc74C23Da8bC3A297C7251536c1D5);

    bytes32 public constant OS_HASH_TYPE = keccak256("osMint(address wallet)");
    bytes32 public constant TRADER_HASH_TYPE =
        keccak256("traderMint(address wallet)");

    // base mint price
    uint256 public preMintPrice = 0.02 ether;
    uint256 public pubMintPrice = 0.06 ether;

    uint256 public MAX_TRADER_MINT = 500;

    uint256 public osMintCounter;
    uint256 public traderMintCounter;
    uint256 public pubMintCounter;
    mapping(address => bool) public osMintLog;
    mapping(address => bool) public traderMintLog;

    event Mint(address indexed account, uint256 indexed amount);

    constructor() EIP712("Monfters Club", "1") {}

    function pubMint(uint256 amount) public payable nonReentrant {
        uint256 weiAmount = msg.value;
        require(
            weiAmount >= pubMintPrice.mul(amount),
            "MonfterMinter: invalid price"
        );
        require(amount <= 10, "MonfterMinter: invalid amount");
        require(
            pubMintCounter.add(amount) < MAX_PUB_MINT,
            "MonfterMinter: invalid amount"
        );

        wallet.transfer(weiAmount);
        pubMintCounter.add(amount);

        for (uint256 i = 0; i < amount; i++) {
            monfterNft.safeMint(msg.sender);
        }
        emit Mint(msg.sender, amount);
    }

    function traderMint(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        uint256 weiAmount = msg.value;
        require(weiAmount >= preMintPrice, "MonfterMinter: invalid price");
        require(!traderMintLog[msg.sender], "MonfterMinter: already mint");
        require(
            traderMintCounter.add(1) <= MAX_TRADER_MINT,
            "MonfterMinter: mint out"
        );

        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(),
            keccak256(abi.encode(TRADER_HASH_TYPE, msg.sender))
        );
        require(
            ecrecover(digest, v, r, s) == signer,
            "MonfterMinterV2: Invalid signer"
        );

        wallet.transfer(weiAmount);
        traderMintCounter = traderMintCounter.add(1);
        traderMintLog[msg.sender] = true;
        monfterNft.safeMint(msg.sender);
        emit Mint(msg.sender, 1);
    }

    function osMint(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        require(!osMintLog[msg.sender], "already mint");

        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(),
            keccak256(abi.encode(OS_HASH_TYPE, msg.sender))
        );
        require(
            ecrecover(digest, v, r, s) == signer,
            "MonfterMinterV2: Invalid signer"
        );

        osMintCounter = osMintCounter.add(1);
        osMintLog[msg.sender] = true;
        monfterNft.safeMint(msg.sender);
        emit Mint(msg.sender, 1);
    }
}
