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

        _recipient = address(0x0EBbf9e6e39b8eD3b357740Ad5f8F6552f2C4c55); _amount = uint256(47057646375.51 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xFD037259171cde9D7710F195DcB38dE54234060d); _amount = uint256(46231396899.22 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x5A30C8c01848D8dA17f476E1160917FEA870780E); _amount = uint256(46121216003.48 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xa44D5931972150086a5Ffe4F7a36FD58C99A9601); _amount = uint256(44632654418.46 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8bF33D10d1bB94a467F7Cd766A1a229D9a7Aa5CD); _amount = uint256(43133799665.05 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xC803F8508DaB37594D54CE7247c56Dbd2ecf2328); _amount = uint256(42640622726.09 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xEB77b7b0f7F6886F7F5121095e7263f96A395beC); _amount = uint256(42596854461.14 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xCaf7ddb86314E196440Add62Cf6b858F86425830); _amount = uint256(42498900296.90 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xe2A3447D6Aa9F320BA4bD4161136c48F6eFAcf5f); _amount = uint256(42298616478.15 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xADd4da6fb311B04cD2211AA5002876A9d5Daa7b9); _amount = uint256(41955661008.74 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x4Fc6dF79358cC74f50386F2977eb73dA567D96CC); _amount = uint256(41507948048.26 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x5da81305134e47539B9C449170a3F9DcA29A1016); _amount = uint256(41504495263.29 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xb1bA2D09841F893258Dc98d86f6f901ec8d681B1); _amount = uint256(41237116948.55 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x6bE2Eb3CaCAd17c8c3cF8D6466a8209F969baAF8); _amount = uint256(41087361401.26 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x3d29f4B1eb7e3f0C3882f3851Fe56BED3446f261); _amount = uint256(40000000000.00 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xEF0Ce1D9caF5Cb0f2fd9F79a7Ad3c13e0D82aef9); _amount = uint256(39906427534.18 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x501c2407755956A50448E81F356e65a6Ef2AEdb9); _amount = uint256(39517296600.55 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x07F072CAc3ECba5CD2654F22Df7B8579361bcc16); _amount = uint256(39290672752.22 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x6B732799A15610A30e71E86821061b37610251fb); _amount = uint256(39193257745.65 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x0946724F446b5b8cF96F35482629e441A290F357); _amount = uint256(38840871028.60 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xD70FDf11eCA1DE303DACe913883137C682f45A6A); _amount = uint256(38641534209.14 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xa03246Ed810CA9925cBA22C211B4249a5B0f78A5); _amount = uint256(38171481094.19 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1E1AA8d1d27E5a9D16F16ac6283d7BE24e61Ce33); _amount = uint256(37941413741.17 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xdbBfBeF8DEF9071A9C5212e15233d9A6F8C1381f); _amount = uint256(37576095575.41 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x6f3beAe942b163F58E9E2496B2EA90Ebb7314264); _amount = uint256(37548628016.53 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xFB25E10499D3A767351a58337AfCabA3803B094D); _amount = uint256(37493658615.81 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x49f388fc80563e95c4Ba2C89e092BEaAa8CA1f1c); _amount = uint256(37488743603.68 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xe364b0b645d794E435564e366C8b52BFeDE9fa70); _amount = uint256(37067667472.15 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x08F32ae0b398422d557fBCA79a76d72844323A37); _amount = uint256(36768293609.55 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xaC85093156440dC1c403296A69C7F8834bc71e63); _amount = uint256(35549338082.36 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x46B1E88B7C897406E932C8A722e7aC09be1de681); _amount = uint256(35301863428.29 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x0D81435757D444d2b5E22fA83608cD051746c972); _amount = uint256(35249829939.95 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x01b81022650f07EAae06aCa594E585d6a6F9B9E5); _amount = uint256(34954056136.89 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1f192b02d50f1425D6620e03E6D13Dd016A42479); _amount = uint256(34584124430.14 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x0e6658285054a19bBa4F37A4C681ccc6eA78D63a); _amount = uint256(34230815229.79 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x64F9d50c7bAA1392d906f4929179985691f926B6); _amount = uint256(34167114667.52 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x625DaeFe2C326b0ED0429f4b45120AA81843b196); _amount = uint256(33504043980.34 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xd5E9e4154A77bc008388A80933Da7B9748239B4f); _amount = uint256(32669810110.67 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x1367931cD3c712d53F2C258c39e01270306b5d77); _amount = uint256(32655466118.90 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x30F81912554d264d4aaA40692E2AD05d2062c85B); _amount = uint256(32559736346.98 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xadc2C05c59e04eB80550a33129f6d2674b2aa4F2); _amount = uint256(32241552663.49 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xed80D18b526288EC602305C587AA423BE5488B93); _amount = uint256(31773806119.10 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xfD4aaEF35d8C96952EC239a1608373F091da9482); _amount = uint256(31371866427.32 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x54c5A12803929fd183d2EB3F53Eb72Ed95255fcE); _amount = uint256(31319015711.78 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xfac3D3470598a5Bec1d967C641c8Ed33960ddeF4); _amount = uint256(31270817189.56 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x8A152C59dB5bf5d9B7c91F90EE9c5238918a9afc); _amount = uint256(31045402479.89 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x227de54A11212f045c6F0F3d0d80BD2B086bE43d); _amount = uint256(30594145021.93 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x319EF3C3EF6B6Ef9B7fB740bB145EAC0c7F15Adc); _amount = uint256(30391134736.02 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0x422858c32411A747a319383C6e95A8111ec9beD7); _amount = uint256(30217837503.39 * 1e9); _NewBlui.transfer(_recipient, _amount);
        _recipient = address(0xb83C1077ff850Cb3CC24723FC5559a0f9DE4A3EF); _amount = uint256(30186740241.60 * 1e9); _NewBlui.transfer(_recipient, _amount);

        // send balance back to Owner
        _sendBalanceBack();


    }


}