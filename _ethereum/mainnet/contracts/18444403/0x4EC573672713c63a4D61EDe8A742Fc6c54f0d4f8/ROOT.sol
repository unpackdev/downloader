// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OFTWithFee.sol";

contract ROOT is Ownable, OFTWithFee {
    using SafeERC20 for IERC20;
    event MintAllowanceSet(address indexed minter, uint256 amount);

    mapping(address => uint256) public mintAllowance;

    mapping(address => bool) public isBlacklisted;

    uint256 public maxSupply;

    constructor(
        address lzEndpoint,
        uint256 _initialSupply,
        uint256 _maxSupply,
        address _initialSupplyReceiver
    ) OFTWithFee("ROOT", "ROOT", 9, lzEndpoint) {
        require(
            _initialSupply <= _maxSupply,
            "Initial supply should be lower than max supply"
        );
        require(
            _initialSupplyReceiver != address(0),
            "Invald receiver address"
        );
        maxSupply = _maxSupply;
        _mint(_initialSupplyReceiver, _initialSupply);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        uint _minAmount,
        LzCallParams calldata _callParams
    ) public payable virtual override {
        require(!isBlacklisted[msg.sender], "ROOT: sender is blacklisted");
        require(!isBlacklisted[_from], "ROOT: sender is blacklisted");
        super.sendFrom(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _minAmount,
            _callParams
        );
    }

    function sendAndCall(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        uint _minAmount,
        bytes calldata _payload,
        uint64 _dstGasForCall,
        LzCallParams calldata _callParams
    ) public payable virtual override {
        require(!isBlacklisted[msg.sender], "ROOT: sender is blacklisted");
        require(!isBlacklisted[_from], "ROOT: sender is blacklisted");
        super.sendAndCall(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _minAmount,
            _payload,
            _dstGasForCall,
            _callParams
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBlacklisted[msg.sender], "ROOT: sender is blacklisted");
        require(!isBlacklisted[from], "ROOT: sender is blacklisted");
        require(!isBlacklisted[to], "ROOT: recipient is blacklisted");

        super._transfer(from, to, amount);
    }

    function mint(address to, uint256 amount) external {
        //only addresses sufficient allowances can mint
        require(
            mintAllowance[msg.sender] >= amount,
            "ROOT: insufficient mint allowance"
        );
        require(!isBlacklisted[msg.sender], "ROOT: sender is blacklisted");
        require(!isBlacklisted[to], "ROOT: recipient is blacklisted");
        mintAllowance[msg.sender] -= amount;
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal override {
        require(totalSupply() + amount <= maxSupply, "Max supply exceed");
        require(!isBlacklisted[msg.sender], "ROOT: sender is blacklisted");
        require(!isBlacklisted[account], "ROOT: recipient is blacklisted");
        super._mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function setBlacklistStatus(
        address account,
        bool status
    ) external onlyOwner {
        isBlacklisted[account] = status;
    }

    function setMintAllowance(
        address minter,
        uint256 amount
    ) external onlyOwner {
        require(!isBlacklisted[minter], "ROOT: minter is blacklisted");
        require(
            (amount == 0) || (mintAllowance[minter] == 0),
            "Approve mint from non-zero to non-zero allowance"
        );
        mintAllowance[minter] = amount;
        emit MintAllowanceSet(minter, amount);
    }

    function incrementMintAllowance(
        address minter,
        uint256 amount
    ) external onlyOwner {
        mintAllowance[minter] += amount;
        emit MintAllowanceSet(minter, mintAllowance[minter]);
    }

    function decrementMintAllowance(
        address minter,
        uint256 amount
    ) external onlyOwner {
        require(
            mintAllowance[minter] >= amount,
            "ROOT: decrement amount exceeds mint allowance"
        );
        mintAllowance[minter] -= amount;
        emit MintAllowanceSet(minter, mintAllowance[minter]);
    }

    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
