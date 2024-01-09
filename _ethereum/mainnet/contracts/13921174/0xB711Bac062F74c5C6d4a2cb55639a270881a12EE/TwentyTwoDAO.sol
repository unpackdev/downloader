// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract TwentyTwoDAO is ERC20, EIP712 {
    uint256 public constant MAX_SUPPLY = uint248(222222222 ether);

    // for DAO.
    uint256 public constant AMOUNT_DAO = MAX_SUPPLY / 100 * 22;
    address public constant ADDR_DAO = 0xA28BD221F2785212D76203C1AA9fcB80dfECdA28;

    // for team
    uint256 public constant AMOUNT_TEAM = MAX_SUPPLY / 100 * 22;
    address public constant ADDR_TEAM = 0x767A2D5C203E4d2201f4Fa0Ff80fAEad0187E02F;

    // for airdrop
    uint256 public constant AMOUNT_AIRDROP = MAX_SUPPLY - (AMOUNT_DAO + AMOUNT_TEAM);

    constructor(string memory _name, string memory _symbol, address _signer) ERC20(_name, _symbol) EIP712("22", "1") {
        _mint(ADDR_DAO, AMOUNT_DAO);
        _mint(ADDR_TEAM, AMOUNT_TEAM);
        _totalSupply = AMOUNT_DAO + AMOUNT_TEAM;
        cSigner = _signer;
    }

    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 amount)");

    address public immutable cSigner;

    function claim(uint248 amount, uint8 v, bytes32 r, bytes32 s) external {
        uint256 total = _totalSupply + amount;
        require(total <= MAX_SUPPLY, "22DAO: Exceed max supply");
        require(minted(msg.sender) == 0, "22DAO: Claimed");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        amount,msg.sender
                    )
                )
            )
        );
        require(ecrecover(digest, v, r, s) == cSigner, "22DAO: Invalid signer");
        _totalSupply = total;
        _mint(msg.sender, amount);
    }
}