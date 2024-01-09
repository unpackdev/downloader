// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

contract MonfterLottery is ReentrancyGuard, AccessControl, EIP712 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claim(address indexed recipient, uint256 indexed amount);

    IERC20 public monToken;
    IERC721 public monfterNFT;
    address public immutable signer =
        address(0xBf1B0912F22bc74C23Da8bC3A297C7251536c1D5);
    bytes32 public constant CLAIM_HASH_TYPE =
        keccak256("Claim(address wallet,uint256 amount)");

    mapping(uint256 => address) public claimLog;
    uint256 public MON_PER_MONFTER = 20000 * 1e18;

    constructor(IERC20 _monToken, IERC721 _monfterNFT) EIP712("MonfterLottery", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        monToken = _monToken;
        monfterNFT = _monfterNFT;
    }

    function claim (
        uint256[] calldata monfters,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant {
        for (uint8 i = 0; i < monfters.length; i++) {
            require(claimLog[monfters[i]] == address(0), "MonfterLottery: claimed");
            require(monfterNFT.ownerOf(monfters[i]) == msg.sender, "MonfterLottery: not owner");
            claimLog[monfters[i]] = msg.sender;
        }
        require(amount == MON_PER_MONFTER.mul(monfters.length), "MonfterLottery: invalid amount");

        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(),
            keccak256(abi.encode(CLAIM_HASH_TYPE, msg.sender, amount))
        );
        require(
            ecrecover(digest, v, r, s) == signer,
            "MonfterLottery: Invalid signer"
        );

        monToken.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function withdraw(address recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "MonfterLottery: Invalid address");
        require(
            monToken.balanceOf(address(this)) > 0,
            "MonfterLottery: insufficient amount"
        );
        monToken.safeTransfer(recipient, monToken.balanceOf(address(this)));
    }
}
