// SPDX-License-Identifier: GPL3-or-later
// Kyil guarantee

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./draft-IERC20Permit.sol";
import "./ERC20.sol";
import "./EIP712.sol";
import "./IBridgeMintable.sol";
import "./BoringBatchable.sol";

contract KarenToken is
    BoringBatchable,
    AccessControlEnumerable,
    ERC20,
    EIP712,
    IERC20Permit,
    IBridgeMintable
{
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => uint256) private _nonces;
    mapping(address => bool) public globalPermissionedDestination;
    mapping(address => bool) public globalPermissionedSource;

    uint256 internal _cap;
    uint8 internal _decimals;
    bool public _soulbound;

    event SoulboundSet(bool soulbound);
    event GlobalPermissionedSourceSet(address sourceAddress, bool allowed);
    event GlobalPermissionedDestinationSet(
        address destinationAddress,
        bool allowed
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        uint256 cap_,
        uint256 initialSupply,
        address initialSupplyTo,
        bool _soulbound_,
        address[] memory _admins
    ) ERC20(_name, _symbol) EIP712(_name, "1") {
        if (cap_ == 0) {
            _cap = type(uint256).max;
        } else {
            _cap = cap_;
        }

        _decimals = decimals_;

        if (initialSupply > 0 && initialSupplyTo != address(0)) {
            _mint(initialSupplyTo, initialSupply);
        }

        _soulbound = _soulbound_;

        _setRoleAdmin(GOVERNANCE_ROLE, GOVERNANCE_ROLE);
        _setRoleAdmin(ADMIN_ROLE, GOVERNANCE_ROLE);
        _setRoleAdmin(MINTER_ROLE, GOVERNANCE_ROLE);

        _grantRole(GOVERNANCE_ROLE, _admins[0]);

        if (_admins[1] != address(0)) {
            _grantRole(ADMIN_ROLE, _admins[1]);
        }

        if (_admins[2] != address(0)) {
            _grantRole(MINTER_ROLE, _admins[2]);
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "T::permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "T::permit: invalid signature");

        _approve(owner, spender, value);
    }

    function nonces(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _nonces[owner];
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(address owner)
        internal
        virtual
        returns (uint256 current)
    {
        current = _nonces[owner];
        _nonces[owner] += 1;
    }

    function proxyMintBatch(
        address, /* _minter*/
        address _account,
        uint256[] calldata, /* _ids*/
        uint256[] calldata _amounts,
        bytes memory /*_data */
    ) external onlyRole(MINTER_ROLE) {
        _mint(_account, _amounts[0]);
    }

    function mint(address _account, uint256 _amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(_account, _amount);
    }

    function _mint(address account, uint256 amount) internal override {
        require(totalSupply() + amount <= cap(), "T::_mint: cap exceeded");
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal view override {
        if (_soulbound) {
            require(
                from == address(0) || // mint
                    to == address(0) || // burn
                    globalPermissionedSource[from] ||
                    globalPermissionedDestination[to],
                "T::tx: soulbound"
            );
        }
    }

    // soulbound functions

    function soulbound() public view returns (bool) {
        return _soulbound;
    }

    function setGlobalDestinationPermission(
        address destinationAddress,
        bool allowed
    ) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "C::setGDP: unauthorized");
        require(destinationAddress != address(0), "C::setGDP: address zero");
        globalPermissionedDestination[destinationAddress] = allowed;

        emit GlobalPermissionedDestinationSet(destinationAddress, allowed);
    }

    function setGlobalSourcePermission(address sourceAddress, bool allowed)
        external
    {
        require(hasRole(ADMIN_ROLE, _msgSender()), "C::setGSP: unauthorized");
        require(sourceAddress != address(0), "C::setGSP: address zero");
        globalPermissionedSource[sourceAddress] = allowed;

        emit GlobalPermissionedSourceSet(sourceAddress, allowed);
    }

    function setSoulbound(bool _soulbound_) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "C::setSB: unauthorized");
        _soulbound = _soulbound_;

        emit SoulboundSet(_soulbound_);
    }
}
