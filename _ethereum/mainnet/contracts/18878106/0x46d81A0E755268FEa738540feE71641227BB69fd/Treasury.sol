// SPDX-License-Identifier: MIT
// Treasury 
pragma solidity 0.8.21;

import "MarketConnector.sol";
import "IERC20Burn.sol";
import "TransferHelper.sol";

/// @title Treasury 
/// @author UBD Team
/// @notice This contract store UBD ecosystem treasuruy assets
/// @dev  Check deploy params so they are immutable
contract Treasury is MarketConnector {

	uint256 public constant SANDBOX2_TOPUP_PERCENT  = 330000; //   1% -   10000, 13% - 130000, etc 
    uint256 public constant SANDBOX1_REDEEM_PERCENT =  10000; //   1% -   10000, 13% - 130000, etc 
    uint256 public constant PERCENT_DENOMINATOR = 10000; 

    
    modifier onlyMarketRegistry()
    {
        require(msg.sender == marketRegistry, 'Only for MarketRegistry');
        _;
    }

    event ReceivedEther(address, uint);
    
    constructor(address _markets)
        MarketConnector(_markets)
    {
        require(_markets != address(0), 'No zero markets');
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
    
    /// @notice Send one erc20 treasury asset for swap
    /// @dev Can be called only from MarketRegistry
    /// @param _marketAdapter  - address of AMM adapter contract
    /// @param _erc20 - address of erc20 treasury tokens
    /// @param _amount - amount of erc20 for  send
    function sendOneERC20ForSwap(address _marketAdapter, address _erc20, uint256 _amount) 
        external
        onlyMarketRegistry 
    {
        
        TransferHelper.safeTransfer(_erc20, _marketAdapter, _amount);
    }

    /// @notice Send all erc20 treasury asset for swap
    /// @dev Can be called only from MarketRegistry
    /// @param _marketAdapter  - address of AMM adapter contract
    /// @param _percent - percent of Treasury balance
    function sendERC20ForSwap(address _marketAdapter, uint256 _percent) 
        external
        onlyMarketRegistry 
        returns(uint256[] memory)
    {
        
        return _sendPercentOfTreasuryTokens(_marketAdapter, _percent);
    }

    /// @notice Send ether from  treasury asset for swap
    /// @dev Can be called only from MarketRegistry
    /// @param _percent - percent of Treasury balance
    function sendEtherForRedeem(uint256 _percent) 
        external 
        onlyMarketRegistry 
        returns (uint256 amount)
    {
        amount = address(this).balance * _percent / (100 * PERCENT_DENOMINATOR); 
        TransferHelper.safeTransferETH(marketRegistry, amount);
    }

   
    /// @notice Returns native token and erc20 balance of address in stableToken units
    /// @dev Second param is array
    /// @param _holder - address for get balance
    /// @param _assets - array of erc20 address for get balance
    function getBalanceInStableUnits(address _holder, address[] memory _assets) 
        external 
        view 
        returns(uint256)
    {
        return _getBalanceInStableUnits(_holder, _assets);
    }

    /// @notice Check conditions for Sandox2 topup
    /// @dev Actualy check UBD ecosystem collateral Level
    function isReadyForTopupSandBox2() public view returns(bool) {
        if (_getCollateralSystemLevelM10() >= 30) {
            return true;
        }
    }

    /// @notice Returns array of erc20 Treasury assets
    /// @dev Keep in mind that Native asset always exist
    function treasuryERC20Assets() public view returns(address[] memory assets) {
         return IMarketRegistry(marketRegistry).treasuryERC20Assets();
    }

    function _sendPercentOfTreasuryTokens(address _to, uint256 _percent) 
        internal 
        returns(uint256[] memory)
    {
        uint256 treasuryERC20AssetsCount = treasuryERC20Assets().length;
        address[] memory _treasuryERC20Assets = new address[](treasuryERC20AssetsCount);
        uint256[] memory _treasuryERC20sended = new uint256[](treasuryERC20AssetsCount);
        _treasuryERC20Assets = treasuryERC20Assets();
        for (uint8 i = 0; i < _treasuryERC20Assets.length; ++ i){
            _treasuryERC20sended[i] = IERC20(_treasuryERC20Assets[i]).balanceOf(address(this)) 
                * _percent / (100 * PERCENT_DENOMINATOR); 
            TransferHelper.safeTransfer(
                _treasuryERC20Assets[i],
                _to, 
                _treasuryERC20sended[i]
            );
        }
        return _treasuryERC20sended;

    }
}