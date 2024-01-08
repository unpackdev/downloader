// contracts/IDXStrategist.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./CErc20.sol";
import "./CEther.sol";
import "./Comptroller.sol";
import "./CompoundVault.sol";

import "./CVault.sol";

/**

IDX Digital Labs Strategist Smart Contract

Author: Ian Decentralize

  - CREATE VAULT
  - UPDATE VAULT FEES
  - BORROW FROM A VAULT 
  - REPAY ON BEHALF OF A VAULT
  - LIQUIDATE A POSITION
  
 Other Strategies in the process of...

*/

contract IDXStrategist is
    Initializable

{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CVaults for CVaults.CompVault;

    CErc20 cCOMP;
    IERC20Upgradeable COMP;

    address payable STRATEGIST;
    uint256 public vaultCount;

    mapping(address => uint256) public vaultsIds;
    mapping(uint256 => CVaults.CompVault) public vaults;

    CVaults.CompVault vaultRegistry;
 
    mapping(address => address) public cTokenAddr;
    mapping(address => mapping(address => uint256)) avgIdx;

    event VaultCreated(uint256 id, uint256 tier, address logic, address asset);

    bytes32 STRATEGIST_ROLE;
    bytes32 VAULT_ROLE;
    bytes32 CONTROLLER_ROLE;

     modifier onlyStrategist() {
        require(msg.sender == STRATEGIST);
        _;
    }

    function initialize(address startegist) public initializer {
        STRATEGIST = payable(startegist);
        COMP = IERC20Upgradeable(0x61460874a7196d6a22D1eE4922473664b3E95270);
        cCOMP = CErc20(0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4);
    }

    /// @notice Create and Deploy a new vault
    /// @dev Will add a contract vault to the vaults
    /// @param cToken collaterall token
    /// @param asset native asset
    /// @param tier tier access
    /// @param fees vault fees
    /// @param symbol the symbol of the vault (token)

    function createVault(
        address deployer,
        CErc20 cToken,
        IERC20Upgradeable asset,
        IERC20Upgradeable protocolAsset,
        uint256 tier,
        uint256 fees,
        uint256 feeBase,
        string memory symbol
    ) public 
      onlyStrategist
     {
      
        CVaults.CompVault storage vault = vaults[vaultCount];
        vault.id = vaultCount;
        vault.tier = tier;
        vault.lastClaimBlock = block.number;
        vault.accumulatedCompPerShare = 0;
        vault.fees = fees;
        vault.protocolAsset = IERC20Upgradeable(protocolAsset);
        vault.collateral = CErc20(cToken);
        vault.asset = IERC20Upgradeable(asset);
        vault.logic = new CompoundVault();
        vault.logic.initializeIt(
            address(this),
            deployer,
            address(cToken),
            address(asset),
            fees,
            feeBase,
            symbol
        );

        vaultsIds[address(vault.logic)] = vaultCount;
        vaultCount += 1;
        emit VaultCreated(vault.id, vault.tier, address(vault.logic), address(asset));
    }

    /// @notice Enter and exit Market con Com Vault
    /// @dev Borrowing from a vault increase it's yield in Comp
    function enterVaultMarket(address _vault, address cAsset) public onlyStrategist {
        CVaults.CompVault memory vault = vaults[vaultsIds[_vault]];
        vault.logic._enterCompMarket(cAsset);
    }

    function exitCompMarket(address _vault, address cAsset) public onlyStrategist {
        CVaults.CompVault memory vault = vaults[vaultsIds[_vault]];
        vault.logic._exitCompMarket(cAsset);
    }

    /// @notice Get Vault Return
    /// @dev Borrowing from a vault increase it's yield in Comp
    /// @param fromVault vault we borrow from
    /// @param asset asset to repay / must not be farming asset
    /// @param amount to repay
    /// @dev the funds must be in this contract

    function _VaultSwap(
        address fromVault,
        address asset,
        address cToken,
        uint256 amount
    ) public onlyStrategist returns(bool){
        CVaults.CompVault memory vaultOut = vaults[vaultsIds[fromVault]];
        uint256 returnedAmount = vaultOut.logic._borrowComp(amount, cToken, asset);
        require(returnedAmount == amount, 'iStrategist : Borrow failed!');
        return true;
    }


    /// @notice REPAY IN A VAULT
    /// @dev The funds must be in the contract
    /// @param vaultAddress address of the vault
    /// @param cAsset asset to repay
    /// @param asset asset to repay
    /// @param amount to repay
    /// @dev the funds must be in this contract

    function _RepayCompVaultValue(
        address vaultAddress,
        address cAsset,
        address asset,
        uint256 amount
    ) public onlyStrategist {
        CVaults.CompVault memory vault = vaults[vaultsIds[vaultAddress]];
        IERC20Upgradeable _asset = IERC20Upgradeable(asset);
        CErc20 _cAsset = CErc20(cAsset);
        _asset.safeApprove(address(_cAsset), amount);
        require(
            _cAsset.repayBorrowBehalf(address(vault.logic), amount) == 0,
            "iStrategist : Repay failed!"
        );
    }

    /// @notice Liquidate an account on Compound.
    /// @dev fees are already deducted on the share value based on earning
    /// @param _borrower address of the vault
    /// @param _amount to be repayed
    /// @param _collateral the asset to be received
    /// @return value the amount transfered to this contract

     function liquidateBorrow(address _borrower, uint _amount, address _collateral, address _repayed) 
        public
        onlyStrategist
        returns (uint256)
    {   
        CErc20 repayedAsset = CErc20(_repayed);
        repayedAsset.approve(address(repayedAsset), _amount); 
        return  repayedAsset.liquidateBorrow(_borrower, _amount, _collateral);
        
    }

    /// @notice Redeem and Withdraw fees.
    /// @dev fees are already deducted on the share value based on earning
    /// @param _vaultAddress address of the vault
 
    function collectFees(address _vaultAddress)
        public
        onlyStrategist 
    {
        CVaults.CompVault memory vault = vaults[vaultsIds[_vaultAddress]];
        vault.logic.getFees();
        
    }

    function withdrawERC20Fees(address _asset) public onlyStrategist {
          
           IERC20Upgradeable asset = IERC20Upgradeable(_asset);
           asset.transfer(msg.sender,asset.balanceOf(address(this)));
    }

    function withdrawETHFees() public onlyStrategist {
          payable(msg.sender).transfer(address(this).balance);
    }

    // function changeStrategist(address newStrategist) public onlyStrategist {
    //      STRATEGIST = payable(newStrategist);
    // }


    /// @notice THIS VAULT ACCEPT ETHER
    receive() external payable {
        // nothing to do
    }
}
