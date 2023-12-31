// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

contract Target {
    address private _owner;
    address private _implementation;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor(address implementation) {
        _owner = msg.sender;
        _implementation = implementation;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Target: You are not the owner");
        _;
    }

    modifier onlyWhale() {
        require(_balances[msg.sender] >= 3e18, "Target: You are not a whale");
        _;
    }

    // View functions
    function owner() public view returns (address) {
        return _owner;
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address account, address spender) public view returns (uint256) {
        return _allowances[account][spender];
    }

    // Public functions
    function getAirdrop() public {
        _getAirdrop();
    }

    function approve(address spender, uint256 value) public {
        _approve(msg.sender, spender, value);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public {
        (bool success,) = _implementation.delegatecall(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", sender, recipient, amount)
        );
        if (success == false) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }


    function mint(address receiver, uint256 amount) onlyOwner public {
        _mint(receiver, amount);
    }

    function withdraw() onlyOwner public {
        _withdraw();
    }

    function changeImplementation(address newImplementation) onlyWhale public {
        _changeImplementation(newImplementation);
    }

    receive() external payable {}

    fallback() external payable {}

    // Private functions
    function _getAirdrop() private {
        require(_balances[msg.sender] == 0, "Cannot claim airdrop");
        _balances[msg.sender] = 1e18;
    }

    function _approve(address account, address spender, uint256 value) public {
        require(account != address(0), "Target: approve from the zero address");
        require(spender != address(0), "Target: approve to the zero address");

        _allowances[account][spender] = value;
    }

    function _mint(address receiver, uint256 amount) private {
        require(receiver != address(0), "Target: mint to the zero address");
        require(_balances[receiver] < 3e18, "Target: cannot mint to whale");
        _balances[receiver] = _balances[receiver] + amount;
    }

    function _withdraw() private {
        (bool success, ) = msg.sender.call{value : address(this).balance}("");
        require(success, "Failed to send ether");
    }

    function _changeImplementation(address newImplementation) private {
        _implementation = newImplementation;
    }
}