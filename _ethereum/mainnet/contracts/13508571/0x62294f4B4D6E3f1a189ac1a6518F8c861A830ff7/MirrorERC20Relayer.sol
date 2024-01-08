// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IMirrorERC20ProxyStorage.sol";
import "./IMirrorERC20Relayer.sol";
import "./IERC20.sol";

/**
 * @title MirrorERC20Relayer
 * @author MirrorXYZ
 * @notice This contract implements the logic for erc20 proxies. It attaches
 * msg.sender to the calls that require the original sender of the transaction.
 */
contract MirrorERC20Relayer is IERC20, IMirrorERC20Relayer, IERC20Events {
    /// @notice The address that holds the proxy's storage
    address public immutable proxyStorage;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /**
     * @notice Assign immutable proxy storage address.
     * @param proxyStorage_ - the address that holds the proxy's storage
     */
    constructor(address proxyStorage_) {
        proxyStorage = proxyStorage_;
    }

    /**
     * @notice Initialize metadata variables and register the proxy operator.
     * This function is called by a proxy during its deployment. The function
     * is only callable during deployment.
     */
    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external override {
        // Ensure that this function is only callable during contract deployment
        assembly {
            if extcodesize(address()) {
                revert(0, 0)
            }
        }

        IMirrorERC20ProxyStorage(proxyStorage).initialize(
            operator_,
            name_,
            symbol_,
            totalSupply_,
            decimals_
        );
    }

    function operator() external view override returns (address) {
        return IMirrorERC20ProxyStorage(proxyStorage).operator();
    }

    // ============ EIP-20 Methods ============

    function name() external view override returns (string memory) {
        return IMirrorERC20ProxyStorage(proxyStorage).name();
    }

    function symbol() external view override returns (string memory) {
        return IMirrorERC20ProxyStorage(proxyStorage).symbol();
    }

    function decimals() external view override returns (uint8) {
        return IMirrorERC20ProxyStorage(proxyStorage).decimals();
    }

    function totalSupply() external view override returns (uint256) {
        return IMirrorERC20ProxyStorage(proxyStorage).totalSupply();
    }

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return IMirrorERC20ProxyStorage(proxyStorage).balanceOf(_owner);
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return
            IMirrorERC20ProxyStorage(proxyStorage).allowance(_owner, spender);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        emit Approval(msg.sender, spender, value);

        return
            IMirrorERC20ProxyStorage(proxyStorage).approve(
                msg.sender,
                spender,
                value
            );
    }

    function mint(address to, uint256 value) external override {
        emit Transfer(address(0), to, value);

        return
            IMirrorERC20ProxyStorage(proxyStorage).mint(msg.sender, to, value);
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        emit Transfer(msg.sender, to, value);

        return
            IMirrorERC20ProxyStorage(proxyStorage).transfer(
                msg.sender,
                to,
                value
            );
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        emit Transfer(from, to, value);

        return
            IMirrorERC20ProxyStorage(proxyStorage).transferFrom(
                from,
                to,
                value
            );
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return IMirrorERC20ProxyStorage(proxyStorage).DOMAIN_SEPARATOR();
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
        emit Approval(owner, spender, value);

        return
            IMirrorERC20ProxyStorage(proxyStorage).permit(
                owner,
                spender,
                value,
                deadline,
                v,
                r,
                s
            );
    }

    function nonces(address owner) external view returns (uint256) {
        return IMirrorERC20ProxyStorage(proxyStorage).nonces(owner);
    }

    function setOperator(address newOperator) external {
        return
            IMirrorERC20ProxyStorage(proxyStorage).setOperator(
                msg.sender,
                newOperator
            );
    }
}
