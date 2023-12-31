// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./draft-EIP712.sol";

contract ERC20MintablePauseable is
    EIP712,
    ERC20Burnable,
    ERC20Pausable,
    AccessControlEnumerable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(address => bool) private blackList;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) EIP712("PermitToken", "1.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _mint(owner, initialSupply);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "forbidden");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        require(!blackList[from], "forbidden");
        super._beforeTokenTransfer(from, to, amount);
    }

    function setBlackList(address account) public onlyAdmin {
        blackList[account] = !blackList[account];
    }

    function getBlackList(address account)
        public
        view
        onlyAdmin
        returns (bool)
    {
        return blackList[account];
    }

    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have minter role to mint"
        );
        _mint(to, amount);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(deadline >= block.timestamp, "expired!");
        // hash调用方法和参数
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            )
        );
        // 结构化hash
        bytes32 hash = _hashTypedDataV4(structHash);
        // 还原签名人
        address signer = ECDSA.recover(hash, signature);
        require(owner == signer, "Permit: invalid signature");
        _approve(owner, spender, value);
    }
}
