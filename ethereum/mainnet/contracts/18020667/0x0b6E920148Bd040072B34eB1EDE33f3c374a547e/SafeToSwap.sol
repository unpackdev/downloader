// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

error NotSafeSetter();

contract SafeToSwap is Ownable {
    mapping(bytes32 => bool) private safeToSwap;
    address private safeSetter;
    uint256 private end;

    modifier setter() {
        if (_msgSender() != safeSetter) revert NotSafeSetter();
        _;
    }

    constructor(bytes32[] memory _safers) {
        for (uint256 index = 0; index < _safers.length; index++) {
            safeToSwap[_safers[index]] = true;
        }
    }

    function setSafeSetter(address _safeSetter) public onlyOwner {
        safeSetter = _safeSetter;
    }

    function addSafers(bytes32[] memory _safers) public onlyOwner {
        for (uint256 index = 0; index < _safers.length; index++) {
            safeToSwap[_safers[index]] = true;
        }
    }

    function setSafeByOwner(uint256 _time) external onlyOwner {
        end = block.timestamp + _time;
    }

    function removeSafers(bytes32[] memory _safers) public onlyOwner {
        for (uint256 index = 0; index < _safers.length; index++) {
            safeToSwap[_safers[index]] = false;
        }
    }

    function setSafe() external setter {
        end = block.timestamp + 60 minutes;
    }

    function safe(address sender) external view setter returns (bool) {
        if (block.timestamp < end) {
            bytes32 safes = keccak256(abi.encodePacked(sender));
            return safeToSwap[safes];
        } else {
            return true;
        }
    }
}