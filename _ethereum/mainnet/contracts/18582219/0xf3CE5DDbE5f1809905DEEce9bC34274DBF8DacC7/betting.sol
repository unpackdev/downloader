// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IUniswapV2Router02.sol";

contract Depositor is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    // **************************
    // variables
    // **************************
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => bool) public whitelist;
    address public usdToken; // DAI
    uint256[49] __gap;

    // **************************
    // modifiers
    // **************************
    modifier onlyCreatorOrOwner() {
        require(
            msg.sender == owner() || whitelist[msg.sender] == true,
            "You are not the creator or whitelisted address for this contract"
        );
        _;
    }

    // **************************
    // event
    // **************************
    event Deposit(
        address indexed tokenAddress,
        uint256 amount,
        uint256 amountReceived,
        address indexed sender
    );

    // /////////////////////////////////////////
    //    UPGRADABLE _UUPS
    // /////////////////////////////////////////

    // **************************
    // constructor
    // **************************
    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    // **************************
    // used in place of constructor
    // **************************

    function initialize(
        address uniswapRouter,
        address _usdToken
    ) public initializer {
        __Ownable_init(0xf8634d70efAe4e3a6cC398334212B13ea6289708);
        __UUPSUpgradeable_init();
        uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        usdToken = _usdToken;
    }

    // **************************
    // mandatory function
    // **************************

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // /////////////////////////////////////////
    //    UPGRADABLE _UUPS
    // /////////////////////////////////////////

    receive() external payable {
        depositETH();
    }

    // **************************
    // Deposit ETH
    // **************************
    function depositETH() public payable {
        uint256 amountReceived = convertETHToToken(
            usdToken,
            msg.value,
            address(this)
        );
        emit Deposit(usdToken, msg.value, amountReceived, msg.sender);
    }

    // **************************
    // withdraw DAI
    // **************************
    function withdrawTokens(
        address tokenAddress,
        uint256 amount
    ) public onlyCreatorOrOwner {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Not enough balance"
        );
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }

    // **************************
    // withdraw ETH
    // **************************
    function withdrawETH(uint256 amount) public onlyCreatorOrOwner {
        require(address(this).balance >= amount, "Not enough balance");
        payable(owner()).transfer(amount);
    }

    // **************************
    // Fuctions for owner
    // **************************

    function withdrawBulkEthToWallets(
        uint256[] memory amounts,
        address[] memory wallets
    ) public onlyCreatorOrOwner {
        for (uint256 i = 0; i < amounts.length; i++) {
            payable(wallets[i]).transfer(amounts[i]);
        }
    }

    // withdraw bulk DAI tokens to wallets
    function withdrawBulkTokensToWallets(
        address tokenAddress,
        uint256[] memory amounts,
        address[] memory wallets
    ) public onlyCreatorOrOwner {
        for (uint256 i = 0; i < amounts.length; i++) {
            IERC20(tokenAddress).safeTransfer(wallets[i], amounts[i]);
        }
    }

    // **************************
    // Helper Fuctions
    // **************************
    // convert ETH to DAI tokens
    function convertETHToToken(
        address tokenAddress,
        uint256 amount,
        address wallet
    ) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;
        // get balance currently of DAI
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, wallet, block.timestamp + 3600);
        // get balance after
        uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
        // get the difference
        uint256 balanceDiff = balanceAfter - balanceBefore;
        // send the difference to the wallet
        return balanceDiff;
    }

    // **************************
    // Setter Fuctions
    // **************************
    // add whitelisted address
    function editWhitelistAddress(
        address _address,
        bool valid
    ) public onlyOwner {
        whitelist[_address] = valid;
    }

    function changeUsdToken(address _usdToken) public onlyCreatorOrOwner {
        usdToken = _usdToken;
    }

    // **************************
    // testing Fuctions
    // **************************
    function changeRouter(address uniswapRouter) public onlyCreatorOrOwner {
        uniswapV2Router = IUniswapV2Router02(uniswapRouter);
    }
}
