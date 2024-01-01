// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.10;

interface IDoughV2Index {
    function getDoughV2Dsa(address _user) external view returns (address);
}

interface IShadowToken {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

contract DoughV2Token {
    string private _name;
    string private _symbol;

    address public immutable shadowTokenAddress;
    address public immutable doughV2Index;

    error CustomError(string errorMsg);

    constructor(string memory name_, string memory symbol_, address shadowTokenAddress_, address doughV2Index_) {
        if (shadowTokenAddress_ == address(0)) revert CustomError("invalid address");
        if (doughV2Index_ == address(0)) revert CustomError("invalid address");
        _name = name_;
        _symbol = symbol_;
        shadowTokenAddress = shadowTokenAddress_;
        doughV2Index = doughV2Index_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return IShadowToken(shadowTokenAddress).decimals();
    }

    function totalSupply() public view returns (uint256) {
        return IShadowToken(shadowTokenAddress).totalSupply();
    }

    function balanceOf(address account) public view returns (uint256) {
        address _dsa = IDoughV2Index(doughV2Index).getDoughV2Dsa(account);
        if (_dsa == address(0)) {
            return 0;
        } else {
            return IShadowToken(shadowTokenAddress).balanceOf(_dsa);
        }
    }
}
