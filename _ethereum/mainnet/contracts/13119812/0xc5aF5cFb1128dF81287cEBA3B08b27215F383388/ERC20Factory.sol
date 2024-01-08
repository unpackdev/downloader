// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./EnumerableSet.sol";
import "./SafeERC20.sol";
import "./TMCERC20.sol";

contract ERC20Factory is Context, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private _erc20Contracts;
    mapping(address => uint256) private _erc20Balance;
    uint256 private _feePercent4Deci;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _feePercent4Deci = 200;
    }

    // Administrative functions.
    function erc20Count() external view verifyIsAdmin returns (uint256 count) {
        count = _erc20Contracts.length();
        return count;
    }

    function updateFee(uint256 fee) external verifyIsAdmin {
        _feePercent4Deci = fee;
    }

    function erc20At(uint256 index)
        external
        view
        verifyIsAdmin
        returns (address anAddress)
    {
        return _erc20Contracts.at(index);
    }

    function transferBalance(address tokenAddress, address to)
        external
        verifyIsAdmin
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = _erc20Balance[tokenAddress];

        delete _erc20Balance[tokenAddress];
        _erc20Contracts.remove(tokenAddress);

        token.safeTransfer(to, tokenBalance);
    }

    // Service functions.
    function createERC20(
        string memory name,
        string memory symbol,
        uint256 amount
    ) external {
        TMCERC20 token = new TMCERC20(
            name,
            symbol
        );
        address factoryAddress = address(this);
        address tokenAddress = address(token);
        uint256 tokenBalance = amount * (10**18);
        uint256 fee = (tokenBalance * _feePercent4Deci) / (10000);

        token.mint(_msgSender(), tokenBalance - fee);
        token.mint(address(this), fee);

        token.grantRole(token.DEFAULT_ADMIN_ROLE(), _msgSender());
        token.grantRole(token.MINTER_ROLE(), _msgSender());
        token.grantRole(token.PAUSER_ROLE(), _msgSender());

        token.renounceRole(token.DEFAULT_ADMIN_ROLE(), factoryAddress);
        token.renounceRole(token.MINTER_ROLE(), factoryAddress);
        token.renounceRole(token.PAUSER_ROLE(), factoryAddress);

        _erc20Contracts.add(tokenAddress);
        _erc20Balance[tokenAddress] = fee;

        emit ERC20Created(tokenAddress, _msgSender());
    }

    // Modifiers.
    modifier verifyIsAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");
        _;
    }

    event ERC20Created(address indexed token, address indexed user);
}
