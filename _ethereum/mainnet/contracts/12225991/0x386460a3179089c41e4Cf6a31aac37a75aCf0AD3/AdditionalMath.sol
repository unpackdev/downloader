
pragma solidity 0.6.2;

/*
#    Copyright (C) 2017  alianse777
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#    https://github.com/alianse777/solidity-standard-library.git
*/

import "./SafeMath.sol";

library AdditionalMath {

    using SafeMath for uint256;

   /**
    * @dev Compute square root of x
    * @param x num to sqrt
    * @return sqrt(x)
    */
   function sqrt(uint x) internal pure returns (uint){
       uint n = x / 2;
       uint lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2; 
       }
       return uint(n);
   }

}