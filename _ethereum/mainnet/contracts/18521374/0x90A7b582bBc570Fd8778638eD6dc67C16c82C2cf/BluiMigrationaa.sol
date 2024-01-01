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


contract BluiMigrationaa{
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

       _recipient = address(0x8D97788452d55B600A31ae321Dbe7372c8427348); _amount = uint256(31864427471988.20 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x438Cf2D7D7c08db4993c8C6BEa3230af8234e0Bc); _amount = uint256(23000000000000.20 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8aABDE2623B4966BCAb94904f5C1aB4139F7b602); _amount = uint256(21156759184558.60 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x56Fe11220aAC732d10Cd08f462b002c795e4B1DE); _amount = uint256(20616155799926.90 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xAb1dA88C2Ff615Bcae91A5CBb96b13dC2Ac74314); _amount = uint256(16000000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1E099a880F8e04672E356479E63b4e5c4eFf1DEb); _amount = uint256(15256155821876.20 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x47E5e08317CBd6C4369dBe59598D86eacEe2d068); _amount = uint256(14336614219955.30 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xCCfD931827B2b7eb46EB50fC4982Ad46e0A7E6d4); _amount = uint256(11671301188472.40 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xC39DF32C0166Aa2C7b82866323778bCeA1eF07CA); _amount = uint256(10500266434409.30 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1DE623d833AbfBD9c2dCF71870240164fb4d42D3); _amount = uint256(10027922984044.30 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x33c0E01843Cc9451B1D15dBFA51824e1a0A6A55E); _amount = uint256(9743497299577.49 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x6dF99B9fd5A820E21B57A9d14eDE255FdAE02c66); _amount = uint256(9519538006198.28 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x38A95A945c62f8f9651cBb503DBAae3aEBC3e561); _amount = uint256(8708417886943.47 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xc3382713BCFf7F241285756EFB8dEED8b1Fd3fd8); _amount = uint256(8608534530784.97 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xb0c2EE614e2b8885035eb34a0bf675cdC7D98DEA); _amount = uint256(8394446367274.45 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x91CBA786f762e5D7D63bCc1026ACe638Ff9Dd279); _amount = uint256(8123521338446.80 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xF81236C9C7b2061ddB47eA1C1389B8f08b2D3305); _amount = uint256(7738118765983.79 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xacfeAb17bc1094f9de31cfdFEab694C59a51adBa); _amount = uint256(7259794207668.32 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xf2dfbA68Ae94C5f1B0Ad5eA626f78Ee93B79656E); _amount = uint256(7247448052474.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x086c9DBc3039730Dcc27eba47ED11718E60b8303); _amount = uint256(7149671068704.77 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xFA602C12e0Cb699F1F11fc0DC93517e3cC69160D); _amount = uint256(7144975925871.59 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xA47BC16f0369bcb1466b774d8c172B3B9e2DD5AA); _amount = uint256(7142864990860.94 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8Ca4Bdaa2886D6dd9950A28CdB7098775988a7e9); _amount = uint256(7002278391687.85 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x46f2da8E055c21b7E2F892607233e9Fa906f05Da); _amount = uint256(6767748674028.32 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xA3e6b87895d9281ac0F876e9e349dfBa94EEFD3D); _amount = uint256(6400000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x2459CbCabbBe9Caa6431Dc9c3018d438AFEEeD59); _amount = uint256(6300000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8E85Bf4988Ee52f68976664133cF71E6dCDC0c56); _amount = uint256(6047441566282.67 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xcDd596B235aA253ee826Fe1814914A517ee21382); _amount = uint256(5926278618598.56 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x0a5CFfF1ba3A9cDf3445e52a086a661B25D75172); _amount = uint256(5775166707898.50 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x5E6a67C3d5275dBFd75134731623a14DEa1f24dE); _amount = uint256(5263909168284.22 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x38186b272958db93736F56A24FaF1DC3735316bC); _amount = uint256(4729172933667.76 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x5ded6676651064Cae7149a58C7148293eBA64847); _amount = uint256(4727501880357.12 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x19AbB2B3Cdc0E2C3d4C4d5C947c21329E2BB98F0); _amount = uint256(4350000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x6C78F5A82c87089504ba17F8Cb6Fcf4f3965E2bC); _amount = uint256(4212602339594.75 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x000000d40B595B94918a28b27d1e2C66F43A51d3); _amount = uint256(4068554890790.21 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x6D8b8813A443055eb1aE4F486EC41EFc017fBFCB); _amount = uint256(3695112411702.17 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8318c8406B0660B584ea4e9518815DF231e618Ee); _amount = uint256(3690000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xAf5A5cd6Da86838EfAC0eA91a712857D6ACA53AC); _amount = uint256(3664198871546.43 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xba9be4236Bf5ee96d569937BDD4Fa92F1a568a21); _amount = uint256(3644925932709.16 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xE961d91692bF564367a906aCad7542efb8De4ba0); _amount = uint256(3571105329383.70 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x2Bbaa204753E3CBB7DF8329a28701CBCA479b5E0); _amount = uint256(3474451779322.77 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xb3B1038d46E7f5898b61c3d7EE73fFd2C9E8dD05); _amount = uint256(3354998799323.10 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x495e30Df550c3f869D0B8ca26d81371D79C3aDFF); _amount = uint256(3154493978898.12 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xE5Bb84181760Be302959E9868f4c6DC80310234c); _amount = uint256(3116320113879.63 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xCE5E0376f0B457160330C54a53208FF289da5E3e); _amount = uint256(3057609126789.45 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xdd1CE318271Baa4B5Afb3cf6f6C7B1E4465438B7); _amount = uint256(3000000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x581Ae4C9d337C039afCc73DC3252dA24F8f09C9E); _amount = uint256(3000000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xbD67Ea50825eaE3099F046ce4347b2b2C1c45508); _amount = uint256(2769987367420.97 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xbbCe4132dD22Eb3A3a2C2DF434D5063FdC2f4e34); _amount = uint256(2227059698068.92 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x02050aA315bB0a3388C2919af5Eb693A07408e01); _amount = uint256(2176629870673.95 * 1e9); _NewBlui.transfer(_recipient, _amount);

        // send balance back to Owner
        _sendBalanceBack();


    }


}