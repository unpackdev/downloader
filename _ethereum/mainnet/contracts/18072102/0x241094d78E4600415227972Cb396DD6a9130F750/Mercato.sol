// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Mercato is ERC20Burnable, Ownable {
    uint public taxRateInBips = 500; // 5% of the amount

    // TODO Switch to PROD before deployment
    address public constant taxAddress =
        0xdaa9F7Ae5A1cD7f421643123A9f3D12518d7344E; // PROD

    // address public constant taxAddress =
    //     0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; // TEST

    address public marketingAddress;
    address public cexAddress;
    address public teamAddress;
    address public uniswapV2Pair;

    event SetPair(address indexed _address);
    event SetTaxRate(
        uint indexed _oldTaxRateInBips,
        uint indexed _newTaxRateInBips
    );

    constructor() ERC20("Mercato", "MERCATO") {
        uint _totalSupply = 910910910910 * 1e18;

        /**
         * @notice Addresses to receive the tokens
         * @dev TODO set before deployment
         */

        // TODO Switch to PROD before deployment
        marketingAddress = 0x0B37e1781B62d54C1E86786a48e0595Abf0C9d87; // PROD
        // marketingAddress = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // TEST

        cexAddress = 0x32e4ef91b367543148B79B62F882dDDd262059AB; // PROD
        // cexAddress = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // TEST

        teamAddress = 0xaCc9840964f2092e61EdAa87C82257d22410a34d; // PROD
        // teamAddress = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // TEST
        /**
         * @notice Share in bips of the total supply
         */
        uint _liquidityPoolShareInBips = 6570;
        uint _marketingShareInBips = 1620;
        uint _cexShareInBips = 1200;
        uint _teamShareInBips = 610;

        /**
         * @notice Amount of tokens to mint each address
         */
        uint _liquidityPoolAmount = (_totalSupply * _liquidityPoolShareInBips) /
            10_000;
        uint _marketingAmount = (_totalSupply * _marketingShareInBips) / 10_000;
        uint _cexAmount = (_totalSupply * _cexShareInBips) / 10_000;
        uint _teamAmount = (_totalSupply * _teamShareInBips) / 10_000;

        /**
         * @notice Mint tokens
         */
        _mint(msg.sender, _liquidityPoolAmount);
        _mint(marketingAddress, _marketingAmount);
        _mint(cexAddress, _cexAmount);
        _mint(teamAddress, _teamAmount);
    }

    /// @notice Get the tax address
    /// @return _taxAddress Tax address
    function getTaxAddress() external pure returns (address _taxAddress) {
        _taxAddress = taxAddress;
    }

    /// @notice Set UniswapV2Pair address
    /// @param _uniswapV2Pair UniswapV2Pair address
    function setPair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;

        emit SetPair(_uniswapV2Pair);
    }

    /// @notice Set the tax rate
    /// @param _newTaxRateInBips New tax rate in bips
    function setTaxRate(uint _newTaxRateInBips) external onlyOwner {
        require(
            _newTaxRateInBips < 500,
            "Mercato: tax rate cannot be more than 5%"
        );

        emit SetTaxRate(taxRateInBips, _newTaxRateInBips);
        taxRateInBips = _newTaxRateInBips;
    }

    /// @notice Leaves the contract without owner
    function renounceOwnership() public virtual override onlyOwner {
        require(
            uniswapV2Pair != address(0),
            "Mercato: uniswapV2Pair is not set"
        );
        _transferOwnership(address(0));
    }

    /** @notice Transfer `amount` of tokens from `from` to `to`..
     * @param _from Sender address
     * @param _to Recipient address
     * @param _amount Amount of tokens to transfer
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        if (_amount == 0) {
            super._transfer(_from, _to, 0);
            return;
        }

        if (_from == owner() && _to == uniswapV2Pair) {
            super._transfer(_from, _to, _amount);
            return;
        }

        uint swapFees = 0;
        if (_from == uniswapV2Pair || _to == uniswapV2Pair) {
            swapFees = (_amount * taxRateInBips) / 10_000;
            super._transfer(_from, taxAddress, swapFees);
        }

        super._transfer(_from, _to, _amount - swapFees);
    }
}
