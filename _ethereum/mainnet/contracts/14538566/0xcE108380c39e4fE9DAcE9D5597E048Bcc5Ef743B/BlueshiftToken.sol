// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";

import "./ERC20.sol";

contract BlueshiftToken is ERC20, Ownable {
    address public minter;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _minter
    ) ERC20(_tokenName, _tokenSymbol) {
        minter = _minter;
    }

    function mint(address _account, uint256 _amount) external returns (bool) {
        require(msg.sender == minter, "only minter can mint");
	require(totalSupply() == 0, "only one minting is allowed");

        _mint(_account, _amount);
        return true;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }
}
