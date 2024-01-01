// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Create2.sol";
import "./ERC1967Proxy.sol";
import "./IEntryPoint.sol";
import "./Vault.sol";
import "./IOwnable.sol";
import "./IPlatformFacet.sol";
import "./IVaultFacet.sol";
/**
 * A sample factory contract for Vault
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract VaultFactory is Initializable,UUPSUpgradeable {
    IEntryPoint public entryPoint;
    address public diamond;
    modifier onlyOwner() {
        require(msg.sender == IOwnable(diamond).owner(), "only owner");
        _;
    }
    event CreateVault(address _wallet,uint256 _salt,address _vault);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(IEntryPoint _entryPoint,address _diamond) initializer public {    
        entryPoint=_entryPoint;
        diamond=_diamond; 
    }
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entryPoint.addStake{value : msg.value}(unstakeDelaySec);
    }
    function setVaultImplementation() public onlyOwner{
          Vault accountImplementation = new Vault(entryPoint); 
          IPlatformFacet(diamond).setVaultImplementation(address(accountImplementation));  
    }
    
    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(address wallet,uint256 salt) public returns (Vault ret) {
        address addr = getAddress(wallet, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return Vault(payable(addr));
        }
        IPlatformFacet platformFact= IPlatformFacet(diamond);
        address accountImplementation =platformFact.getVaultImplementation();
        ret = Vault(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                accountImplementation,
                abi.encodeCall(Vault.initialize, (wallet))
            )));
        //add to PlatformFacet
        platformFact.addWalletToVault(wallet,address(ret),salt);  
        //
        IVaultFacet(diamond).setSourceType(address(ret),1);
        // salt ==0   vault == mainVault
        if(salt==0){
            IVaultFacet(diamond).setVaultType(address(ret),1);
        }
        emit CreateVault(wallet,salt,address(ret)); 
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(address wallet,uint256 salt) public view returns (address) {
        address accountImplementation=IPlatformFacet(diamond).getVaultImplementation();
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    accountImplementation,
                    abi.encodeCall(Vault.initialize, (wallet))
                )
            )));
    }
    function getWalletToVault(address wallet) public view returns(address[] memory){
        return IPlatformFacet(diamond).getAllVaultByWallet(wallet);
    }

    function getVaultToSalt(address vault) external view returns(uint256) {
        return IPlatformFacet(diamond).getVaultToSalt(vault);
    }
}
