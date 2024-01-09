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
contract DexGameVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public totalTokenGrants;

    IERC20 private _token;

    struct TokenGrant {
        uint256 value; // 32 bytes
        uint256 claimedValue;
        uint64 cliff;
        uint64 vesting;
        uint64 start; // 3 * 8 = 24 bytes
    } // total 78 bytes = 3 sstore per operation (32 per sstore)

    mapping(address => TokenGrant) private grants;

    event NewTokenGrant(address indexed to, uint256 value);

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
    /**
     * @dev Grant tokens to a specified address
     * @param _to address The address which the tokens will be granted to.
     * @param _value uint256 The amount of tokens to be granted.
     * @param _start uint64 Time of the beginning of the grant.
     * @param _cliff uint64 Time of the cliff period.
     * @param _vesting uint64 The vesting period.
     */
    function grantVestedTokens(
        address _to,
        uint256 _value,
        uint64 _start,
        uint64 _cliff,
        uint64 _vesting
    ) public onlyOwner {
        // Check for date inconsistencies that may cause unexpected behavior
        require(_cliff >= _start && _vesting >= _cliff);
        require(!tokenGrantExist(_to), "grant already exist.!");

        grants[_to] = TokenGrant(_value, 0, _cliff, _vesting, _start);
        totalTokenGrants = totalTokenGrants.add(_value);

        emit NewTokenGrant(_to, _value);
    }

    function bulkGrantVestedToken(
        address[] calldata _tos,
        uint256[] calldata _values,
        uint64[] calldata _starts,
        uint64[] calldata _cliffs,
        uint64[] calldata _vestings
    ) public onlyOwner {
        require(
            _tos.length == _values.length &&
                _tos.length == _starts.length &&
                _tos.length == _cliffs.length &&
                _tos.length == _vestings.length
        );

        for (uint256 i = 0; i < _tos.length; i++) {
            if (tokenGrantExist(_tos[i])) continue;
            grantVestedTokens(
                _tos[i],
                _values[i],
                _starts[i],
                _cliffs[i],
                _vestings[i]
            );
        }
    }

    /**
     * @dev Revoke the grant of tokens of a specifed address.
     * @param _holder The address which will have its tokens revoked.
     */
    function revokeTokenGrant(address _holder) public onlyOwner {
        require(tokenGrantExist(_holder), "grant not exist.!");

        TokenGrant storage _grant = grants[_holder];
        uint256 _remainingValue = _grant.value.sub(_grant.claimedValue);
        // remove grant from array

        require(_token.transfer(owner(), _remainingValue), "transfer failed.!");

        totalTokenGrants = totalTokenGrants.sub(_remainingValue);
        delete grants[_holder];
    }

    /**
     * @dev Calculate the total amount of transferable tokens of a holder at a given time
     * @param holder address The address of the holder
     * @param time uint64 The specific time.
     * @return An uint256 representing a holder's total amount of transferable tokens.
     */
    function transferableTokens(address holder, uint64 time)
        public
        view
        returns (uint256)
    {
        bool grantExist = tokenGrantExist(holder);
        if (grantExist == false) return 0; // shortcut for holder without grants

        TokenGrant storage _grant = grants[holder];

        uint256 _vested = vestedTokens(_grant, time);
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

    /**
     * @dev Check the amount of grants that an address has.
     * @param _holder The holder of the grants.
     * @return grantExist A bool representing the total amount of grants.
     */
    function tokenGrantExist(address _holder)
        private
        view
        returns (bool grantExist)
    {
        return grants[_holder].value > 0;
    }

    /**
     * @dev Calculate amount of vested tokens at a specific time
     * @param tokens uint256 The amount of tokens granted
     * @param time uint64 The time to be checked
     * @param start uint64 The time representing the beginning of the grant
     * @param cliff uint64  The cliff period, the period before nothing can be paid out
     * @param vesting uint64 The vesting period
     * @return An uint256 representing the amount of vested tokens of a specific grant
     *  transferableTokens
     *   |                         _/--------   vestedTokens rect
     *   |                       _/
     *   |                     _/
     *   |                   _/
     *   |                 _/
     *   |                /
     *   |              .|
     *   |            .  |
     *   |          .    |
     *   |        .      |
     *   |      .        |
     *   |    .          |
     *   +===+===========+---------+----------> time
     *      Start       Cliff    Vesting
     */
    function calculateVestedTokens(
        uint256 tokens,
        uint256 time,
        uint256 start,
        uint256 cliff,
        uint256 vesting
    ) public pure returns (uint256) {
        // Shortcuts for before cliff and after vesting cases.
        if (time < cliff) return 0;
        if (time >= vesting) return tokens;

        // Interpolate all vested tokens.
        // As before cliff the shortcut returns 0, we can use just calculate a value
        // in the vesting rect (as shown in above's figure)

        uint256 _vestedTokens = SafeMath.div(
            SafeMath.mul(tokens, SafeMath.sub(time, start)),
            SafeMath.sub(vesting, start)
        );

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
            uint256 value,
            uint256 claimedValue,
            uint256 vested,
            uint256 claimableValue,
            uint64 start,
            uint64 cliff,
            uint64 vesting
        )
    {
        TokenGrant storage _grant = grants[_holder];

        value = _grant.value;
        claimedValue = _grant.claimedValue;
        start = _grant.start;
        cliff = _grant.cliff;
        vesting = _grant.vesting;

        vested = vestedTokens(_grant, uint64(block.timestamp));
        if(vested>0)
            claimableValue = vested.sub(claimedValue);
        else
            claimableValue = 0;
    }

    /**
     * @dev Get the amount of vested tokens at a specific time.
     * @param grant TokenGrant The grant to be checked.
     * @param time The time to be checked
     * @return An uint256 representing the amount of vested tokens of a specific grant at a specific time.
     */
    function vestedTokens(TokenGrant memory grant, uint64 time)
        private
        pure
        returns (uint256)
    {
        return
            calculateVestedTokens(
                grant.value,
                uint256(time),
                uint256(grant.start),
                uint256(grant.cliff),
                uint256(grant.vesting)
            );
    }

    function emergencyWithdrawal() public onlyOwner {
        require(
            _token.transfer(owner(), _token.balanceOf(address(this))),
            "transfer failed.!"
        );
    }
}
