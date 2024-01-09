// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ModifiedERC20.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract GasDAO is ERC20, EIP712 {
    uint256 public constant MAX_SUPPLY = 1e14 ether;

    // for DAO
    uint256 public constant AMOUNT_DAO = MAX_SUPPLY / 100 * 15;
    address public constant ADDR_DAO = 0x05c1b6e50dFa64D96c4b2f3B881ef807a2dCC286;

    // for team
    uint256 public constant AMOUNT_TEAM = MAX_SUPPLY / 100 * 5;
    address public constant ADDR_TEAM = 0x27A8894577B20f492f078Cdc548949548ab50A43;

    // for liquidity providers
    uint256 public constant AMOUNT_LP = MAX_SUPPLY / 100 * 20;
    address public constant ADDR_LP = 0xF5b0B8380D6F7C61Ae01F59CB6b4bD082F3f7445;

    // for airdrop
    uint256 public constant AMOUNT_AIRDROP = MAX_SUPPLY - (AMOUNT_DAO + AMOUNT_TEAM + AMOUNT_LP);


    constructor() ERC20("GasDAO", "GAS") EIP712("GasDAO", "1") {
        _mint(ADDR_DAO, AMOUNT_DAO);
        _mint(ADDR_TEAM, AMOUNT_TEAM);
        _mint(ADDR_LP, AMOUNT_LP);
        _totalSupply = AMOUNT_DAO + AMOUNT_TEAM + AMOUNT_LP;
        cSigner = 0x9a5da01DcF5Ae9fd5B1CB39e8dAf6512e13EdE9a;
    }

    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 amount)");

    address public cSigner;

    function claim(uint256 amountV, bytes32 r, bytes32 s) external {
        uint256 amount = uint248(amountV);
        uint8 v = uint8(amountV >> 248);
        uint256 total = _totalSupply + amount;
        require(total <= MAX_SUPPLY, "GasDAO: Exceed max supply");
        require(minted(msg.sender) == 0, "GasDAO: Claimed");
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            ECDSA.toTypedDataHash(_domainSeparatorV4(),
                keccak256(abi.encode(MINT_CALL_HASH_TYPE, msg.sender, amount))
        )));
        require(ecrecover(digest, v, r, s) == cSigner, "GasDAO: Invalid signer");
        _totalSupply = total;
        _mint(msg.sender, amount);
    }
}
