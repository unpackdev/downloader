//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Errors.sol";
import "./ZetaFallback.sol";

abstract contract IZetaToken is AccessControlEnumerable, ZetaFallback {
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    bool internal isEnabled = true;
    mapping(bytes32 => bool) public actionAvailability;

    mapping(address => uint256) internal _balances;
    uint256 internal _totalSupply;

    constructor(address zetaERC1155) {
        _setupRole(OPERATOR, _msgSender());
        _setupRole(OPERATOR, zetaERC1155);

        _totalSupply = 0;
    }

    function canPerform(address account, string memory action)
        external
        view
        virtual
        returns (bool);

    function balanceOf(address account)
        external
        view
        virtual
        returns (uint256)
    {
        return _balances[account];
    }

    function increaseBalance(address account, uint256 delta)
        external
        virtual
        onlyRole(OPERATOR)
    {
        unchecked {
            _balances[account] += delta;
        }
    }

    function decreaseBalance(address account, uint256 delta)
        external
        virtual
        onlyRole(OPERATOR)
    {
        uint256 fromBalance = _balances[account];
        if (fromBalance < delta) {
            revert InsufficientBalanceForTransfer();
        }
        unchecked {
            _balances[account] = fromBalance - delta;
        }
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    function increaseTotalSupply(uint256 delta)
        external
        virtual
        onlyRole(OPERATOR)
    {
        unchecked {
            _totalSupply += delta;
        }
    }

    function decreaseTotalSupply(uint256 delta)
        external
        virtual
        onlyRole(OPERATOR)
    {
        if (_totalSupply < delta) {
            revert InsufficientTotalSupplyForDecrease();
        }

        unchecked {
            _totalSupply -= delta;
        }
    }

    function setIsEnabled(bool enabled) external virtual onlyRole(OPERATOR) {
        isEnabled = enabled;
    }

    function setActionAvailability(string memory action, bool availability)
        public
        onlyRole(OPERATOR)
    {
        actionAvailability[keccak256(abi.encode(action))] = availability;
    }
}
