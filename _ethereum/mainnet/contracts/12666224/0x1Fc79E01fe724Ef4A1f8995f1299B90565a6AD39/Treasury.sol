//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IUniswapV2Router02.sol";

import "./Token.sol";
import "./PaymentRecipient.sol";

contract Treasury is AccessControlUpgradeable, PaymentRecipient {
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    event BoughtBack(address initiator, uint256 ethAmount, uint256 tokensBought);
    event Burnt(address initiator, uint256 ethAmount);

    Token private _tokenAddress;
    IUniswapV2Router02 private _uniswapRouter;

    function initialize(address payable uniswapRouter) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNOR_ROLE, _msgSender());

        _uniswapRouter = IUniswapV2Router02(uniswapRouter);
    }

    //
    // Modifiers
    //
    modifier isGovernor() {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Treasury: caller is not governor");
        _;
    }

    //
    // Admin functions
    //
    function setTokenAddress(address tokenAddress) public isGovernor() {
        _tokenAddress = Token(tokenAddress);
    }

    function buybackAndBurn(uint256 ethAmount, uint256 amountOutMin) public isGovernor() {
        require(ethAmount >= address(this).balance, "Treasury: amount is more than balance");
        require(address(_tokenAddress) != address(0), "Treasury: token address not set");

        // Build arguments for uniswap router call
        address[] memory path = new address[](2);
        path[0] = _uniswapRouter.WETH();
        path[1] = address(_tokenAddress);

        // Make the call and give it 30 seconds
        uint256[] memory amounts =
            _uniswapRouter.swapExactETHForTokens{value: ethAmount}(
                amountOutMin,
                path,
                address(this),
                block.timestamp + 30
            );
        uint256 amountBought = amounts[amounts.length - 1];
        emit BoughtBack(_msgSender(), ethAmount, amountBought);

        _tokenAddress.burn(amountBought);
        emit Burnt(_msgSender(), amountBought);
    }
}
