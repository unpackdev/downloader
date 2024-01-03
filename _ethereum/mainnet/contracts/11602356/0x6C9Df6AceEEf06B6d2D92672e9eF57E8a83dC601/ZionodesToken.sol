// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./EnumerableSet.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

import "./Pause.sol";

contract ZionodesToken is ERC20, Pause {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    uint256 public _fee;
    uint256 public _feeDecimals;

    address public _factory;
    address public _collector;
    address public _balancerPool;

    EnumerableSet.AddressSet _transferWhitelist;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address factoryAdmin
    ) ERC20(name, symbol) Roles([factoryAdmin, _msgSender(), address(this)]) {
        _setupDecimals(decimals);

        _transferWhitelist.add(_msgSender());
        _transferWhitelist.add(address(0));

        _factory = _msgSender();
        _feeDecimals = 18;
        _fee = 0.01 * (10**18);
        _collector = factoryAdmin;

        _mint(_factory, totalSupply);
    }

    function setFee(uint256 fee) external onlySuperAdminOrAdmin {
        _fee = fee;
    }

    function setBalancerPoolAddress(address balancerPool)
        external
        onlySuperAdminOrAdmin
    {
        require(balancerPool != address(0), "Can not be zero address");
        require(
            balancerPool != _msgSender(),
            "Can not be the same like caller"
        );
        require(
            balancerPool != _balancerPool,
            "Can not be the same like old one"
        );

        _balancerPool = balancerPool;
        _transferWhitelist.add(_balancerPool);
    }

    function addToTransferWhitelist(address account)
        external
        onlySuperAdminOrAdmin
    {
        _transferWhitelist.add(account);
    }

    function removeFromTransferWhitelist(address account)
        external
        onlySuperAdminOrAdmin
    {
        _transferWhitelist.remove(account);
    }

    function setCollector(address newCollector) external onlySuperAdminOrAdmin {
        require(newCollector != address(0), "Can not be zero address");
        require(
            newCollector != _collector,
            "Can not be the same as the current collector address"
        );

        _collector = newCollector;
    }

    function mint(address account, uint256 amount)
        external
        onlySuperAdminOrAdmin
    {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function getFeeForAmount(uint256 amount) public view returns (uint256) {
        return _fee.mul(amount).div(100).div(10**_feeDecimals);
    }

    function getTotalSupplyExceptAdmins() external view returns (uint256) {
        uint256 adminBalances = 0;

        for (uint256 i = 0; i < _admins.length(); ++i) {
            adminBalances = adminBalances.add(balanceOf(_admins.at(i)));
        }

        return totalSupply().sub(adminBalances).add(balanceOf(_factory));
    }

    function isInTransferWhitelist(address account)
        external
        view
        returns (bool)
    {
        return _transferWhitelist.contains(account);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (
            _transferWhitelist.contains(sender) ||
            _transferWhitelist.contains(recipient)
        ) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 fee = getFeeForAmount(amount);

            super._transfer(sender, recipient, amount.sub(fee));
            super._transfer(sender, _collector, fee);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!paused(), "ERC20: token transfer while paused");
    }
}
