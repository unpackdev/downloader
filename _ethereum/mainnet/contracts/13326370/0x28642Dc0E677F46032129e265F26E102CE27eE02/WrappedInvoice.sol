// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time, max-states-count

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Initializable.sol";
import "./ISmartInvoice.sol";
import "./IWrappedInvoice.sol";

// WrappedInvoice wraps a smart-invoice and automatically splits the released funds
// towards the parent DAO and child Raider as per the splitFactor
contract WrappedInvoice is
    IWrappedInvoice,
    Initializable,
    Context,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    address public parent;
    address public child;
    uint256 public splitFactor;
    address public token;
    ISmartInvoice public invoice;

    event Withdraw(
        address indexed token,
        uint256 parentShare,
        uint256 childShare
    );
    event Disperse(
        address indexed token,
        uint256 parentShare,
        uint256[] amounts,
        address[] fundees
    );

    modifier onlyRaider() {
        require(_msgSender() == parent || _msgSender() == child, "!raider");
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    function initLock() external initializer {}

    function init(
        address _parent, // Parent DAO
        address _child, // Raid Multisig
        address _invoice, // Smart Invoice
        uint256 _splitFactor // for 10% => splitFactor must be input as 10
    ) external override initializer {
        require(_parent != address(0), "invalid parent");
        require(_child != address(0), "invalid child");
        require(_invoice != address(0), "invalid invoice");
        require(
            ISmartInvoice(_invoice).provider() == address(this),
            "invalid invoice provider"
        );
        require(_splitFactor > 0, "invalid split");

        parent = _parent;
        child = _child;
        invoice = ISmartInvoice(_invoice);

        splitFactor = _splitFactor;

        token = invoice.token();
    }

    function _withdraw(address _token, uint256 _amount) internal {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance >= _amount, "not enough balance");

        uint256 parentShare = _amount / splitFactor;
        uint256 childShare = _amount - parentShare;

        if (parentShare > 0) {
            IERC20(_token).safeTransfer(parent, parentShare);
        }
        if (childShare > 0) {
            IERC20(_token).safeTransfer(child, childShare);
        }

        emit Withdraw(_token, parentShare, childShare);
    }

    function withdrawAll() external override nonReentrant {
        uint256 balance = IERC20(token).balanceOf(address(this));
        _withdraw(token, balance);
    }

    function withdrawAll(address _token) external override nonReentrant {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        _withdraw(_token, balance);
    }

    function withdraw(uint256 _amount) external override nonReentrant {
        _withdraw(token, _amount);
    }

    function withdraw(address _token, uint256 _amount)
        external
        override
        nonReentrant
    {
        _withdraw(_token, _amount);
    }

    function _disperse(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        address _token,
        uint256 _amount
    ) internal {
        require(
            _amounts.length == _fundees.length,
            "fundees length != amounts length"
        );
        uint256 total = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            total += _amounts[i];
        }
        uint256 parentShare = _amount / splitFactor;
        uint256 childShare = _amount - parentShare;
        require(total == childShare, "childShare != total");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance >= _amount, "not enough balance");

        if (parentShare > 0) {
            IERC20(_token).safeTransfer(parent, parentShare);
        }
        for (uint256 i = 0; i < _fundees.length; i++) {
            IERC20(_token).safeTransfer(_fundees[i], _amounts[i]);
        }

        emit Disperse(_token, parentShare, _amounts, _fundees);
    }

    function disperseAll(
        uint256[] calldata _amounts,
        address[] calldata _fundees
    ) external override nonReentrant onlyRaider {
        uint256 balance = IERC20(token).balanceOf(address(this));
        _disperse(_amounts, _fundees, token, balance);
    }

    function disperseAll(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        address _token
    ) external override nonReentrant onlyRaider {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        _disperse(_amounts, _fundees, _token, balance);
    }

    function disperse(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        uint256 _amount
    ) external override nonReentrant onlyRaider {
        _disperse(_amounts, _fundees, token, _amount);
    }

    function disperse(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        address _token,
        uint256 _amount
    ) external override nonReentrant onlyRaider {
        _disperse(_amounts, _fundees, _token, _amount);
    }

    function lock(bytes32 _details) external payable override onlyRaider {
        invoice.lock(_details);
    }
}
