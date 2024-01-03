// Sources flattened with hardhat v2.0.3 https://hardhat.org

// File contracts/utils/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: No License

pragma solidity 0.6.6;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}


// File contracts/interfaces/IProtocolFactory.sol

// SPDX-License-Identifier: No License

pragma solidity 0.6.6;

/**
 * @dev ProtocolFactory contract interface. See {ProtocolFactory}.
 * @author crypto-pumpkin@github
 */
interface IProtocolFactory {
  /// @notice emit when a new protocol is supported in COVER
  event ProtocolInitiation(address protocolAddress);

  function getAllProtocolAddresses() external view returns (address[] memory);
  function getRedeemFees() external view returns (uint16 _numerator, uint16 _denominator);
  function redeemFeeNumerator() external view returns (uint16);
  function redeemFeeDenominator() external view returns (uint16);
  function protocolImplementation() external view returns (address);
  function coverImplementation() external view returns (address);
  function coverERC20Implementation() external view returns (address);
  function treasury() external view returns (address);
  function governance() external view returns (address);
  function claimManager() external view returns (address);
  function protocols(bytes32 _protocolName) external view returns (address);

  function getProtocolsLength() external view returns (uint256);
  function getProtocolNameAndAddress(uint256 _index) external view returns (bytes32, address);
  /// @notice return contract address, the contract may not be deployed yet
  function getProtocolAddress(bytes32 _name) external view returns (address);
  /// @notice return contract address, the contract may not be deployed yet
  function getCoverAddress(bytes32 _protocolName, uint48 _timestamp, address _collateral, uint256 _claimNonce) external view returns (address);
  /// @notice return contract address, the contract may not be deployed yet
  function getCovTokenAddress(bytes32 _protocolName, uint48 _timestamp, address _collateral, uint256 _claimNonce, bool _isClaimCovToken) external view returns (address);

  /// @notice access restriction - owner (dev)
  /// @dev update this will only affect contracts deployed after
  function updateProtocolImplementation(address _newImplementation) external returns (bool);
  /// @dev update this will only affect contracts deployed after
  function updateCoverImplementation(address _newImplementation) external returns (bool);
  /// @dev update this will only affect contracts deployed after
  function updateCoverERC20Implementation(address _newImplementation) external returns (bool);
  function assignClaimManager(address _address) external returns (bool);
  function addProtocol(
    bytes32 _name,
    bool _active,
    address _collateral,
    uint48[] calldata _timestamps,
    bytes32[] calldata _timestampNames
  ) external returns (address);

  /// @notice access restriction - governance
  function updateClaimManager(address _address) external returns (bool);
  function updateFees(uint16 _redeemFeeNumerator, uint16 _redeemFeeDenominator) external returns (bool);
  function updateGovernance(address _address) external returns (bool);
  function updateTreasury(address _address) external returns (bool);
}


// File contracts/interfaces/IProtocol.sol

// SPDX-License-Identifier: No License

pragma solidity 0.6.6;

/**
 * @dev Protocol contract interface. See {Protocol}.
 * @author crypto-pumpkin@github
 */
interface IProtocol {
  /// @notice emit when a claim against the protocol is accepted
  event ClaimAccepted(uint256 newClaimNonce);

  function getProtocolDetails()
    external view returns (
      bytes32 _name,
      bool _active,
      uint256 _claimNonce,
      uint256 _claimRedeemDelay,
      uint256 _noclaimRedeemDelay,
      address[] memory _collaterals,
      uint48[] memory _expirationTimestamps,
      address[] memory _allCovers,
      address[] memory _allActiveCovers
    );
  function active() external view returns (bool);
  function name() external view returns (bytes32);
  function claimNonce() external view returns (uint256);
  /// @notice delay # of seconds for redeem with accepted claim, redeemCollateral is not affected
  function claimRedeemDelay() external view returns (uint256);
  /// @notice delay # of seconds for redeem without accepted claim, redeemCollateral is not affected
  function noclaimRedeemDelay() external view returns (uint256);
  function activeCovers(uint256 _index) external view returns (address);
  function claimDetails(uint256 _claimNonce) external view returns (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _timestamp);
  function collateralStatusMap(address _collateral) external view returns (uint8 _status);
  function expirationTimestampMap(uint48 _expirationTimestamp) external view returns (bytes32 _name, uint8 _status);
  function coverMap(address _collateral, uint48 _expirationTimestamp) external view returns (address);

  function collaterals(uint256 _index) external view returns (address);
  function collateralsLength() external view returns (uint256);
  function expirationTimestamps(uint256 _index) external view returns (uint48);
  function expirationTimestampsLength() external view returns (uint256);
  function activeCoversLength() external view returns (uint256);
  function claimsLength() external view returns (uint256);
  function addCover(address _collateral, uint48 _timestamp, uint256 _amount)
    external returns (bool);

  /// @notice access restriction - claimManager
  function enactClaim(uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint256 _protocolNonce) external returns (bool);

  /// @notice access restriction - dev
  function setActive(bool _active) external returns (bool);
  function updateExpirationTimestamp(uint48 _expirationTimestamp, bytes32 _expirationTimestampName, uint8 _status) external returns (bool);
  function updateCollateral(address _collateral, uint8 _status) external returns (bool);

  /// @notice access restriction - governance
  function updateClaimRedeemDelay(uint256 _claimRedeemDelay) external returns (bool);
  function updateNoclaimRedeemDelay(uint256 _noclaimRedeemDelay) external returns (bool);
}


// File contracts/interfaces/IBalancerPool.sol

// SPDX-License-Identifier: No License

pragma solidity 0.6.6;

interface IBalancerPool {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
}


// File contracts/Minter.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

contract Arbys is Ownable {
    IProtocolFactory public factory;
    IERC20 public daiToken;
    uint48 public expirationTime;

    // Initialize, called once
    constructor (
      IProtocolFactory _factory,
      IERC20 daiToken_
    )
      public Ownable()
    {
      factory = _factory;
      daiToken = daiToken_;
    }

    function arbitrageSell(IProtocol _protocol, IBalancerPool _claimPool, IBalancerPool _noclaimPool, uint48 _expiration, uint _daiAmount) external {
      daiToken.transferFrom(msg.sender, address(this), _daiAmount);
      if (daiToken.allowance(address(this), address(_protocol)) < _daiAmount) {
        daiToken.approve(address(_protocol), _daiAmount);
      }
      _protocol.addCover(address(daiToken), _expiration, _daiAmount);

      address noclaimTokenAddr = factory.getCovTokenAddress(_protocol.name(), _expiration, address(daiToken), _protocol.claimNonce(), false);
      address claimTokenAddr = factory.getCovTokenAddress(_protocol.name(), _expiration, address(daiToken), _protocol.claimNonce(), true);

      _swapTokenForDai(_noclaimPool, IERC20(noclaimTokenAddr), _daiAmount);
      _swapTokenForDai(_claimPool, IERC20(claimTokenAddr), _daiAmount);

      uint256 bal = daiToken.balanceOf(address(this));
      require(bal > _daiAmount, "No arbys");
      require(daiToken.transfer(msg.sender, bal), "ERR_TRANSFER_FAILED");
    }

    function _swapTokenForDai(IBalancerPool _bPool, IERC20 token, uint _sellAmount) private {
        if (token.allowance(address(this), address(_bPool)) < _sellAmount) {
          token.approve(address(_bPool), _sellAmount);
        }
        IBalancerPool(_bPool).swapExactAmountIn(
            address(token),
            _sellAmount,
            address(daiToken),
            0, // minAmountOut, set to 0 -> sell no matter how low the price of CLAIM tokens are
            2**256 - 1 // maxPrice, set to max -> accept any swap prices
        );
    }

    function destroy() external onlyOwner {
        selfdestruct(msg.sender);
    }

    receive() external payable {}
}