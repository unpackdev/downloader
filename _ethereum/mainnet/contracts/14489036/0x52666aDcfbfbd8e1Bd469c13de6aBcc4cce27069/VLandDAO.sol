// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract VLandDAO is ERC20, ERC20Snapshot, Ownable, ERC20Permit, ERC20Votes {

    address public staking;
    address public poolDistributor;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) ERC20Permit(name_) {
    }

    modifier onlyStaking() {
        require(staking == _msgSender(), "VLandDAO: caller is not staking");
        _;
    }

    function setPoolDistributor(address _poolDistributor) public onlyOwner {
        require(_poolDistributor != address(0));
        poolDistributor = _poolDistributor;
    }

    function setStaking(address _staking) external onlyOwner {
        require(_staking != address(0));
        staking = _staking;
    }

    function snapshot() public returns (uint256) {
        require(_msgSender() == poolDistributor || _msgSender() == owner());
        return _snapshot();
    }

    function mint(address to, uint256 amount) external onlyStaking {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public onlyStaking {
        _burn(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20, ERC20Snapshot)
    {
        require(from == address(0) || to == address(0));
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}