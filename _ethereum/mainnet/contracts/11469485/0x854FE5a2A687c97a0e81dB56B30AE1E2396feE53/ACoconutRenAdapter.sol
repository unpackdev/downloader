// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

interface IGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function burn(bytes calldata _to, uint256 _amount)
        external
        returns (uint256);
}

interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IGateway);

    function getTokenBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IERC20);
}

interface IAcoconutSwap {
    function poolToken() external view returns (IERC20);

    function mint(uint256[] calldata _amounts, uint256 _minMintAmount) external;
}

contract ACoconutRenAdapter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IGatewayRegistry public registry;
    IAcoconutSwap public acSwap;

    constructor(
        address _registry,
        address _acSwap
    ) public {
        require(_registry != address(0x0), "registry not set");
        require(_acSwap != address(0x0), "acSwap not set");

        registry = IGatewayRegistry(_registry);
        acSwap = IAcoconutSwap(_acSwap);
        IERC20 acBTC = acSwap.poolToken();
        IERC20 renBTC = registry.getTokenBySymbol("BTC");

        acBTC.safeApprove(address(acSwap), uint256(-1));
        renBTC.safeApprove(address(acSwap), uint256(-1));
    }

    function mint(
        // Parameters from users
        address _target,
        // Parameters from Darknodes
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) public {
        bytes32 pHash = keccak256(abi.encode(_target));
        uint256 renBtcAmount = registry.getGatewayBySymbol("BTC").mint(
            pHash,
            _amount,
            _nHash,
            _sig
        );

        uint256[] memory amounts = new uint256[](2);
        amounts[1] = renBtcAmount;
        IERC20 acBTC = acSwap.poolToken();
        uint256 beforeAmount = acBTC.balanceOf(address(this));
        acSwap.mint(amounts, 0);
        uint256 afterAmount = acBTC.balanceOf(address(this));
        acBTC.safeTransfer(_target, afterAmount.sub(beforeAmount));
    }
}