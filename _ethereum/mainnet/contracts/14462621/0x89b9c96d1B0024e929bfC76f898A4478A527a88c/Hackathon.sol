//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IWETH.sol";

/**
    @title ETH Dubai -- Hackathon contract
    @notice Simple Permissionless Hackathon contract where sponsors
            can deposit any token and rewards them to any address on withdraw
**/
contract Hackathon is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /***********
     * Varibles
     ***********/

    // an address of the owner
    address public immutable owner;

    // an address of wrapped native
    address public immutable native;

    // a timestamp when owner can claim the rewards on behalf of sponsors
    uint256 public immutable rewardExpiresAfter;

    // bounty reward details
    struct BountyReward {
        string title;
        address rewardToken;
        uint256 rewardAmount;
    }

    /***********
     * Modifiers
     ***********/

    modifier onlyOwner() {
        require(address(msg.sender) == owner, "!owner");
        _;
    }

    /**********
     * Mappings
     **********/

    /// @notice keeps track of amount deposited by each sponsor for a specific token
    /// @dev mapping(sponsor => mapping(erc20 => amount))
    mapping(address => mapping(address => uint256)) public sponsorsTokens;

    /// @notice keep track of verified sponsors set by owner
    /// @dev mapping(sponsor => is verified boolean)
    mapping(address => bool) public verifiedSponsors;

    /// @notice keep track of rewards paid to contestant
    mapping(address => BountyReward[]) public bountyRewards;

    /**********
     * Events
     **********/

    event Deposit(address indexed token, uint256 amount);
    event Withdraw(
        address indexed token,
        uint256 amount,
        address indexed winner,
        string title
    );
    event WithdrawReward(
        address indexed _sponsor,
        address indexed _token,
        uint256 _amount
    );
    event SetVerifiedSponsor(address indexed sponsor, bool status);

    /*****************
     * View Functions
     *****************/

    /***
     * @notice Check token balance held by this contract
     */
    function tokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @notice Length of bounty rewards paid to winner
     */
    function bountyRewardsLength(address _winner)
        public
        view
        returns (uint256)
    {
        return bountyRewards[_winner].length;
    }

    /************
     * Functions
     ************/

    constructor(address _native, uint256 _rewardExpiresAfter) {
        owner = address(msg.sender);
        native = _native;
        rewardExpiresAfter = _rewardExpiresAfter;
    }

    /// @notice Native way to receive some ETHs
    receive() external payable {}

    /***
     * @notice Allow anyone to deposit any ERC20 tokens
     * This function will be called by sponsors to deposit some tokens into the contract
     * @param _token The address of the ERC20 token to be deposited
     * @param _amount The amount of tokens to be deposited
     **/
    function deposit(address _token, uint256 _amount)
        public
        payable
        nonReentrant
    {
        uint256 _before = tokenBalance(_token);

        if (_token == native && msg.value > 0) {
            IWETH(native).deposit{value: msg.value}();
        } else {
            IERC20(_token).safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
        }

        // Check for deflationary tokens
        _amount = tokenBalance(_token).sub(_before);

        sponsorsTokens[msg.sender][_token] += _amount;

        emit Deposit(_token, _amount);
    }

    /***
     * @notice Allow sponsors to reward winner using some ERC20 tokens.
     * This function will be called by sponsors to reward winners with some ERC20 tokens
     * @param _token The address of the token to be rewarded
     * @param _amount The amount of ERC20 tokens to be rewarded
     * @param _winner The address of the winner to be rewarded
     * @param _title The title of bounty reward
     **/
    function withdraw(
        address _token,
        uint256 _amount,
        address payable _winner,
        string memory _title
    ) external nonReentrant {
        require(
            _amount <= sponsorsTokens[address(msg.sender)][_token],
            "!balance"
        );

        sponsorsTokens[address(msg.sender)][_token] -= _amount;

        if (_token == native) {
            IWETH(native).withdraw(_amount);
            payable(_winner).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(address(_winner), _amount);
        }

        BountyReward memory _bountryReward = BountyReward({
            title: _title,
            rewardToken: _token,
            rewardAmount: _amount
        });

        bountyRewards[_winner].push(_bountryReward);

        emit Withdraw(_token, _amount, _winner, _title);
    }

    /******************
     * Owner Functions
     ******************/

    /***
     * @notice Allow sponsors to reward winner using some ERC20 tokens.
     * @dev This function will be called by owner to set status for each sponsor
     * @param _sponsor The address of the sponsor
     * @param _status The verification status of the sponsor
     **/
    function setVerifiedSponsor(address _sponsor, bool _status)
        external
        onlyOwner
    {
        verifiedSponsors[_sponsor] = _status;

        emit SetVerifiedSponsor(_sponsor, _status);
    }

    /***
     * @notice Allow owner to withdraw reward after it expires
     * @dev This function will be called by owner to withdraw reward deposited by sponsor
     * @param _sponsor The address of the sponsor
     * @param _token The address of token to withdraw
     * @param _amount The amount of token to withdraw
     **/
    function withdrawReward(
        address _sponsor,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(block.timestamp >= rewardExpiresAfter, "!active");
        sponsorsTokens[_sponsor][_token] -= _amount;

        IERC20(_token).safeTransfer(address(owner), _amount);

        emit WithdrawReward(_sponsor, _token, _amount);
    }
}
