// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract KEEPERCircSupply is Ownable {
    using SafeMath for uint;

    address public KEEPER;
    address[] public nonCirculatingKEEPERAddresses;

    constructor (address _KEEPER) {
        KEEPER = _KEEPER;
    }

    function KEEPERCirculatingSupply() external view returns (uint) {
        uint _totalSupply = IERC20( KEEPER ).totalSupply();
        uint _circulatingSupply = _totalSupply.sub( getNonCirculatingKEEPER() );
        return _circulatingSupply;
    }

    function getNonCirculatingKEEPER() public view returns ( uint ) {
        uint _nonCirculatingKEEPER;
        for( uint i=0; i < nonCirculatingKEEPERAddresses.length; i = i.add( 1 ) ) {
            _nonCirculatingKEEPER = _nonCirculatingKEEPER.add( IERC20( KEEPER ).balanceOf( nonCirculatingKEEPERAddresses[i] ) );
        }
        return _nonCirculatingKEEPER;
    }

    function setNonCirculatingKEEPERAddresses( address[] calldata _nonCirculatingAddresses ) external onlyOwner() returns ( bool ) {
        nonCirculatingKEEPERAddresses = _nonCirculatingAddresses;
        return true;
    }
}