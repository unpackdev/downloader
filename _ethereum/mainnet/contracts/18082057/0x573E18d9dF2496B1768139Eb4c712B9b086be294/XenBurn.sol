// SPDX-License-Identifier: MIT

/*


██╗  ██╗███████╗███╗   ██╗    ██████╗ ██╗   ██╗██████╗ ███╗   ██╗
╚██╗██╔╝██╔════╝████╗  ██║    ██╔══██╗██║   ██║██╔══██╗████╗  ██║
 ╚███╔╝ █████╗  ██╔██╗ ██║    ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
 ██╔██╗ ██╔══╝  ██║╚██╗██║    ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
██╔╝ ██╗███████╗██║ ╚████║    ██████╔╝╚██████╔╝██║  ██║██║ ╚████║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
                                                                 

*/

pragma solidity 0.8.17;
//import "./console.sol";

import "./IUniswapV2Router02.sol";


interface IPriceOracle {
    function calculateAveragePrice() external view returns (uint256);
    function calculateV2Price() external view returns (uint256);
}

interface IBurnRedeemable {
    function onTokenBurned(address user, uint256 amount) external;
}

interface IBurnableToken {
    function burn(address user, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IPlayerNameRegistryBurn {
    function getPlayerNames(address playerAddress) external view returns (string[] memory);
}

contract xenBurn is IBurnRedeemable {
    address public xenCrypto;
    mapping(address => bool) private burnSuccessful;
    mapping(address => uint256) public lastCall;
    mapping(address => uint256) public callCount;
    uint256 public totalCount;
    uint256 public totalXenBurned;
    uint256 public totalEthBurned;
    address private uniswapPool = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IPriceOracle private priceOracle;
    IPlayerNameRegistryBurn private playerNameRegistry;

    constructor(address _priceOracle, address _xenCrypto, address _playerNameRegistry) {
        priceOracle = IPriceOracle(_priceOracle);
        xenCrypto = _xenCrypto;
        playerNameRegistry = IPlayerNameRegistryBurn(_playerNameRegistry);
    }

    event TokenBurned(address indexed user, uint256 amount, string playerName);

    // Modifier to allow only human users to perform certain actions
    modifier isHuman() {
        require(msg.sender == tx.origin, "Only human users can perform this action");
        _;
    }

    // Modifier to enforce restrictions on the frequency of calls
    modifier gatekeeping() {
        require(
            (lastCall[msg.sender] + 1 days) <= block.timestamp || (callCount[msg.sender] + 5) <= totalCount,
            "Function can only be called once per 24 hours, or 5 times within the 24-hour period by different users"
        );
        _;
    }

    // Function to burn tokens by swapping ETH for the token
    function burnXenCrypto() public isHuman gatekeeping {
        require(address(this).balance > 0, "No ETH available");

        address player = msg.sender;

        // Pull player's name from game contract
        string[] memory names = playerNameRegistry.getPlayerNames(player);
        require(names.length > 0, "User must have at least 1 name registered");

        // Amount to use for swap (98% of the contract's ETH balance)
        uint256 amountETH = address(this).balance * 98 / 100;
        totalEthBurned += amountETH;

        // Get current token price from PriceOracle
        uint256 tokenPrice = priceOracle.calculateAveragePrice();
        

        // Calculate the minimum amount of tokens to purchase. Slippage set to 10% max
        uint256 minTokenAmount = (amountETH * tokenPrice * 90) / 100;

        // Perform a Uniswap transaction to swap the ETH for tokens
        uint256 deadline = block.timestamp + 150; // 15 second deadline
        uint256[] memory amounts = IUniswapV2Router02(uniswapPool).swapExactETHForTokens{value: amountETH}(
            minTokenAmount, getPathForETHtoTOKEN(), address(this), deadline
        );

        // The actual amount of tokens received from the swap is stored in amounts[1]
        uint256 actualTokenAmount = amounts[1];

        // Verify that the trade happened successfully
        require(actualTokenAmount >= minTokenAmount, "Uniswap trade failed");

        // Update the call count and last call timestamp for the user
        totalCount++;
        callCount[player] = totalCount;
        lastCall[player] = block.timestamp;

        // Transfer the Xen to the user
        IBurnableToken(xenCrypto).transfer(player, actualTokenAmount);

        // Call the external contract to burn tokens
        IBurnableToken(xenCrypto).burn(player, actualTokenAmount);

        // Check if the burn was successful
        require(burnSuccessful[player], "Token burn was not successful");

        // Reset the burn successful status for the user
        burnSuccessful[player] = false;
    }

    // Function to calculate the expected amount of tokens to be burned based on the contract's ETH balance and token price
    function calculateExpectedBurnAmount() public view returns (uint256) {
        // Check if the contract has ETH balance
        if (address(this).balance == 0) {
            return 0;
        }

        // Calculate the amount of ETH to be used for the swap (98% of the contract's ETH balance)
        uint256 amountETH = address(this).balance;

        // Get current token price from PriceOracle
        uint256 tokenPrice = priceOracle.calculateV2Price();

        // Calculate the expected amount of tokens to be burned
        uint256 expectedBurnAmount = (amountETH * tokenPrice);

        return expectedBurnAmount;
    }

    // Function to deposit ETH into the contract
    function deposit() public payable returns (bool) {
        require(msg.value > 0, "No ETH received");
        return true;
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Function to get the path for swapping ETH to the token
    function getPathForETHtoTOKEN() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswapPool).WETH();
        path[1] = xenCrypto;
        return path;
    }

    // Implementation of the onTokenBurned function from the IBurnRedeemable interface
    function onTokenBurned(address user, uint256 amount) external override {
        require(msg.sender == address(xenCrypto), "Invalid caller");        

        // Transfer 1% of the ETH balance to the user who called the function
        uint256 amountETH = address(this).balance / 2;

        // Set the burn operation as successful for the user
        burnSuccessful[user] = true;
        totalXenBurned += amount;

        address payable senderPayable = payable(user);
        (bool success,) = senderPayable.call{value: amountETH}("");
        require(success, "Transfer failed.");        

        // Pull player's name from the PlayerNameRegistry contract
        string[] memory names = playerNameRegistry.getPlayerNames(user);

        string memory playerName = names[0];

        // Emit the TokenBurned event
        emit TokenBurned(user, amount, playerName);
    }

    // Function to check if a user's burn operation was successful
    function wasBurnSuccessful(address user) external view returns (bool) {
        return burnSuccessful[user];
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IBurnRedeemable).interfaceId;
    }
}
