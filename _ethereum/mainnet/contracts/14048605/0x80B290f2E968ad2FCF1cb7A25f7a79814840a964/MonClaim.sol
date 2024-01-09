// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

contract MonClaim is ReentrancyGuard, AccessControl, EIP712 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claim(address indexed recipient, uint256 indexed amount);

    IERC20 public monToken;
    address public immutable signer =
        address(0xBf1B0912F22bc74C23Da8bC3A297C7251536c1D5);
    bytes32 public constant CLAIM_HASH_TYPE =
        keccak256("Claim(address wallet,uint256 amount)");

    mapping(address => bool) public claimLog;
    uint256 public counter;

    constructor(IERC20 _monToken) EIP712("MonClaim", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        monToken = _monToken;
    }

    function claim(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant {
        require(!claimLog[msg.sender], "MonClaim: claimed");

        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(),
            keccak256(abi.encode(CLAIM_HASH_TYPE, msg.sender, amount))
        );
        require(
            ecrecover(digest, v, r, s) == signer,
            "MonClaim: Invalid signer"
        );

        counter += 1;
        claimLog[msg.sender] = true;
        monToken.transfer(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

    function withdraw(address recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "MonClaim: Invalid address");
        require(
            monToken.balanceOf(address(this)) > 0,
            "MonClaim: insufficient amount"
        );
        monToken.safeTransfer(recipient, monToken.balanceOf(address(this)));
    }
}
