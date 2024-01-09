//SPDX-License-Identifier: MIT

/*

 ____                     __               __          ______    __              ______           __                
/\  _`\                  /\ \__         __/\ \        /\__  _\__/\ \      __    /\__  _\       __/\ \               
\ \ \L\ \     __     __  \ \ ,_\   ___ /\_\ \ \/'\    \/_/\ \/\_\ \ \/'\ /\_\   \/_/\ \/ _ __ /\_\ \ \____     __   
 \ \  _ <'  /'__`\ /'__`\ \ \ \/ /' _ `\/\ \ \ , <       \ \ \/\ \ \ , < \/\ \     \ \ \/\`'__\/\ \ \ '__`\  /'__`\ 
  \ \ \L\ \/\  __//\ \L\.\_\ \ \_/\ \/\ \ \ \ \ \\`\      \ \ \ \ \ \ \\`\\ \ \     \ \ \ \ \/ \ \ \ \ \L\ \/\  __/ 
   \ \____/\ \____\ \__/.\_\\ \__\ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\  \ \_\ \_,__/\ \____\
    \/___/  \/____/\/__/\/_/ \/__/\/_/\/_/\/_/\/_/\/_/      \/_/\/_/\/_/\/_/\/_/      \/_/\/_/   \/_/\/___/  \/____/
                                                                                                                                                                                                                                        
*/

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./IERC721Enumerable.sol";

abstract contract HC {
    function mint(address to, uint256 amount) public virtual;
}

contract HulaDistributor is Pausable, AccessControlEnumerable {

    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");

    uint public constant START_DATE = 1635724800; // Mon, 1 Nov 2021 0:00:00 GMT
    uint public constant END_DATE = 1951257600; // Mon, 1 Nov 2031 0:00:00 GMT

    uint public UNIKI_DAILY_YIELD = 30 ether;
    uint public SPECIAL_DAILY_YIELD = 6 ether;
    uint public REGULAR_DAILY_YIELD = 5 ether;

    mapping(uint => bool) private unikis;
    mapping(uint => bool) private specials;
    mapping(uint => uint) public outstandingBalance;
    mapping(uint => uint) public claimDate;

    IERC721Enumerable bttContract;
    HC hulaContract;

    constructor(address _bttAddress, address _hulaAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REWARDER_ROLE, _msgSender());

        bttContract = IERC721Enumerable(_bttAddress);
        hulaContract = HC(_hulaAddress);

        uint[10] memory unikiIds = [ uint(1353), 1960, 1996, 2092, 2147, 3022, 3033, 3577, 4010, 4632 ];
        for (uint i=0; i<unikiIds.length; i++)
            unikis[unikiIds[i]] = true;
        

        uint[12] memory specialIds = [ uint(14), 694, 805, 2278, 2382, 2739, 2748, 2980, 4220, 4337, 4613, 4842 ];
        for (uint i=0; i<specialIds.length; i++)
            specials[specialIds[i]] = true;
    }

    function isTokenOwner(address _address, uint _tokenid) private view returns (bool) {
        bool isOwner = false;
        uint balance = bttContract.balanceOf(_address);

        for (uint i=0; i<balance; i++) {
            uint tokenid = bttContract.tokenOfOwnerByIndex(_address, i);

            if (tokenid == _tokenid) {
                isOwner = true;
                break;
            }
        }

        return isOwner;
    }

    function availableHula(uint _tokenid) public view returns (uint) {
        uint startDate = (claimDate[_tokenid] > 0) ? claimDate[_tokenid] : START_DATE;
        uint numOfDays = (block.timestamp - startDate) / (1 days);
        uint available;

        if (unikis[_tokenid])
            available = numOfDays * UNIKI_DAILY_YIELD;
        else if (specials[_tokenid])
            available = numOfDays * SPECIAL_DAILY_YIELD;
        else
            available = numOfDays * REGULAR_DAILY_YIELD;

        available += outstandingBalance[_tokenid];

        return available;
    }

    function claimHula(uint _tokenid, uint _amount) public whenNotPaused {
        address sender = _msgSender();
        require(isTokenOwner(sender, _tokenid), 'HulaDist: Must own tiki to claim hula');
        
        uint available = availableHula(_tokenid);
        require(_amount <= available, 'HulaDist: Cannot claim more than available balance');

        claimDate[_tokenid] = block.timestamp;
        outstandingBalance[_tokenid] = available - _amount;
        hulaContract.mint(sender, _amount);
    }

    function addBalance(uint _tokenid, uint _amount) public {
        require(hasRole(REWARDER_ROLE, _msgSender()), "HulaDist: Must have rewarder role");
        outstandingBalance[_tokenid] += _amount;
    }

    function removeBalance(uint _tokenid, uint _amount) public {
        require(hasRole(REWARDER_ROLE, _msgSender()), "HulaDist: Must have rewarder role");
        require(_amount <= outstandingBalance[_tokenid], "HulaDist: Cannot remove more than available");
        outstandingBalance[_tokenid] -= _amount;
    }

    function mintHula(address _address, uint _amount) public {
        require(hasRole(REWARDER_ROLE, _msgSender()), "HulaDist: Must have rewarder role");
        hulaContract.mint(_address, _amount);
    }

    function setDailyYield(uint _regular, uint _special, uint _uniki) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HulaDist: Must have admin role");
        REGULAR_DAILY_YIELD = _regular;
        SPECIAL_DAILY_YIELD = _special;
        UNIKI_DAILY_YIELD = _uniki;
    }

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HulaDist: Must have admin role");
        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HulaDist: Must have admin role");
        _unpause();
    }

}