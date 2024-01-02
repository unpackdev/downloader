// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./SafeERC20.sol";

/**
 * @title TokenDistribution
 * @dev A token holder contract that can distribute its ERC20 token balance to preset address list, with the
 * ability to withdraw all back to owner address.
 */
contract TokenDistribution is Ownable {
    using SafeERC20 for IERC20;

    struct TokenDistributionSetting {
        address token;
        address[] destinationAddresses;
        uint256 baseShare;
        bool initialized;
    }

    mapping(address => TokenDistributionSetting) private _tokenDistributions;
    mapping(address => mapping(address => uint256))
        private _tokenDistributionShareMap;

    constructor() Ownable(msg.sender) {}

    /**
     * @dev DO NOTHING, AVOID FAT FINGER.
     */
    function renounceOwnership() public override onlyOwner {}

    /* ========== External View FUNCTIONS ========== */

    /**
     * @return The destinationAddresses of the token distribution.
     */
    function destinationAddresses(
        address token
    ) external view returns (address[] memory) {
        return _tokenDistributions[token].destinationAddresses;
    }

    /**
     * @return The baseShare of the token distribution.
     */
    function baseShare(address token) external view returns (uint256) {
        return _tokenDistributions[token].baseShare;
    }

    /**
     * @return The initialize status of the token distribution.
     */
    function initialized(address token) external view returns (bool) {
        return _tokenDistributions[token].initialized;
    }

    /**
     * @return The destinationAddresses of the token distribution.
     */
    function distributionShare(
        address token,
        address destination
    ) external view returns (uint256) {
        return _tokenDistributionShareMap[token][destination];
    }

    /**
     * @dev Register certain token distribution rule.
     * @param _token address of the token to be distributed
     * @param _destinationAddresses the token recipient address list
     * @param _destinationShare the token recipient address shares, should be in same order as _destinationAddresses
     * @param _baseShare total share of the distribution
     */
    function registerTokenDistribution(
        address _token,
        address[] calldata _destinationAddresses,
        uint256[] calldata _destinationShare,
        uint256 _baseShare
    ) external onlyOwner {
        require(
            !_tokenDistributions[_token].initialized,
            "TokenDistribution: TokenDistribution has been registered"
        );
        require(
            _destinationAddresses.length == _destinationShare.length,
            "TokenDistribution: destinationAddresses.length is different from destinationShare.length"
        );

        uint256 totalShare;
        for (uint256 i = 0; i < _destinationAddresses.length; i++) {
            require(
                _destinationAddresses[i] != address(0),
                "TokenDistribution: destinationAddr is point to zero address"
            );
            require(
                _destinationShare[i] != 0,
                "TokenDistribution: destinationShare is set to zero"
            );
            require(
                _tokenDistributionShareMap[_token][_destinationAddresses[i]] ==
                    0,
                "TokenDistribution: destinationShare already set"
            );
            totalShare += _destinationShare[i];
            _tokenDistributionShareMap[_token][
                _destinationAddresses[i]
            ] = _destinationShare[i];
        }

        require(
            totalShare == _baseShare,
            "TokenDistribution: totalShare is different from baseShare setting"
        );

        TokenDistributionSetting memory td = TokenDistributionSetting(
            _token,
            _destinationAddresses,
            _baseShare,
            true
        );
        _tokenDistributions[_token] = td;
    }

    /**
     * @dev Able to withdraw all balance of certain token back to owner
     * @param _token address of the token to be withdraw
     */
    function withdrawAll(address _token) external onlyOwner {
        require(
            IERC20(_token).balanceOf(address(this)) > 0,
            "TokenDistribution: withdrawing 0 balance token"
        );
        IERC20(_token).safeTransfer(
            owner(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    /**
     * @dev Distribute token based on preset rule
     * @param _token address of the token to be distributed
     */
    function distribute(address _token) external {
        TokenDistributionSetting memory td = _tokenDistributions[_token];
        require(
            td.initialized,
            "TokenDistribution: TokenDistribution not registered yet"
        );
        require(
            IERC20(_token).balanceOf(address(this)) > 0,
            "TokenDistribution: distributing 0 balance token"
        );
        uint256 balance = IERC20(_token).balanceOf(address(this));
        for (uint256 i = 0; i < td.destinationAddresses.length; i++) {
            IERC20(_token).safeTransfer(
                td.destinationAddresses[i],
                (balance *
                    _tokenDistributionShareMap[_token][
                        td.destinationAddresses[i]
                    ]) / td.baseShare
            );
        }
    }
}