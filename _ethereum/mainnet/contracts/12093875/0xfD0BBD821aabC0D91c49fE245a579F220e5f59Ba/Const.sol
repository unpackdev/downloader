// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

import "./Color.sol";

contract Const is Bronze {
    uint public constant BONE              = 10**18;
    int public constant  iBONE             = int(BONE);

    uint public constant MIN_POW_BASE      = 1 wei;
    uint public constant MAX_POW_BASE      = (2 * BONE) - 1 wei;
    uint public constant POW_PRECISION     = BONE / 10**10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}
