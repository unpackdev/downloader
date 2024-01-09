// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract Dev3 is ERC20, EIP712, Ownable {
    mapping(address=>bool) public claimed;
    uint256 public constant MAX_SUPPLY = 10000000000000000;
    uint256 public constant claimPeriodEnds = 1654041600;
    address public immutable cSigner;
    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 amount)");

    constructor(address _signer) ERC20("DEV3", "DEV3") EIP712("Dev3Dao", "1") {
        cSigner = _signer;
        _mint(address(this), MAX_SUPPLY);
    }

    function claim(uint256 amount, bytes32 r, bytes32 s, uint8 v) external {
        require(block.timestamp <= claimPeriodEnds, "Claim period ended");
        require(!claimed[msg.sender], "Tokens already claimed.");
        require(balanceOf(address(this)) >= amount, "Max supply reached");
        bytes32 digest = ECDSA.toTypedDataHash(_domainSeparatorV4(),keccak256(abi.encode(MINT_CALL_HASH_TYPE, msg.sender, amount)));
        require(ecrecover(digest, v, r, s) == cSigner, "Invalid signer");
        claimed[msg.sender] = true;
        _transfer(address(this), msg.sender, amount);
    }

    function sweep(address dest) public onlyOwner {
        require(block.timestamp > claimPeriodEnds, "Claim period not yet ended");
        _transfer(address(this), dest, balanceOf(address(this)));
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}