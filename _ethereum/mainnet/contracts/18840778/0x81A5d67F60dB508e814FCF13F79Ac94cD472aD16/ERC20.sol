// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./ERC20.sol";

contract $ERC20 is ERC20 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) payable {
    }

    function $_balances(address arg0) external view returns (uint256) {
        return _balances[arg0];
    }

    function $_totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function $_transfer(address from,address to,uint256 amount) external {
        super._transfer(from,to,amount);
    }

    function $_mint(address account,uint256 amount) external {
        super._mint(account,amount);
    }

    function $_burn(address account,uint256 amount) external {
        super._burn(account,amount);
    }

    function $_approve(address owner,address spender,uint256 amount) external {
        super._approve(owner,spender,amount);
    }

    function $_spendAllowance(address owner,address spender,uint256 amount) external {
        super._spendAllowance(owner,spender,amount);
    }

    function $_beforeTokenTransfer(address from,address to,uint256 amount) external {
        super._beforeTokenTransfer(from,to,amount);
    }

    function $_afterTokenTransfer(address from,address to,uint256 amount) external {
        super._afterTokenTransfer(from,to,amount);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}
