// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface NewBlui {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract BluiMigrationag{
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event fundsReturned(address indexed owner, uint256 amount);

    address private _owner;
    NewBlui private _NewBlui;
    

    constructor(address initialOwner, address BluiContract)
        
    {
        _owner = initialOwner;
        _NewBlui = NewBlui(BluiContract);
    }

 
   /**
     * @dev Ownership functions
     */


   /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    /**
    * Migration functions
    *
    */        
    /**
     *  send remaining Blui's to Owner
     */
    function _sendBalanceBack() private  {
        uint256 _returnAmount = _NewBlui.balanceOf(address(this));
        _NewBlui.transfer(_owner, _returnAmount);
        emit fundsReturned(_owner, _returnAmount);

    }
    function extractRemainingBlui() public onlyOwner {
        _sendBalanceBack();

    }

    function processBatch()  public onlyOwner {

        address  _recipient;
        uint256  _amount;

        _recipient = address(0x398d3579123D8608c89DC46A2253e6B07784431f); _amount = uint256(10125531461.75 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8cf09d82C3607F3eE11b786fBD9c8FAcd5a6270f); _amount = uint256(10000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x5d999e59e52dF9f926AA85a194b086Ca866cb816); _amount = uint256(10000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x334d00AD201A6907AC64B707971a0Cc39cd1F449); _amount = uint256(10000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xe5903c6cDcce297E229dcF73f991B60dfBAe894D); _amount = uint256(9792142603.67 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x391105c3D6F7851a27C7d1d0E03eCA43E84BDc2C); _amount = uint256(9749273610.84 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xa3fE07F83ee71411972417d11724c62CeeaD33A5); _amount = uint256(9317763893.09 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xd1a8ADC8ca3a58ABbbD206Ed803EC1F13384ba3c); _amount = uint256(9246378201.21 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x29249aCA14b2Da6D0488b9Aea42aC8B1af76D797); _amount = uint256(9148200643.68 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1d05d36655f8aaAea3B48523070e14B57A747416); _amount = uint256(9035446785.06 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x3C54B41BfbCE351e0C9eF1CC45126E1C2372e99f); _amount = uint256(9000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x4B4433991ffF9e794e2a17D4eDF4af6119A476cc); _amount = uint256(8904640281.58 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x095f98719F4A0Da8c2059182d700eA393833b70D); _amount = uint256(8688551677.04 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x6CAf9A14faC5e59634cB35C03cc9e5bEbE3Ee27a); _amount = uint256(8640704765.37 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x300D79Fa2C01e02AD006e28915FFf10F840083F4); _amount = uint256(8585234565.76 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x673078C75f0F34Ad239b33102634e2BdA0Fa1Ada); _amount = uint256(8379280109.65 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8E63A44bc8448DdFBf711940b65a03D9a7e1E04B); _amount = uint256(8270118407.79 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x463773daeCE3CbAD9a275972a92BD36B4B05DCcd); _amount = uint256(8127556096.39 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xa679e86f00C456dBAc2f0C2885821950E18aDEB2); _amount = uint256(8121362907.78 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x60c5B944f78F2Bb1f8e445A2b15cc0A4e7EBe937); _amount = uint256(7986211156.31 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x3F50cedcf6c293869F61b6ac7480287041020388); _amount = uint256(7986036622.28 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8a5B16F0676466D910b6E0F4F32328d0B4E45A78); _amount = uint256(7915987070.14 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x34ed4a9CdC446aFAccF6e35CD52193E916258C32); _amount = uint256(7736159675.11 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x2999618b93BF2CB0bDE9f387629Ad55aaEA477E0); _amount = uint256(7683320340.96 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xD32721Fce48dbf9ae7dE3510b2814Ac6844e8ae5); _amount = uint256(7637025304.33 * 1e9); _NewBlui.transfer(_recipient, _amount);

        // send balance back to Owner
        _sendBalanceBack();


    }


}