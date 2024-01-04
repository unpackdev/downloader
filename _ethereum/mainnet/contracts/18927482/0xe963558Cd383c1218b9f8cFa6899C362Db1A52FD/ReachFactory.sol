// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.19;

import "./ReachAffiliateDistribution.sol";
import "./Ownable2Step.sol";
import "./ECDSA.sol";
import "./SafeERC20.sol";

error InvalidDistributionAddress();

/**
 * @title ReachDistributionFactory
 * @dev This contract allows for the management of Reach token distributions.
 */
contract ReachDistributionFactory is Ownable2Step {
    using SafeERC20 for IERC20;

    // Events
    event ReachAffiliateDistributionCreated(
        address indexed distribution,
        uint256 timestamp
    );

    // State variables
    address public reachToken;
    address public mainDistribution;

    /**
     * @dev Constructor that sets the initial Reach token address.
     * @param _reachToken The address of the Reach token.
     * @param _mainDistribution The address of the main distribution.
     */
    constructor(address _reachToken, address _mainDistribution) {
        if (_reachToken == address(0)) {
            revert InvalidTokenAddress();
        }
        reachToken = _reachToken;
        mainDistribution = _mainDistribution;
    }

    // External functions
    /**
     * @dev Deploys a new affiliate distribution.
     */
    function deployAffiliateDistribution(address _owner) external onlyOwner {
        ReachAffiliateDistribution newDistribution = new ReachAffiliateDistribution(
                reachToken,
                _owner,
                mainDistribution
            );

        emit ReachAffiliateDistributionCreated(
            address(newDistribution),
            block.timestamp
        );
    }

    /**
     * @dev Withdraws all Reach tokens to the owner's address.
     */
    function withdrawTokens() external onlyOwner {
        uint256 balance = IERC20(reachToken).balanceOf(address(this));

        IERC20(reachToken).safeTransfer(owner(), balance);
    }

    /**
     * @dev Withdraws all Ether to the owner's address.
     */
    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Public functions
    /**
     * @dev Sets the Reach token address.
     * @param _token The address of the new Reach token.
     */
    function setToken(address _token) public onlyOwner {
        if (_token == address(0) || IERC20(_token).totalSupply() == 0) {
            revert InvalidTokenAddress();
        }
        reachToken = _token;
    }

    /**
     * @dev Sets the main distribution address.
     * @param _mainDistribution The address of the new main distribution.
     */
    function setMainDistribution(address _mainDistribution) public onlyOwner {
        if (_mainDistribution == address(0)) {
            revert InvalidDistributionAddress();
        }
        mainDistribution = _mainDistribution;
    }

    // Override functions
    /**
     * @dev Prevents the ownership from being renounced.
     */
    function renounceOwnership() public virtual override onlyOwner {
        revert("Can't renounce ownership");
    }
}
