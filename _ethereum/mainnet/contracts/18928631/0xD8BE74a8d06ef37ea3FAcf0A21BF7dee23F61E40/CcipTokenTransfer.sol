// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./Client.sol";
import "./IRouterClient.sol";
import "./IERC20.sol";
import "./AddressArrayUtils.sol";

contract CCIPTokenTransfer {
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);
    error DestinationChainNotWhitelisted(uint64 destinationChainSelector);

    event ChainWhitelisted(uint64 indexed destinationChainSelector);
    event TokensTransferred(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address token,
        uint256 tokenAmount,
        address feeToken,
        uint256 fees
    );
    event OwnerUpdated(address indexed newOwner);

    // Mapping to track allowed destination chains
    mapping(uint64 => bool) public whitelistedChains;

    // Instance of CCIP Router
    IRouterClient public router;
    // LINK fee token
    IERC20 public LINK;

    // The address with administrative privileges over this contract
    address public owner;

    /// @dev Modifier that checks if the chain with the given destinationChainSelector is whitelisted
    /// @param _destinationChainSelector The selector of the destination chain
    modifier onlyWhitelistedChain(uint64 _destinationChainSelector) {
        if (!whitelistedChains[_destinationChainSelector]) {
            revert DestinationChainNotWhitelisted(_destinationChainSelector);
        }
        _;
    }

    /// @dev Modifier that checks whether the msg.sender is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Constructor initializes the contract with the router address
    /// @param _router The address of the router contract
    /// @param _link The address of the link contract
    constructor(address _router, address _link, address _owner) {
        router = IRouterClient(_router);
        LINK = IERC20(_link);
        owner = _owner;
    }

    function _previewFee(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeToken
    ) internal view returns (uint256) {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _token, _amount, _feeToken);
        return router.getFee(_destinationChainSelector, evm2AnyMessage);
    }

    function _maxApproveLink() internal {
        if (LINK.allowance(owner, address(router)) == 0) {
            LINK.approve(address(router), type(uint256).max);
        }
    }

    function _maxApproveToken(address _token) internal {
        if (IERC20(_token).allowance(owner, address(router)) == 0) {
            IERC20(_token).approve(address(router), type(uint256).max);
        }
    }

    /// @notice Find all tokens from input address array that are supported on destination chain
    /// @param _chainSelector The identifier for destination blockchain
    /// @param _tokens array of token addresses
    /// @return filteredTokens Address array of tokens that are supported
    function filterSupportedTokens(uint64 _chainSelector, address[] memory _tokens)
        public
        view
        returns (address[] memory)
    {
        address[] memory supportedTokens = router.getSupportedTokens(_chainSelector);
        return AddressArrayUtils.intersect(supportedTokens, _tokens);
    }

    /// @notice Test whether a specific token is valid on destination chain
    /// @param _chainSelector The identifier for destination blockchain
    /// @param _token token address
    /// @return isSupported Boolean indicating whether token is supported
    function tokenIsValid(uint64 _chainSelector, address _token) external view returns (bool isSupported) {
        address[] memory tokenArray = new address[](1);
        tokenArray[0] = _token;
        address[] memory supportedTokens = filterSupportedTokens(_chainSelector, tokenArray);
        return supportedTokens.length == 1;
    }

    /// @notice Estimate fee transfer tokens to destination chain paying LINK as gas
    /// @param _destinationChainSelector The identifier for destination blockchain
    /// @param _receiver The address of the recipient on destination blockchai
    /// @param _token token address
    /// @param _amount token amount
    /// @return fee Amount of LINK token to provide as fee
    function previewFeeLINK(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount)
        external
        view
        returns (uint256 fee)
    {
        return _previewFee(_destinationChainSelector, _receiver, _token, _amount, address(LINK));
    }

    /// @notice Estimate fee transfer tokens to destination chain paying in native gas
    /// @param _destinationChainSelector The identifier for destination blockchain
    /// @param _receiver The address of the recipient on destination blockchai
    /// @param _token token address
    /// @param _amount token amount
    /// @return fee Amount of native token to provide as fee
    function previewFeeNative(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount)
        external
        view
        returns (uint256 fee)
    {
        return _previewFee(_destinationChainSelector, _receiver, _token, _amount, address(0));
    }

    /// @notice Transfer tokens to receiver on the destination chain
    /// @notice pay in LINK
    /// @notice the token must be in the list of supported tokens
    /// @notice This function can only be called by the owner
    /// @dev Assumes your contract has sufficient LINK tokens to pay for the fees
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain
    /// @param _receiver The address of the recipient on the destination blockchain
    /// @param _token token address
    /// @param _amount token amount
    /// @return messageId The ID of the message that was sent
    function transferTokensPayLINK(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount)
        external
        onlyWhitelistedChain(_destinationChainSelector)
        returns (bytes32 messageId)
    {
        // Create EVM2AnyMessage with information for sending cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _token, _amount, address(LINK));

        // Get the required fee
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        // Approve the Router to transfer LINK tokens on contract's behalf
        _maxApproveLink();
        // Approve the Router to spend tokens on contract's behalf
        _maxApproveToken(_token);

        // Pull funds to transfer and gas fee from user to contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        LINK.transferFrom(msg.sender, address(this), fees);

        // Send the message through the router
        messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);
        emit TokensTransferred(messageId, _destinationChainSelector, _receiver, _token, _amount, address(LINK), fees);
        return messageId;
    }

    /// @notice Transfer tokens to receiver on the destination chain
    /// @notice Pay in native gas such as ETH on Ethereum or MATIC on Polgon
    /// @notice the token must be in the list of supported tokens
    /// @dev Assumes your contract has sufficient native gas like ETH on Ethereum or MATIC on Polygon
    /// @param _destinationChainSelector The identifier for destination blockchain
    /// @param _receiver The address of the recipient on destination blockchain
    /// @param _token token address
    /// @param _amount token amount
    /// @return messageId The ID of the message that was sent
    function transferTokensPayNative(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable onlyWhitelistedChain(_destinationChainSelector) returns (bytes32 messageId) {
        // Create EVM2AnyMessage with information for sending cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _token, _amount, address(0));

        // Get the required fee
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);
        if (fees > address(this).balance) {
            revert NotEnoughBalance(address(this).balance, fees);
        }

        // approve the Router to spend token on contract's behalf
        _maxApproveToken(_token);

        // Pull funds to transfer from user to contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Send the message through the router
        messageId = router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);
        emit TokensTransferred(messageId, _destinationChainSelector, _receiver, _token, _amount, address(0), fees);
        return messageId;
    }

    /// @notice Construct a CCIP message
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer
    /// @param _receiver The address of the receiver
    /// @param _token The token to be transferred
    /// @param _amount The amount of the token to be transferred
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message
    function _buildCCIPMessage(address _receiver, address _token, uint256 _amount, address _feeTokenAddress)
        internal
        pure
        returns (Client.EVM2AnyMessage memory)
    {
        // Set the token amounts
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: _token, amount: _amount});

        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: "", // No data
            tokenAmounts: tokenAmounts, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit to 0 as we are not sending any data and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 0, strict: false})
                ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
    }

    /// @notice Fallback function to allow the contract to receive Ether
    /// It is automatically called when Ether is transferred to the contract without any data
    receive() external payable {}

    /// @dev Updates the whitelist status of a destination chain for transactions
    /// @notice This function can only be called by the owner
    /// @param _destinationChainSelector The selector of the destination chain to be updated
    /// @param allowed The whitelist status to be set for the destination chain
    function whitelistDestinationChain(uint64 _destinationChainSelector, bool allowed) external onlyOwner {
        whitelistedChains[_destinationChainSelector] = allowed;
    }

    /// @notice Allows the contract owner to withdraw the entire balance of Ether from the contract
    /// @notice This function can only be called by the owner
    /// @dev This function reverts if there are no funds to withdraw or if the transfer fails
    /// @param _beneficiary The address to which the Ether should be transferred
    function withdraw(address _beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent,) = _beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    /// @notice Allows the owner of the contract to withdraw all tokens of a specific ERC20 token
    /// @notice This function can only be called by the owner
    /// @dev This function reverts with a 'NothingToWithdraw' error if there are no tokens to withdraw
    /// @param _beneficiary The address to which the tokens will be sent
    /// @param _token The contract address of the ERC20 token to be withdrawn
    function withdrawToken(address _beneficiary, address _token) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).transfer(_beneficiary, amount);
    }

    /// @notice Updates the owner address of this contract.
    /// @notice This function can only be called by the owner
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    /// @notice Sets router allowance to 0 to disable transferring tokens out of contract
    /// @notice This function can only be called by the owner
    /// @param _token The contract address of the ERC20 token to disable
    function revokeRouterAllowance(address _token) external onlyOwner {
        LINK.approve(address(router), 0);
        IERC20(_token).approve(address(router), 0);
    }
}
