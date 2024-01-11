// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20Permit.sol";
import "./MetaVaultAC.sol";

contract gMVD is ERC20, MetaVaultAC {
    using Address for address;
    using SafeMath for uint256;

    bool public transferAllowance;

    address public staking;

    constructor(address _authority) ERC20("Governance Metavault", "gMVD", 18) MetaVaultAC(IMetaVaultAuthority(_authority)) {}

    modifier onlyStaking() {
        require(msg.sender == staking);
        _;
    }

    function setStaking(address _staking) public onlyGovernor {
        staking = _staking;
    }

    function setTransferAllowance(bool _allowance) public onlyGovernor {
        transferAllowance = _allowance;
    }

    function mint(address _account, uint256 _amount) external onlyStaking {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyStaking {
        _burn(_account, _amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(transferAllowance, "Transfer Forbidden");
        return super.transferFrom(sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(transferAllowance, "Transfer Forbidden");
        return super.transfer(recipient, amount);
    }
}
