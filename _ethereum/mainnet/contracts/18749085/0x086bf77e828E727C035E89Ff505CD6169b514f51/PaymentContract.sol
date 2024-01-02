// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract EDFIAcademyPayment is Ownable, ReentrancyGuard {
    struct TokenInfo {
        string symbol;
        address tokenAddress;
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be zero");
        _;
    }

    modifier nonZeroAmount(uint256 _amount) {
        require(_amount > 0, "Amount must be greater than zero");
        _;
    }

    // Receive function to receive ETH
    event ReceivedNative(address sender, uint256 amount);

    receive() external payable {
        emit ReceivedNative(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceivedNative(msg.sender, msg.value);
    }

    // Mapping for supported tokens; can be extended
    mapping(string => address) public supportedTokens;
    string[] public supportedTokenSymbols;

    // Cut percentage for the platform; default is 0%
    uint256 public cutPercentage = 0;

    // Event for payment
    event PaymentMade(
        string indexed indexedOrderId,
        string orderId,
        address recipientAddress,
        uint256 amount,
        string currency
    );

    event CutTaken(string indexed orderId, uint256 amount, string currency);

    event TokenAdded(string indexed symbol, address indexed tokenAddress);
    event TokenRemoved(string indexed symbol);

    event CutPercentageSet(uint256 newCutPercentage);

    constructor(TokenInfo[] memory tokens) {
        for (uint i = 0; i < tokens.length; i++) {
            supportedTokens[tokens[i].symbol] = tokens[i].tokenAddress;
            supportedTokenSymbols.push(tokens[i].symbol);
        }
    }

    function addSupportedToken(
        string calldata symbol,
        address tokenAddress
    ) external onlyOwner {
        require(supportedTokens[symbol] == address(0), "Token already added");

        supportedTokens[symbol] = tokenAddress;
        supportedTokenSymbols.push(symbol);

        emit TokenAdded(symbol, tokenAddress);
    }

    function removeSupportedToken(string calldata symbol) external onlyOwner {
        require(supportedTokens[symbol] != address(0), "Token not found");

        // Remove from mapping
        supportedTokens[symbol] = address(0);

        // Remove from supportedTokenSymbols array
        for (uint256 i = 0; i < supportedTokenSymbols.length; i++) {
            if (
                keccak256(abi.encodePacked(supportedTokenSymbols[i])) ==
                keccak256(abi.encodePacked(symbol))
            ) {
                supportedTokenSymbols[i] = supportedTokenSymbols[
                    supportedTokenSymbols.length - 1
                ];
                supportedTokenSymbols.pop();
                break;
            }
        }

        emit TokenRemoved(symbol);
    }

    // Function to return all supported token symbols and their addresses
    function getAllSupportedTokens()
        public
        view
        returns (string[] memory, address[] memory)
    {
        uint256 length = supportedTokenSymbols.length;
        address[] memory addresses = new address[](length);

        for (uint i = 0; i < length; i++) {
            string memory symbol = supportedTokenSymbols[i];
            addresses[i] = supportedTokens[symbol];
        }

        return (supportedTokenSymbols, addresses);
    }

    function setCutPercentage(uint256 newCutPercentage) external onlyOwner {
        require(newCutPercentage <= 100, "Invalid percentage");
        cutPercentage = newCutPercentage;
        emit CutPercentageSet(newCutPercentage);
    }

    function pay(
        string calldata orderId,
        address recipientAddress,
        uint256 amount,
        string calldata currency
    )
        external
        nonReentrant
        nonZeroAddress(recipientAddress)
        nonZeroAmount(amount)
    {
        address tokenAddress = supportedTokens[currency];
        require(tokenAddress != address(0), "Unsupported currency");

        // Directly transfer tokens from sender to recipient, handling the cut
        _processPayment(
            orderId,
            msg.sender,
            recipientAddress,
            amount,
            currency
        );
    }

    function payWithNative(
        string calldata orderId,
        address payable recipientAddress
    ) external payable nonReentrant nonZeroAddress(recipientAddress) {
        uint256 amount = msg.value;
        require(amount > 0, "Amount must be greater than 0");

        // Process payment and emit events for native token
        _processPayment(orderId, msg.sender, recipientAddress, amount, "ETH");
    }

    // Internal helper function to transfer ERC20 tokens
    function _transferERC20(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20 token = IERC20(tokenAddress);

        // Check that the user has approved the contract to spend their tokens
        uint256 allowed = token.allowance(from, address(this));
        require(allowed >= amount, "Insufficient allowance for contract");

        // Perform the token transfer
        require(
            token.transferFrom(from, to, amount),
            "Failed to transfer tokens"
        );
    }

    // Internal helper function to process payment and emit events
    function _processPayment(
        string calldata orderId,
        address from,
        address recipientAddress,
        uint256 amount,
        string memory currency
    ) internal {
        // Calculate cut and transfer amounts
        uint256 cutAmount = (amount * cutPercentage) / 100;
        uint256 transferAmount = amount - cutAmount;

        if (keccak256(bytes(currency)) == keccak256("ETH")) {
            // Handle ETH payment
            payable(recipientAddress).transfer(transferAmount);
            if (cutAmount > 0) {
                payable(address(this)).transfer(cutAmount);
            }
        } else {
            // Handle ERC20 token payment
            _transferERC20(
                supportedTokens[currency],
                from,
                recipientAddress,
                transferAmount
            );
            if (cutAmount > 0) {
                _transferERC20(
                    supportedTokens[currency],
                    from,
                    address(this),
                    cutAmount
                );
            }
        }

        // Emit events
        emit PaymentMade(orderId, orderId, recipientAddress, amount, currency);
        if (cutAmount > 0) {
            emit CutTaken(orderId, cutAmount, currency);
        }
    }

    function withdrawAll() external onlyOwner {
        // Withdraw ETH
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            payable(owner()).transfer(ethBalance);
        }

        // Withdraw each supported token
        for (uint i = 0; i < supportedTokenSymbols.length; i++) {
            address tokenAddress = supportedTokens[supportedTokenSymbols[i]];
            IERC20 token = IERC20(tokenAddress);
            uint256 tokenBalance = token.balanceOf(address(this));
            if (tokenBalance > 0) {
                token.transfer(owner(), tokenBalance);
            }
        }
    }
}
