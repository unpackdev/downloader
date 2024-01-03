// SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.6.0;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract Compensation is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public compensationPerRound;
    uint256 public currentRound;
    uint256 public totalRounds;
    uint256 public totalTokensCompensation;
    uint256 public totalAvailableTokens;
    mapping(address => uint256) public tokenClaimLimit;
    mapping(address => uint256) public tokensClaimed;
    IERC20 public CompToken;

    event Refill(
        address _owner,
        uint256 compensationPerRound,
        uint256 _totalAvailable
    );
    event Claim(address _receiver, uint256 _amount);
    event NextRound(uint256 currentRound);

    constructor(
        address _token,
        uint256 _totalTokensCompensation,
        uint256 _totalRounds
    ) public {
        CompToken = IERC20(_token);
        totalRounds = _totalRounds;
        totalTokensCompensation = _totalTokensCompensation;
        compensationPerRound = _totalTokensCompensation.div(_totalRounds);
    }

    /**
     * @dev adds an address for compensation
     * @param _address address is the address to be compensated
     * @param _totalCompensationAmount uint256 is the total amount of tokens claimable by this address
     */
    function addAddressforCompensation(
        address _address,
        uint256 _totalCompensationAmount
    ) public onlyOwner {
        tokenClaimLimit[_address] = _totalCompensationAmount;
    }

    /**
     * @dev adds multiple addresses for compensation
     * @param _addresses array of address is the addresses to be compensated
     * @param _totalCompensationAmounts array of uint256 is the total amounts of tokens claimable by these addresses
     */
    function addMultipleAddressesforCompensation(
        address[] memory _addresses,
        uint256[] memory _totalCompensationAmounts
    ) public onlyOwner {
        require(
            _addresses.length == _totalCompensationAmounts.length,
            "Length of 2 arrays must be the same."
        );
        uint8 i = 0;
        for (i; i < _addresses.length; i++) {
            tokenClaimLimit[_addresses[i]] = _totalCompensationAmounts[i];
        }
    }

    /**
     * @dev enables claims of available tokens as compensation
     */
    function claimCompensation() public {
        uint256 claimAmount = tokenClaimLimit[msg.sender]
            .div(totalRounds)
            .mul(currentRound)
            .sub(tokensClaimed[msg.sender]);
        require(claimAmount > 0, "No claim available.");

        // Can't claim more tokens than are available on the contract
        if (claimAmount > totalAvailableTokens) {
            claimAmount = totalAvailableTokens;
        }

        // Update user's claimed balance and the total available balance, then transfer tokens
        tokensClaimed[msg.sender] = tokensClaimed[msg.sender].add(claimAmount);
        totalAvailableTokens = totalAvailableTokens.sub(claimAmount);
        CompToken.transfer(msg.sender, claimAmount);
        emit Claim(msg.sender, claimAmount);
    }

    /**
     * @dev unlocks another round of compensation tokens to be claimed
     */
    function refill() internal {
        require(
            CompToken.transferFrom(
                msg.sender,
                address(this),
                compensationPerRound
            ),
            "Transfer failed. Have the tokens been approved to the contract?"
        );
        totalAvailableTokens = totalAvailableTokens.add(compensationPerRound);
        emit Refill(msg.sender, compensationPerRound, totalAvailableTokens);
    }

    // Rescue any missent tokens to the contract
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    // Emergency reset
    function eject() public onlyOwner {
        uint256 currBalance = CompToken.balanceOf(address(this));
        CompToken.safeTransfer(msg.sender, currBalance);
    }

    /**
     * @dev unlocks another round of tokens for compensation
     */
    function startnextround() public onlyOwner {
        require(
            currentRound <= totalRounds,
            "Compensation completed, all rounds have been completed."
        );
        if (currentRound < totalRounds) {
            currentRound++;
        }
        refill();
        emit NextRound(currentRound);
    }
}
