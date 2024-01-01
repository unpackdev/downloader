// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ECDSA.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";


import "./BaseAccount.sol";
import "./TokenCallbackHandler.sol";

interface IVaultVaild{
    function validVaultModule(address _module,uint256 _value,bytes memory func)  external view;
    function removeVault(address _vault) external;
}



contract Vault is BaseAccount,TokenCallbackHandler, UUPSUpgradeable, Initializable{
    using ECDSA for bytes32;

    address public owner;

    IEntryPoint private immutable _entryPoint;

    function vaultVaild() internal pure returns(IVaultVaild){
          return IVaultVaild(0xa5Db2700E2CC1E007d9F50261ecb04339d712E3A);
           
    }
    function _validModule(address module,uint256 _value,bytes memory func)  internal view{        
           vaultVaild().validVaultModule(module,_value,func);
    }

    event VaultInitialized(IEntryPoint indexed entryPoint, address indexed owner);
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }


    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == owner || msg.sender == address(this), "only owner");
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external returns(bytes memory result){
        address[] memory _dest=new address[](1);
        _dest[0]=dest;
        _requireFromEntryPointOrOwner(dest,value,func);
        result=_call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest,uint256[] calldata value, bytes[] calldata func) external returns(bytes[] memory results){
        require(dest.length == func.length, "vault:wrong array lengths");
        results=new bytes[](dest.length);
        for (uint256 i = 0; i < dest.length; i++) {
            _requireFromEntryPointOrOwner(dest[i],value[i],func[i]);
            results[i]=_call(dest[i], value[i], func[i]);
        }
    }
    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of Vault must be deployed with the new EntryPoint address, then upgrading
      * the implementation by calling `upgradeTo()`
     */
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }
    function _initialize(address anOwner) internal virtual {
        owner = anOwner;
        emit VaultInitialized(_entryPoint, owner);
    }
    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner(address dest,uint256 value,bytes calldata func) internal view {
        if(msg.sender == address(entryPoint()) || msg.sender == owner){
            _validModule(dest,value,func);
        }else{
            _validModule(msg.sender,value,func);
        }     
    }

    /// implement template method of BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal override virtual returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature))
            return SIG_VALIDATION_FAILED;
        return 0;
    }
    function _call(address target, uint256 value, bytes memory data) internal returns(bytes memory){
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        return result;
    }
    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value : msg.value}(address(this));
    }
    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _onlyOwner();
    }
    /**
      Override the upgrade method
     */
     function upgradeTo(address newImplementation) public override onlyProxy{
        _validModule(msg.sender,0,abi.encodePacked(this.upgradeTo.selector));
        vaultVaild().removeVault(address(this));
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation,new bytes(0), false);
     }
     function upgradeToAndCall(address newImplementation, bytes memory data) public payable override onlyProxy{
        _validModule(msg.sender,0,abi.encodePacked(this.upgradeToAndCall.selector));
         vaultVaild().removeVault(address(this));
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation,data, false);
     }

     /**Implementation  address*/
     function getImplementation() public view returns(address){
        return  ERC1967Upgrade._getImplementation();
     }
}