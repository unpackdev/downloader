// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "ERC20.sol";
import {SafeERC20, IERC20} from "SafeERC20.sol";
import "Upgradeable.sol";

error NotLocked();
error ExpiredPermit();
error UninitializedDomainSeparator();
error InvalidPermitSignature();
error TokenIsReceiver();
error Unauthorized();

contract FungToken is Upgradeable, ERC20 {

    event TokenUnlock(uint256 timestamp);

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;

    bool public locked;
    mapping(address => bool) public movers;

    bool private _initialized;

    constructor() ERC20(name(), symbol()) {}

    function initialize() public onlyOwner {
        if (_initialized == true) {
            revert Unauthorized();
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        locked = true;
        movers[msg.sender] = true;

        _mint(msg.sender, totalSupply());

        _initialized = true;
    }

    function unlock() public onlyOwner {
        if (locked == false) {
            revert NotLocked();
        }
        locked = false;
        emit TokenUnlock(block.timestamp);
    }
    function setMover(address user, bool canMove) public onlyOwner {
        movers[user] = canMove;
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }

    function name() public view override returns (string memory) {
        return "Fung Token";
    }

    function symbol() public view override returns (string memory) {
        return "FUNG";
    }

    function totalSupply() public view override returns (uint256) {
        return 1_000_000_000e18;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (deadline < block.timestamp) {
            revert ExpiredPermit();
        }
        if (DOMAIN_SEPARATOR == bytes32(0)) {
            revert UninitializedDomainSeparator();
        }
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))));
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != owner) {
            revert InvalidPermitSignature();
        }
        _approve(owner, spender, value);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (to == address(this)) {
            revert TokenIsReceiver();
        }
        if (locked == true && movers[msg.sender] == false) {
            revert Unauthorized();
        }

        super._update(from, to, value);
    }
}
