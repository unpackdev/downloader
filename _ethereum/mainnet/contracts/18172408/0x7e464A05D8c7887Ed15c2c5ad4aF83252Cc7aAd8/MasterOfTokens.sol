// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IMasterOfTokens.sol";
import "./AccessControl.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MasterOfTokens is AccessControl, IMasterOfTokens {
    bytes32 private constant ADDOR = keccak256("ADDOR");

    uint256 public nonce;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Nonce => TokenDeployed
    mapping(uint256 => TokenDeployed) private _tokens;

    function addNewToken(TokenDeployed memory _token) external onlyRole(ADDOR) returns (uint256) {
        _tokens[nonce] = _token;

        unchecked {
            nonce++;
        }

        emit NewToken(
            block.number,
            _token.initialLiq,
            _token.pairAddress,
            _token.ticker,
            _token.decimals,
            _token.tokenAddress,
            tx.origin,
            _token.refAddress
        );

        return nonce - 1;
    }

    function updateAddor(address _addor, bool _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_status) {
            _grantRole(ADDOR, _addor);
        } else {
            _revokeRole(ADDOR, _addor);
        }
    }

    function getToken(uint256 _nonce) external view returns (TokenDeployed memory) {
        return _tokens[_nonce];
    }
}
