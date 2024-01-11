/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface ICurvePool {
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount)
        external
        payable;

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external payable;

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount)
        external
        payable;

    function add_liquidity(
        uint256[3] memory _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external payable;

    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount)
        external
        payable;

    function add_liquidity(
        uint256[4] memory _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external payable;

    function coins(uint256 i) external view returns (address);
}
