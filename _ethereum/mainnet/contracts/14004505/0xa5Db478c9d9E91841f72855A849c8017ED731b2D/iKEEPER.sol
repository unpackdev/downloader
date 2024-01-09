// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./IsKEEPER.sol";
import "./IStaking.sol";
// import "./IIndexCalculator.sol";


contract iKEEPER is ERC20, Ownable {

    using SafeMath for uint;
    address public immutable TROVE;
    address public immutable staking;
    address public indexCalculator;


    constructor(address _TROVE, address _staking, address _indexCalculator) ERC20("Invest KEEPER", "iKEEPER") {
        require(_TROVE != address(0));
        TROVE = _TROVE;
        require(_staking != address(0));
        staking = _staking;
        require(_indexCalculator != address(0));
        indexCalculator = _indexCalculator;
    }

    // function setIndexCalculator( address _indexCalculator ) external onlyOwner() {
    //     require( _indexCalculator != address(0) );
    //     indexCalculator = _indexCalculator;
    // }

    // /**
    //     @notice get iKEEPER index (9 decimals)
    //     @return uint
    //  */
    // // function getIndex() public view returns (uint) {
    // //     return IIndexCalculator(indexCalculator).netIndex();
    // // }

    // // /**
    // //     @notice wrap KEEPER
    // //     @param _amount uint
    // //     @return uint
    // //  */
    // // function wrapKEEPER( uint _amount ) external returns ( uint ) {
    // //     IERC20( KEEPER ).transferFrom( msg.sender, address(this), _amount );

    // //     uint value = TROVEToiKEEPER( _amount );
    // //     _mint( msg.sender, value );
    // //     return value;
    // // }

    // /**
    //     @notice wrap TROVE
    //     @param _amount uint
    //     @return uint
    //  */
    // function wrap( uint _amount, address _recipient ) external returns ( uint ) {
    //     IsKEEPER( TROVE ).transferFrom( msg.sender, address(this), _amount );

    //     uint value = TROVEToiKEEPER( _amount );
    //     _mint( _recipient, value );
    //     return value;
    // }


    // // /**
    // //     @notice unwrap KEEPER
    // //     @param _amount uint
    // //     @return uint
    // //  */
    // // function unwrapKEEPER( uint _amount ) external returns ( uint ) {
    // //     _burn( msg.sender, _amount );

    // //     uint value = iKEEPERToTROVE( _amount );
    // //     uint keeperBalance = IERC20(KEEPER).balanceOf( address(this) );
    // //     if (keeperBalance < value ) {
    // //         uint difference = value.sub(keeperBalance);
    // //         require(IsKEEPER(TROVE).balanceOf(address(this)) >= difference, "Contract does not have enough TROVE");
    // //         IsKEEPER(TROVE).approve(staking, difference);
    // //         IStaking(staking).unstake(difference, false);
    // //     }
    // //     IERC20( KEEPER ).transfer( msg.sender, value );
    // //     return value;
    // // }


    // /**
    //     @notice unwrap TROVE
    //     @param _amount uint
    //     @return uint
    //  */
    // function unwrap( uint _amount ) external returns ( uint ) {
    //     _burn( msg.sender, _amount );

    //     uint value = iKEEPERToTROVE( _amount );
    //     IsKEEPER( TROVE ).transfer( msg.sender, value );
    //     return value;
    // }

    // /**
    //     @notice converts iKEEPER amount to TROVE
    //     @param _amount uint
    //     @return uint
    //  */
    // function iKEEPERToTROVE( uint _amount ) public view returns ( uint ) {
    //     return _amount.mul( getIndex() ).div( 10 ** decimals() );
    // }

    // /**
    //     @notice converts TROVE amount to iKEEPER
    //     @param _amount uint
    //     @return uint
    //  */
    // function TROVEToiKEEPER( uint _amount ) public view returns ( uint ) {
    //     return _amount.mul( 10 ** decimals() ).div( getIndex() );
    // }
}