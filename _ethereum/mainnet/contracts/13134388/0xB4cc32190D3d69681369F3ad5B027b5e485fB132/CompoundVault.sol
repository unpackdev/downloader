// CompoundVault.sol
// SPDX-License-Identifier: MIT

/**
        IDX Digital Labs Earning Protocol.
        Compound Vault Strategist
        Gihub :
        Testnet : 

 */
pragma solidity ^0.8.0;

import "./Comptroller.sol";
import "./CErc20.sol";
import "./CEther.sol";
import "./IStrategist.sol";

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";


contract CompoundVault is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum vaultOwnershp {IDXOWNED, PUBLIC, PRIVATE}

    address public ETHER;
    address public COMP;
    address public collateral;
    address public farming;
    address public strategist;
    address public deployer;
    uint256 public fees;
    uint256 public feeBase;
    uint256 public startBlock;
    uint256 public lastClaimBlock;
    uint256 public accumulatedCompPerShare;
    string public version;
    string public symbol;


    mapping(address => uint256) public shares;                  // in USD
    mapping(address => uint256) public collaterals;             // in Ctoken
    mapping(address => uint256) public CompShares;

    bytes32 STRATEGIST_ROLE;
    StrategistProxy STRATEGIST;
    Comptroller comptroller;

    event Mint(address asset, uint256 amount);
    event Redeem(address asset, uint256 amount);
    event CompoundClaimed(address caller, uint256 amount);
    event Borrowed(address asset, uint256 amount);

    /// @notice Initializer
    /// @dev Constructor for Upgradeable Contract
    /// @param _strategist adress of the strategist contract the deployer

    function initializeIt(
        address _strategist,
        address _deployer,
        address _compoundedAsset,
        address _underlyingAsset,
        uint256 _protocolFees,
        uint256 _feeBase,
        string memory _symbol
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
        _setupRole(STRATEGIST_ROLE, _strategist);
        strategist = _strategist;
        deployer = _deployer;
        fees = _protocolFees;
        feeBase = _feeBase;
        collateral = _compoundedAsset;
        farming = _underlyingAsset;
        COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
        comptroller = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
        version = "1.0";
        symbol = _symbol;
        STRATEGIST = StrategistProxy(_strategist);
        _enterCompMarket(_compoundedAsset);
    }

    /// @notice Mint idxComp.
    /// @dev Must be approved
    /// @param _amount The amount to deposit that must be approved in farming asset
    /// @return returnedCollateral the amount minted

    function mint(uint256 _amount)
        public
        payable
        whenNotPaused
        returns (uint256 returnedCollateral)
    {
        IERC20Upgradeable asset = IERC20Upgradeable(farming);
        claimComp();

        if (farming == ETHER) {
            require(msg.value > 0, "iCOMP : Zero Ether!");
            returnedCollateral = buyETHPosition(msg.value);
            shares[msg.sender] += msg.value;
        } else if (farming != ETHER) {
            require(_amount > 0, "iCOMP : Zero Amount!");
            require(
                asset.allowance(msg.sender, address(this)) >= _amount,
                "iCOMP : Insuficient allowance!"
            );

            require(
                asset.transferFrom(msg.sender, address(this), _amount),
                "iCOMP : Transfer failled!"
            );
            returnedCollateral = buyERC20Position(_amount);
            shares[msg.sender] += _amount;
        }

        collaterals[msg.sender] += returnedCollateral;
        
        emit Mint(farming, _amount);

        return returnedCollateral;
    }

    /// @notice Redeem your investement
    /// @dev require approval
    /// @param _amount the amount in native asset
    function redeem(uint256 _amount) external whenNotPaused returns (uint256 transferedAmount) {
        require(_amount > 0, "iCOMP : Zero Amount!");
           claimComp();
          
           CompShares[msg.sender] += (_amount * accumulatedCompPerShare / 1e18);   
          if(farming == ETHER){
                CEther(collateral).exchangeRateCurrent();
          }else{
                CErc20(collateral).exchangeRateCurrent();
          }
            
        // the the math
        uint256[] memory receipt = _vaultComputation(_amount);
        require(receipt[0] != 1, "iCOMP : Overflow");

        require(
            collaterals[msg.sender] >= (receipt[1] + receipt[2]),
            "iCOMP : Insufucient collaterals!"
        );
        // if there was fees
        if(receipt[1] > 0){
           collaterals[strategist] += receipt[1];
        }
        
        collaterals[msg.sender] -= (receipt[1] + receipt[2]) ;
        
        if (farming == ETHER) {
            transferedAmount = sellETHPosition(receipt[2]);

            payable(msg.sender).transfer(transferedAmount);
        } else if (farming != ETHER) {
            IERC20Upgradeable asset = IERC20Upgradeable(farming);
            transferedAmount = sellERC20Position(receipt[2]);
        
            asset.transfer(msg.sender, transferedAmount);
        }
          if(transferedAmount >= shares[msg.sender]) {
              shares[msg.sender] = 0;
          }
          else{
              shares[msg.sender] -= transferedAmount;
          }

        emit Redeem(farming, transferedAmount);

        return transferedAmount;
    }

    /// @notice BUY ERC20 Position
    /// @dev buy a position
    /// @param _amount the amount to deposit in IDXVault
    /// @return returnedAmount in collateral shares

    function buyERC20Position(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CErc20 cToken = CErc20(collateral);
        IERC20Upgradeable asset = IERC20Upgradeable(farming);
        uint256 balanceBefore = cToken.balanceOf(address(this));
        asset.safeApprove(address(cToken), _amount);
        assert(cToken.mint(_amount) == 0);
        uint256 balanceAfter = cToken.balanceOf(address(this));
        returnedAmount = balanceAfter - balanceBefore;

        return returnedAmount;
    }

    /// @notice BUY ETH Position
    /// @dev
    /// @param _amount the amount to deposit in IDXVault
    /// @return returnedAmount in collateral shares

    function buyETHPosition(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CEther cToken = CEther(collateral);
        uint256 balanceBefore = cToken.balanceOf(address(this));
        cToken.mint{value: _amount}();
        uint256 balanceAfter = cToken.balanceOf(address(this));
        returnedAmount = balanceAfter - balanceBefore;

        return returnedAmount;
    }

    /// @notice SELL ERC20 Position
    /// @dev will get the current rate to sell position at current price.
    /// @param _amount the amount in collateralls
    /// @return returnedAmount is in native asset

    function sellERC20Position(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CErc20 cToken = CErc20(collateral);
        IERC20Upgradeable asset = IERC20Upgradeable(farming);
        // we want latest rate
        uint256 balanceB = asset.balanceOf(address(this));
        cToken.approve(address(cToken), _amount);
        require(cToken.redeem(_amount) == 0, "iCOMP : CToken Redeemed Error?");
        uint256 balanceA = asset.balanceOf(address(this));
        returnedAmount = balanceA - balanceB;

        return returnedAmount; //in ERC20 native asset
    }

    /// @notice SELL ERC20 Position
    /// @dev will get the current rate to sell position at current price.
    /// @param _amount in USD
    /// @return returnedAmount in ETH based on balance

    function sellETHPosition(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CEther cToken = CEther(collateral);
        uint256 balanceBefore = address(this).balance;

        cToken.approve(address(cToken), _amount);
        require(
            cToken.redeem(_amount) == 0,
            "iCOMP : CToken Redeemed Error?"
        );
        uint256 balanceAfter = address(this).balance;
        returnedAmount = balanceAfter - balanceBefore;

        return returnedAmount; // in Ether
    }

    function _vaultComputation(uint256 _amount)
        public
        view
        returns (uint256[] memory)
    {

        uint256[] memory txData = new uint256[](4);
        uint256 rate;

        if(farming == ETHER){
            CEther token = CEther(collateral);
            rate = token.exchangeRateStored();

        }else{
           CErc20 token = CErc20(collateral);
           rate = token.exchangeRateStored();

        }
        
        uint256 underlyingMax = (rate * collaterals[msg.sender]) / 1e18;

        // if we have the available funds
        if (underlyingMax >= _amount) {
            // if the amount is not exceeding what available

            uint256 gainQuotient = quotient(
                underlyingMax,
                shares[msg.sender],
                18
            );
            uint256 amountWithdraw = _getCollateralAmount(
                (gainQuotient * _amount) / 1e18
            );
            uint256 deductedFees = _getCollateralAmount(
                ((((gainQuotient * _amount) / 1e18) - _amount) / feeBase) * fees
            );
            uint256 shareConsumed = (rate * (amountWithdraw + deductedFees)) /
                1e18;

            if (amountWithdraw + deductedFees <= collaterals[msg.sender]) {

                txData[0] = 0; // 0 error
                txData[1] = deductedFees; // the fees in collateral
                txData[2] = amountWithdraw; // the collateral amount redeeam/burned must remove fee but not burn
                txData[3] = shareConsumed;
            } else if (amountWithdraw + deductedFees > collaterals[msg.sender]) {
                // we take the maxAvailable
                gainQuotient = quotient(underlyingMax, shares[msg.sender], 18); // must be very low
                amountWithdraw = _getCollateralAmount(
                    (gainQuotient * shares[msg.sender]) / 1e18
                );

                deductedFees = collaterals[msg.sender] - amountWithdraw; 
                shareConsumed = (rate * collaterals[msg.sender]) / 1e18;

                txData[0] = 2;
                txData[1] = deductedFees;
                txData[2] = amountWithdraw;
                txData[3] = shareConsumed;
            }
        }
        else {
            txData[0] = 1;
            
        }

        return txData;
    }




    function quotient(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256 _quotient) {
        uint256 _numerator = numerator * 10**(precision + 1);
        _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }


    /// @notice Get the collaterall amount expected
    /// @dev
    /// @param _amount the amount in farming asset
    /// @return collateralAmount : The amount of cToken for the input amount in farmed asset

    function _getCollateralAmount(uint256 _amount)
        public
        view
        returns (uint256 collateralAmount)
    {   
        if(farming == ETHER){
            collateralAmount = (_amount * 1e18) / CEther(collateral).exchangeRateStored();
        }else{
            collateralAmount = (_amount * 1e18) / CErc20(collateral).exchangeRateStored();
        }
        
        return collateralAmount;
    }

    /// @notice Get the collaterall amount expected
    /// @dev
    /// @param _amount in cToken
    /// @return assetAmount : The amount of cToken for the input amount in farmed asset

    function _getAssetAmount(uint256 _amount)
        public
        view
        returns (uint256 assetAmount)
    {

        if(farming == ETHER){
             assetAmount = CEther(collateral).exchangeRateStored() * _amount / 1e18;
        }else{
             assetAmount = CErc20(collateral).exchangeRateStored() * _amount / 1e18;
        }
      
        return assetAmount;
    }


    /// @notice Comp Shares Distribution
    /// @dev

    function claimComp() internal whenNotPaused returns (uint256 amountClaimed) {
         CErc20 supplyAsset = CErc20(collateral);
        uint256 supply = supplyAsset.balanceOf(address(this));
         
        if(supply == 0){

            return 0;
        }
        
        address[] memory cTokens = new address[](1);
        cTokens[0] = collateral;

        IERC20Upgradeable Comp = IERC20Upgradeable(COMP);
        uint256 cBalanceBefore = Comp.balanceOf(address(this));

        if(farming == ETHER){
            comptroller.claimComp(address(this), cTokens);
        }else{
            comptroller.claimComp(address(this), cTokens);
        }

        uint256 cBalanceAfter = Comp.balanceOf(address(this));
        amountClaimed = cBalanceAfter - cBalanceBefore;

        accumulatedCompPerShare += amountClaimed * 1e18 / supply;

        emit CompoundClaimed(msg.sender, amountClaimed);

        return amountClaimed; 
    }


    function claimMyComp() public {
        require(CompShares[msg.sender]>0,'iCOMP : No shares!');
        IERC20Upgradeable Comp = IERC20Upgradeable(COMP);

        uint256 CompReward = CompShares[msg.sender];
        uint256 CompFees = CompReward / feeBase * fees; 
        uint256 transfered = CompReward - CompFees;

        if(transfered > Comp.balanceOf(address(this))){
            Comp.transfer(msg.sender, Comp.balanceOf(address(this)));

        }else{
           Comp.transfer(msg.sender, transfered);
        }
        Comp.transfer(msg.sender,transfered);
        CompShares[msg.sender] = 0;
        Comp.transfer(strategist, CompFees);

    }

    /// @notice ENTER COMPOUND MARKET ON DEPLOYMENT
    /// @param cAsset Exiting market for unused asset will lower the TX cost with Compound
    /// @dev For strategist

    function _enterCompMarket(address cAsset) public {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        address[] memory cTokens = new address[](1);
        cTokens[0] = cAsset;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "iCOMP : Market Fail");
    }

    /// @notice EXIT COMPOUND MARKET.
    /// @param cAsset Exiting market for unused asset will lower the TX cost with Compound
    function _exitCompMarket(address cAsset) public {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        uint256 errors = comptroller.exitMarket(cAsset);
        require(errors == 0, "Exit CMarket?");
    }

    // @notice EXIT COMPOUND MARKET.
    /// @param amount the amount to borrow
    /// @param cAsset the asset to borrow
    /// @dev funds are sent to strategist. The startegist can use the repayOnBehalf of this vault.

    function _borrowComp(
        uint256 amount,
        address cAsset,
        address asset
    ) external whenNotPaused returns (uint256 borrowed) {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        IERC20Upgradeable token = IERC20Upgradeable(asset);
        uint256 balanceBefore = token.balanceOf(address(this));
        if(farming == ETHER){
            CEther cToken = CEther(cAsset);
            require(cToken.borrow(amount) == 0, "got collateral?");
        }else{
            CErc20 cToken = CErc20(cAsset);
            require(cToken.borrow(amount) == 0, "got collateral?");
        }

        uint256 balanceAfter = token.balanceOf(address(this));
        borrowed = balanceAfter - balanceBefore;
        token.transfer(address(STRATEGIST), borrowed);

        emit Borrowed(asset, amount);
        return borrowed;
    }

    /// @notice SET VAULT FEES.
    /// @param _fees the fees in %
    /// @dev base3 where  200 = 2%

    function setFees(uint256 _fees) external {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        fees = _fees;
    }

    /// @notice Strategist fees.
  
    function getFees() external {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
         uint256 feeCollected;
        if(farming == ETHER){
            CEther cToken = CEther(collateral);
            cToken.approve(address(cToken), collaterals[strategist]);
            feeCollected = sellETHPosition(collaterals[strategist]);
            payable(strategist).transfer(feeCollected);

        }else{
              IERC20Upgradeable asset = IERC20Upgradeable(farming);
              CErc20 cToken = CErc20(collateral);  
              cToken.approve(address(cToken), collaterals[strategist]);  
              sellERC20Position(collaterals[strategist]);
              feeCollected = sellERC20Position(collaterals[strategist]);
              asset.transfer(strategist, feeCollected);
        }       
               collaterals[strategist] = 0;
    }


    /// @notice THIS VAULT ACCEPT ETHER
    receive() external payable {
        // nothing to do
    }

    /// @notice SECURITY.

    /// @notice pause or unpause.
    /// @dev Security feature to use with Defender for vault monitoring

    function pause() public whenNotPaused {
        require(
            hasRole(STRATEGIST_ROLE, msg.sender),
            "iCOMP : Unauthorized to pause"
        );
        _pause();
    }

    function unpause() public whenPaused {
        require(
            hasRole(STRATEGIST_ROLE, msg.sender),
            "iCOMP : Unauthorized to unpause"
        );
        _unpause();
    }
}
