// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IVaultBase.sol";

/// @title VaultL1
contract VaultL1 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    address public arbitrumVaultAddress;

    bool public paused;

    address public polygonVaultAddress;

    /// @dev provider address => token address -> balance
    mapping(address => mapping(address => uint256)) internal providersBalance;

    /// @notice Public function to query the supported tokens list
    /// @dev token address => bool supported/not supported
    mapping(address => bool) public whitelistedTokens;

    /// @notice Public mapping to store/get the max cap per token
    mapping(address => uint256) public maxAssetCap;

    // @notice Public mapping to keep track for the withdraw paused / asset
    mapping(address => bool) public allowToWithdraw;

    /// @notice event emitted when a token is send to L2 network
    /// @param destination address of the receiver
    /// @param token address of the token
    /// @param amount token amount send
    event AssetSend(
        address indexed destination,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when a token is moved to another account
    /// @param token address of the token
    /// @param destination address of the receiver
    /// @param amount token amount send
    event FundsMoved(
        address indexed token,
        address indexed destination,
        uint256 amount
    );
    
    /// @notice event emitted when a token is added to the whitelist
    /// @param token address of the token
    /// @param maxCap amount of the max cap of the token
    event TokenAddedToWhitelist(
        address indexed token,
        uint256 maxCap
    );
    
    /// @notice event emitted when a token is removed from the whitelist
    /// @param token address of the token
    event TokenRemovedFromWhitelist(
        address indexed token
    );
    
    /// @notice event emitted when a token max cap is modified
    /// @param token address of the token
    /// @param newMaxCap amount of the max cap of the token
    event TokenMaxCapEdited(
        address indexed token,
        uint256 newMaxCap
    );

    /// @notice event emitted when user make a deposit
    /// @param sender address of the person who made the token deposit
    /// @param token address of the token
    /// @param amount amount of token deposited on this action
    /// @param totalAmount total amount of token deposited
    /// @param timestamp block.timestamp timestamp of the deposit
    event Deposit(
        address indexed sender,
        address indexed token,
        uint256 amount,
        uint256 indexed totalAmount,
        uint256 timestamp
    );

    /// @notice event emitted when user withdraw token from the contract
    /// @param sender address of the person who withdraw his token
    /// @param token address of the token
    /// @param amount amount of token withdrawn
    /// @param totalAmount total amount of token remained deposited
    /// @param timestamp block.timestamp timestamp of the withdrawal
    event Withdrawal(
        address indexed sender,
        address indexed token,
        uint256 amount,
        uint256 indexed totalAmount,
        uint256 timestamp
    );

    /// @notice event emitted when admin pause the contract
    /// @param admin address of the admin who pause the contract
    event Pause(address admin);

    /// @notice event emitted when admin unpause the contract
    /// @param admin address of the admin who unpause the contract
    event Unpause(address admin);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Public setter function for Arbitrum vault address
    /// @param _newAddress new address of the vault
    function setArbitrumVaultAddress(address _newAddress) public onlyOwner validAddress(_newAddress) {
        arbitrumVaultAddress = _newAddress;
    }

    /// @notice Public setter function for Polygon vault address
    /// @param _newAddress new address of the vault
    function setPolygonVaultAddress(address _newAddress) public onlyOwner validAddress(_newAddress) {
        polygonVaultAddress = _newAddress;
    }

    /// @notice external function used to add token in the whitelist
    /// @param _token ERC20 token address
    function addWhitelistedToken(address _token, uint256 _maxCap)
    external
    onlyOwner
    validAddress(_token)
    validAmount(_maxCap)
    {
        whitelistedTokens[_token] = true;
        maxAssetCap[_token] = _maxCap;

        emit TokenAddedToWhitelist(_token, _maxCap);
    }

    function setMaxCapAsset(address _token, uint256 _maxCap)
    external
    onlyOwner
    onlySupportedToken(_token)
    validAmount(_maxCap)
    {
        require(getTokenBalance(_token) <= _maxCap, "Current token balance is higher");
        maxAssetCap[_token] = _maxCap;
        
        emit TokenMaxCapEdited(_token, _maxCap);
    }

    /// @notice external function used to remove token from the whitelist
    /// @param _token ERC20 token address
    function removeWhitelistedToken(address _token)
    external
    onlyOwner
    validAddress(_token)
    {
        delete whitelistedTokens[_token];
        delete maxAssetCap[_token];

        emit TokenRemovedFromWhitelist(_token);
    }

    /// @notice callable function used to send asset to another wallet
    /// @param _destination address of the token receiver
    /// @param _token address of the token
    /// @param _amount amount send
    function moveFunds(
        address _destination,
        address _token,
        uint256 _amount
    )
    external
    onlyOwner
    validAddress(_destination)
    validAmount(_amount)
    {
        require(getTokenBalance(_token) >= _amount, "Not enough liquidity");
        SafeERC20.safeTransfer(IERC20(_token), _destination, _amount);
        emit FundsMoved(_token, _destination, _amount);
    }

    /// @notice callable function used to send asset to Arbitrum composable vault
    /// @param _destination address of the token receiver
    /// @param _token address of the token
    /// @param _amount amount send
    function sendAssetArbitrum(
        address _destination,
        address _token,
        uint256 _amount,
        bytes calldata _data
    )
    external
    onlyOwner
    validAddress(_destination)
    validAmount(_amount)
    {
        _sendAssetToBridge(arbitrumVaultAddress, _token, _amount, _data, _destination);
    }

    /// @notice callable function used to send asset to Polygon composable vault
    /// @param _destination address of the token receiver
    /// @param _token address of the token
    /// @param _amount amount send
    function sendAssetPolygon(
        address _destination,
        address _token,
        uint256 _amount
    )
    external
    onlyOwner
    validAddress(_destination)
    validAmount(_amount)
    {
        _sendAssetToBridge(polygonVaultAddress, _token, _amount, "", _destination);
    }

    /// @notice Internal function that execute the bridge deposit logic
    function _sendAssetToBridge(address _bridgeAddress, address _token, uint256 _amount, bytes memory data, address _destination) private
    {
        require(getTokenBalance(_token) >= _amount, "Not enough liquidity");
        SafeERC20.safeApprove(IERC20(_token), _bridgeAddress, _amount);
        IVaultBase(_bridgeAddress).depositERC20ForAddress(_amount, _token, data, _destination);
        emit AssetSend(_destination, _token, _amount);
    }

    /// @notice External callable function used to withdraw liquidity from contract
    /// @dev This function withdraw all the liquidity provider staked
    /// @param _token address of the token
    function withdraw(address _token)
    external
    nonReentrant
    {
        require(allowToWithdraw[_token], "Withdraw paused for this token");
        uint256 _providerBalance = getProviderBalance(msg.sender, _token);
        require(_providerBalance > 0, "Provider balance to low");
        require(IERC20(_token).balanceOf(address(this)) >= _providerBalance, "Not enough tokens in the vault");
        delete providersBalance[msg.sender][_token];
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, _providerBalance);

        emit Withdrawal(
            msg.sender,
            _token,
            _providerBalance,
            0,
            block.timestamp
        );
    }

    /// @notice External callable function used to add liquidity to contract
    /// @param _token address of the deposited token
    /// @param _amount amount of token deposited
    function deposit(address _token, uint256 _amount)
    external
    whenNotPaused
    validAmount(_amount)
    onlySupportedToken(_token)
    notOverMaxCap(_token, _amount)
    {
        SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);
        _deposit(_token, _amount, msg.sender);
    }

    /// @dev Internal function that contains the deposit logic
    function _deposit(address _token, uint256 _amount, address _to) internal returns (bool)
    {
        providersBalance[_to][_token] = providersBalance[_to][_token].add(_amount);
        emit Deposit(
            _to,
            _token,
            _amount,
            providersBalance[_to][_token],
            block.timestamp
        );
        return true;
    }

    /// @notice Get Vault balance for a specific token
    /// @param _token Address of the ERC20 compatible token
    function getTokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice External function called by the owner to pause asset withdrawal
    /// @param _token address of the ERC20 token
    function pauseWithdraw(address _token)
    external
    onlySupportedToken(_token)
    onlyOwner
    {
        require(allowToWithdraw[_token], "Already paused");
        delete allowToWithdraw[_token];
    }

    /// @notice External function called by the owner to unpause asset withdrawal
    /// @param _token address of the ERC20 token
    function unpauseWithdraw(address _token)
    external
    onlySupportedToken(_token)
    onlyOwner
    {
        require(!allowToWithdraw[_token], "Already allow");
        allowToWithdraw[_token] = true;
    }

    /// @notice Get ERC20 deposit amount for provider
    /// @param _provider Address of the token provider
    /// @param _token Address of the ERC20 compatible token
    function getProviderBalance(address _provider, address _token) public view returns (uint256) {
        return providersBalance[_provider][_token];
    }

    /// @notice External callable function to pause the contract
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Pause(msg.sender);
    }

    /// @notice External callable function to unpause the contract
    function unpause() external onlyOwner {
        paused = false;
        emit Unpause(msg.sender);
    }

    modifier whenNotPaused() {
        require(paused == false, "Contract is not paused");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }

    modifier onlySupportedToken(address _tokenAddress) {
        require(whitelistedTokens[_tokenAddress] == true, "Token is not supported");
        _;
    }

    modifier notOverMaxCap(address _token, uint256 _amount) {
        uint256 _tokenBalance = getTokenBalance(_token);
        require(_tokenBalance.add(_amount) <= maxAssetCap[_token], "Amount exceed max cap per asset");
        _;
    }
}
