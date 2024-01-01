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


contract BluiMigrationae{
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

        _recipient = address(0xCE3858e5E077801F6CEf402a93CA2BE96329512E); _amount = uint256(110000000000.03 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x025FA98217AcE894e2388EE8fDb13Ddf60e1367E); _amount = uint256(109449819113.33 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x667a24bC1B3b2B654aCC9be716faee6eA1756B53); _amount = uint256(109047684734.39 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xf11d74935a9a15517a084805784b89FE7820C466); _amount = uint256(108633646672.74 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x0cc1C1e68E737059baAe3F63fF1d12caF34F32f5); _amount = uint256(105000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x54bC2F1aC0080c0D5C2a79a1E95d48b7B7B1fCee); _amount = uint256(104755449056.69 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8818C2E04A1Fab81cE6432f98a4674971280753F); _amount = uint256(101750626304.64 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xdE76B8FBE80fC8a0920715969f2f37D30c9C8327); _amount = uint256(101570797000.48 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xeC0502Bd41783460EFA9220a1732bbFf2e494d56); _amount = uint256(101435817078.84 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xf739B48e89ED4B7c2398CC4E2dCD54479b7bea50); _amount = uint256(101203807693.04 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xD836F57e5ebE5827f04dB05db298226cC7E0704F); _amount = uint256(100889629822.65 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xF8DF9B15d37D97bCdDBb93615637f649Bf46e3A3); _amount = uint256(100850249585.02 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xFA86EaaD47e8DfA6C3d3E5cdCba746585C29bf6C); _amount = uint256(100000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x4E6755AcE70972a78B1c173Ac31C0CeBaC0Eabb7); _amount = uint256(100000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1019618f1C708807857FDd50dAc115562a4B8741); _amount = uint256(100000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x564B42BAFB574853d827A3208ef9D04E64f527DE); _amount = uint256(99869786306.81 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xb6848eb7060f191F6239aa4a56745d83dDD9e298); _amount = uint256(99803417024.69 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x51A28219c879a9A93AA37698148927947aDb9908); _amount = uint256(99650977734.47 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1F63989630C6bd4E2d954350a6E01aec73455d6F); _amount = uint256(99000000000.02 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x2A548026C50604Ff1B3e047eaa85A1842051902a); _amount = uint256(98890891117.49 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x0CA1Ad3B9804839408D205a28747A4E8268Ad483); _amount = uint256(97801513441.57 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x16E535DCd65A43D66717a88FB5E78f5919D6977E); _amount = uint256(97493467565.63 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xE881572693F2C1618EDd28DaCaF6C4e58EbDB889); _amount = uint256(96053963365.49 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xf674770729fd2643CBAfa302f34B09399b97F1aC); _amount = uint256(95112792428.17 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x7b49F722ff9b35F920ef482474De0c856a3A5737); _amount = uint256(94838819656.52 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xBADd30e24b469C5bE8C80CC2f556bdf430C4981A); _amount = uint256(93025728280.31 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xD8e6028e44eB1ab21e730BD283e3F9cDD7C3319A); _amount = uint256(93016981076.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x203C29d0a94deAaBfE373d838f7680d694FC94AE); _amount = uint256(91816599849.72 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x19DDB51Ea781f6d7aa8ADd37101c11e467D52893); _amount = uint256(90355401444.42 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xe7116D18C23DbeA0E6bA67b87Bdb22c003a348D3); _amount = uint256(90245040731.27 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x67e767B341fC229a5A3bE8ac180b6Aff70Dc5b24); _amount = uint256(88879359041.68 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x4f82e73EDb06d29Ff62C91EC8f5Ff06571bdeb29); _amount = uint256(88779480194.35 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x16302060c76037338A972c90E5d5FA7a90596d6f); _amount = uint256(87664074501.45 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x4Ad813f25C06065B95a3Ffc64DaE509fB7d85D52); _amount = uint256(86868979888.90 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x5a130DC276c4791007033eE796B5e4ed6a915699); _amount = uint256(86232275055.51 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xc6e009a7901AC60bf749CDEd7C45DDb02d4D57Ed); _amount = uint256(86049335913.85 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1e3127E41AbaC445C8E07e683797FEd0c5457448); _amount = uint256(85545003861.86 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xF447b64eA23AbF5405Fb80175249bC03D8469b89); _amount = uint256(84771405443.07 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xc804B41cC980b0CdF6f7F996A9789C599A7F034f); _amount = uint256(83817108897.11 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xe4639D7D422e4A9a060a7f9963C12A107Febb81B); _amount = uint256(83476385204.87 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x72D437b1AAEa3A548CE2Bc390C99C27a00b4BEA7); _amount = uint256(82741543168.31 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x96D3F98E431175D35DB5F3586D0Ba1450C6d28DD); _amount = uint256(82662333053.35 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x09441166Df9d1cA3a7B8fb324a201d5A14E344BF); _amount = uint256(82114254960.80 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x019C61A6F661881802841B7c1d7DEf9F5403f888); _amount = uint256(81925204714.18 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x2B1caFca189e25c1D9EB59DfCf6778C55AbB7621); _amount = uint256(81863404643.07 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xAF9F9Ce98570aCa3B737cEaC0Da49E24beD7DE35); _amount = uint256(81580543631.72 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x29ac713CF94BB8AC65E0C0901Ff416A1d92d7be1); _amount = uint256(80887359023.47 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x9B20CA357ED1Fdb68010DA587Db93AFB2A3e5F11); _amount = uint256(80264240275.70 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x51A2cb7Ca48B129537102B78539B9ddB7a7755FF); _amount = uint256(80224486591.68 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x13307925948d1D717369d76E07EaF7D4e38A3295); _amount = uint256(80000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);

        // send balance back to Owner
        _sendBalanceBack();


    }


}