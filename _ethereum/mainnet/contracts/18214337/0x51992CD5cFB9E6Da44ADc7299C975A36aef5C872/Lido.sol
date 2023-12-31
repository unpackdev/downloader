// File: Swivel-v4/src/interfaces/ILidoToken.sol



pragma solidity ^0.8.13;

interface ILidoToken {
    /// @dev The address of the stETH underlying asset
    function stETH() external view returns (address);

    /// @notice Returns amount of stETH for one wstETH
    function stEthPerToken() external view returns (uint256);
}

// File: Swivel-v4/src/interfaces/ILido.sol



pragma solidity ^0.8.13;

interface ILido {
    function wrap(uint256) external returns (uint256);

    function unwrap(uint256) external returns (uint256);

    function getWstETHByStETH(uint256) external returns (uint256);
}

// File: Swivel-v4/src/interfaces/IAdapter.sol



pragma solidity 0.8.16;

interface IAdapter {
    function underlying(address) external view returns (address);

    function exchangeRate(address) external view returns (uint256);

    function deposit(address, uint256) external returns (uint256);

    function withdraw(address, uint256) external returns (uint256);
}

// File: Swivel-v4/src/adapters/Lido.sol



pragma solidity 0.8.16;




contract Lido is IAdapter {
    function approve(address a, address c) external {}

    function underlying(address c) external view returns (address) {
        return ILidoToken(c).stETH();
    }

    function exchangeRate(address c) external view returns (uint256) {
        return ILidoToken(c).stEthPerToken();
    }

    function deposit(address c, uint256 a) external returns (uint256) {
        return ILido(c).wrap(a);
    }

    function withdraw(address c, uint256 a) external returns (uint256) {
        ILido wstEth = ILido(c);

        return wstEth.unwrap(wstEth.getWstETHByStETH(a));
    }
}