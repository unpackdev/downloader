pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Vested token
 * @dev Tokens that can be vested for a group of addresses.
 */
contract DexGameTeamVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public totalTokenGrants;

    IERC20 private _token;

    struct TokenRelease{
        uint64 time;
        uint percent;
    }

    struct TokenGrant {
        TokenRelease[] releaseSchedule;
        uint256 value; // 32 bytes
        uint256 claimedValue;
    } // total 78 bytes = 3 sstore per operation (32 per sstore)

    mapping(address => TokenGrant) private grants;
    constructor(IERC20 pToken) {
        _token = pToken;
    }

    function claim() external returns (bool success) {
        address _to = _msgSender();

        uint256 _balance = spendableBalanceOf(_to);

        require(_balance > 0, "no claimable token available.");
        require(_token.balanceOf(address(this)) >= _balance);

        require(_token.transfer(_to, _balance));
        grants[_to].claimedValue = grants[_to].claimedValue.add(_balance);
        return true;
    }

    function spendableBalanceOf(address _holder) public view returns (uint256) {
        return transferableTokens(_holder, uint64(block.timestamp));

    }
    function grantVestedTokens(
        address _to,
        uint256 _value,
        TokenRelease[] calldata _releaseSchedule
    ) public onlyOwner {
        require(_releaseSchedule.length > 0 && _value > 0, "schedule or value ?");
        require(!tokenGrantExist(_to), "grant already exist.!");

        grants[_to].value = _value;
        for (uint i = 0; i < _releaseSchedule.length; i++) {
            grants[_to].releaseSchedule.push(_releaseSchedule[i]);        
        }
        totalTokenGrants = totalTokenGrants.add(_value);

        // emit NewTokenGrant(_to, _value);
    }
    function transferableTokens(address holder, uint64 time)
        public
        view
        returns (uint256)
    {
        bool grantExist = tokenGrantExist(holder);
        if (grantExist == false) return 0; // shortcut for holder without grants

        TokenGrant memory _grant = grants[holder];

        uint256 _vested = calculateVestedTokens(_grant.value, time,_grant.releaseSchedule);
        uint256 _claimedValue = _grant.claimedValue;
        // Balance - totalNonVested is the amount of tokens a holder can transfer at any given time

        (bool _flag, uint256 _vestedTransferable) = _vested.trySub(
            _claimedValue
        );
        if (!_flag) return 0;
        // Return the minimum of how many vested can transfer and other value
        // in case there are other limiting transferability factors (default is balanceOf)
        return _vestedTransferable;
    }
    function tokenGrantExist(address _holder)
        private
        view
        returns (bool grantExist)
    {
        return grants[_holder].value > 0;
    }
    function calculateVestedTokens(
        uint256 _tokens,
        uint64 _time,
        TokenRelease[] memory _releaseSchedule
    ) public pure returns (uint256) {
        uint256 _vestedTokens=0;
        for (uint i = 0; i < _releaseSchedule.length; i++) {
            if( _time > _releaseSchedule[i].time){
                _vestedTokens = _vestedTokens.add(_tokens.mul(_releaseSchedule[i].percent).div(1000));
            }
        }
        return _vestedTokens;
    }

    /**
     * @dev Get all information about a specific grant.
     * @param _holder The address which will have its tokens revoked.
     */
    function tokenGrant(address _holder)
        public
        view
        returns (
            uint256 claimedValue,
            uint256 vested,
            uint amount,
            uint256 claimableValue,
            TokenRelease[] memory releaseSchedule
        )
    {
        TokenGrant memory _grant = grants[_holder];
        claimedValue = _grant.claimedValue;
        releaseSchedule = _grant.releaseSchedule;
        amount = _grant.value;
        vested = calculateVestedTokens(_grant.value, uint64(block.timestamp),_grant.releaseSchedule);

        if(vested>0)
            claimableValue = vested.sub(claimedValue);
        else
            claimableValue = 0;
    }
}
