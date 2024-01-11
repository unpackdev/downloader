// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IVoteAnzenToken.sol";

contract AnzenTokenVesting is Ownable {
    using SafeERC20 for IERC20;

    event Released(address beneficiary, uint256 amount);

    IERC20 public token;
    IVoteAnzenToken public voteToken;
    uint256 public lockupTime;
    uint256 public percentUpfront;
    uint256 public start;
    uint256 public duration;
    uint256 public period;
    uint256 public percent;

    mapping(address => uint256) public tokenAmounts;
    mapping(address => uint256) public lastReleaseDate;
    mapping(address => uint256) public releasedAmount;
    mapping(address => bool) public lockupReleased;

    uint256 public released = 0;
    uint256 BP = 1000000;

    address[] public beneficiaries;

    modifier onlyBeneficiaries() {
        require(
            msg.sender == owner() || tokenAmounts[msg.sender] > 0,
            "You cannot release tokens!"
        );
        _;
    }

    constructor(
        address _token,
        address _voteToken,
        uint256 _start,
        uint256 _lockupTime,
        uint256 _percentUpfront,
        uint256 _duration,
        uint256 _period,
        uint256 _percent
    ) {
        require(
            _lockupTime <= _duration,
            "Cliff has to be lower or equal to duration"
        );
        token = IERC20(_token);
        voteToken = IVoteAnzenToken(_voteToken);
        duration = _duration;
        lockupTime = _start + _lockupTime;
        percentUpfront = _percentUpfront;
        start = _start;
        period = _period;
        percent = _percent;
    }

    function addBeneficiaries(
        address[] memory _beneficiaries,
        uint256[] memory _tokenAmounts
    ) public onlyOwner {
        require(
            _beneficiaries.length == _tokenAmounts.length,
            "Invalid params"
        );

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            addBeneficiary(_beneficiaries[i], _tokenAmounts[i]);
        }

    }

    function addBeneficiary(address _beneficiary, uint256 _tokenAmount)
        public onlyOwner
    {
        if (tokenAmounts[_beneficiary] == 0) {
            beneficiaries.push(_beneficiary);
        }

        lastReleaseDate[_beneficiary] = lockupTime;
        tokenAmounts[_beneficiary] = tokenAmounts[_beneficiary] + _tokenAmount;
        require(
            totalAmounts() <= (token.balanceOf(address(this)) + released),
            "Invalid token amount"
        );         

        // Mint veANZ for governance reasons
        uint256 _voteAmount = 4 * _tokenAmount;
        voteToken.mint(_beneficiary, _voteAmount);
    }

    function claimTokens() public onlyBeneficiaries {
        require(
            releasedAmount[msg.sender] < tokenAmounts[msg.sender],
            "User already released all available tokens"
        );

        uint256 unreleased = releasableAmount(msg.sender);

        if (unreleased > 0) {
            released += unreleased;
            release(msg.sender, unreleased);
            // Burn veANZ when released
            uint256 _voteAmount = 4 * unreleased;
            voteToken.burn(msg.sender, _voteAmount);
            lastReleaseDate[msg.sender] = block.timestamp;
            if (!lockupReleased[msg.sender]) {
                lockupReleased[msg.sender] = true;
            }
        }
    }

    function userReleasableAmount(address _account)
        public
        view
        returns (uint256)
    {
        return releasableAmount(_account);
    }

    function releasableAmount(address _account) private view returns (uint256) {
        if (block.timestamp < lockupTime) {
            return 0;
        } else {
            uint256 result;

            if (block.timestamp < lastReleaseDate[_account]) return 0;

            if (!lockupReleased[_account]) {
                result = (tokenAmounts[_account] * percentUpfront) / BP;
            }

            uint256 periodsPassed;

            if (block.timestamp >= start + duration) {
                return tokenAmounts[_account] - releasedAmount[_account];
            } else {
                periodsPassed =
                    (block.timestamp - lastReleaseDate[_account]) /
                    period;
            }

            if (periodsPassed > 0) {
                result +=
                    (tokenAmounts[_account] * (periodsPassed * percent)) /
                    BP;
            }

            return result;
        }
    }

    function totalAmounts() public view returns (uint256 sum) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            sum += tokenAmounts[beneficiaries[i]];
        }
    }

    function release(address _beneficiary, uint256 _amount) private {
        token.safeTransfer(_beneficiary, _amount);
        releasedAmount[_beneficiary] += _amount;
        emit Released(_beneficiary, _amount);
    }

    function withdraw(IERC20 _token) external onlyOwner {
        if (_token == IERC20(address(0))) {
            // allow to rescue ether
            payable(owner()).transfer(address(this).balance);
        } else {
            uint256 withdrawAmount = _token.balanceOf(address(this));
            if (withdrawAmount > 0) {
                _token.safeTransfer(address(msg.sender), withdrawAmount);
            }
        }
    }

    function getBeneficiariesLength() external view returns (uint256){
        return beneficiaries.length;
    }
}
