//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ITokenVesting.sol";

// import "./console.sol";

contract TokenVesting is ITokenVesting, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev whitelists store all active whitelist members for all tokens.
     */
    mapping(uint256 => mapping(address => WhitelistInfo)) public whitelists;

    /**
     * @dev vestingInfos store all vesting informations.
     */
    mapping(uint256 => VestingInfo) public vestingInfos;

    /**
     * @dev vestingTokens store all active vesting tokens.
     */
    mapping(uint256 => address) public vestingTokens;

    /**
     * @dev token indexer
     */
    uint256 public tokenId;

    address public TREASURY;

    constructor(address _treasury) {
        TREASURY = _treasury;
    }

    /**
     *
     * @dev setup vesting plans for investors
     *
     * @param _strategy indicate the distribution plan - seed, strategic and private
     * @param _cliff duration in days of the cliff in which tokens will begin to vest
     * @param _start vesting start date
     * @param _duration duration in days of the period in which the tokens will vest
     *
     */
    function setVestingInfo(
        uint256 _strategy,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _step
    ) external override onlyOwner {
        require(_strategy != 0, "Strategy should be correct");
        require(!vestingInfos[_strategy].active, "Vesting option already exist");

        vestingInfos[_strategy].strategy = _strategy;
        vestingInfos[_strategy].cliff = _cliff;
        vestingInfos[_strategy].start = _start;
        vestingInfos[_strategy].duration = _duration;
        vestingInfos[_strategy].step = _step;
        vestingInfos[_strategy].active = true;

        emit VestingInfoAdded(_strategy, _cliff, _start, _duration);
    }

    /**
     *
     * @dev remove existing vesting plan
     *
     * @param _strategy indicate the distribution plan - seed, strategic and private
     *
     */
    function deleteVestingInfo(uint256 _strategy) external override onlyOwner {
        require(_strategy != 0, "Strategy should be correct");
        require(vestingInfos[_strategy].active, "Vesting is not existed");

        delete vestingInfos[_strategy];

        emit VestingInfoDeleted(_strategy);
    }

    /**
     *
     * @dev update cliff of whitelisted user
     *
     * @param _tokenId vesting token index
     * @param _wallet whitelisted user address
     * @param _cliff updated cliff duration in day
     *
     */
    function updateUserCliff(
        uint256 _tokenId,
        address _wallet,
        uint256 _cliff
    ) external override onlyOwner {
        require(whitelists[_tokenId][_wallet].active, "User is not whitelisted");

        whitelists[_tokenId][_wallet].cliff = _cliff;

        emit UserCliffUpdated(_tokenId, _wallet, _cliff);
    }

    /**
     *
     * @dev update tokenAmount of whitelisted user
     *
     * @param _tokenId vesting token index
     * @param _wallet whitelisted user address
     * @param _tokenAmount updated cliff duration in day
     *
     */
    function updateUserTokenAmount(
        uint256 _tokenId,
        address _wallet,
        uint256 _tokenAmount
    ) external override onlyOwner {
        require(whitelists[_tokenId][_wallet].active, "User is not whitelisted");

        whitelists[_tokenId][_wallet].tokenAmount = _tokenAmount;

        emit UserTokenAmountUpdated(_tokenId, _wallet, _tokenAmount);
    }

    /**
     *
     * @dev set the address as whitelist user address
     *
     * @param _tokenId token index
     * @param _wallet wallet addresse array
     * @param _tokenAmount vesting token amount array
     * @param _option vesting info array
     *
     */
    function addWhitelists(
        uint256 _tokenId,
        address[] calldata _wallet,
        uint256[] calldata _tokenAmount,
        uint256[] calldata _option
    ) external override onlyOwner {
        require(_wallet.length == _tokenAmount.length, "Invalid array length");
        require(_option.length == _tokenAmount.length, "Invalid array length");

        for (uint256 i = 0; i < _wallet.length; i++) {
            require(whitelists[_tokenId][_wallet[i]].wallet != _wallet[i], "Whitelist already available");
            require(vestingInfos[_option[i]].active, "Vesting option is not existing");

            whitelists[_tokenId][_wallet[i]] = WhitelistInfo(
                _wallet[i],
                _tokenAmount[i],
                0,
                block.timestamp,
                vestingInfos[_option[i]].cliff,
                vestingInfos[_option[i]].start,
                vestingInfos[_option[i]].duration,
                vestingInfos[_option[i]].step,
                vestingInfos[_option[i]].start + vestingInfos[_option[i]].cliff * 1 days,
                _option[i],
                true
            );

            emit AddWhitelist(_tokenId, _wallet[i]);
        }
    }

    /**
     *
     * @dev delete whitelisted user wallets
     *
     * @param _tokenId token index
     * @param _wallet wallet addresse array
     *
     */
    function deleteWhitelists(uint256 _tokenId, address[] calldata _wallet) external override onlyOwner {
        for (uint256 i = 0; i < _wallet.length; i++) {
            delete whitelists[_tokenId][_wallet[i]];
            emit DeleteWhitelist(_tokenId, _wallet[i]);
        }
    }

    /**
     *
     * @dev add vesting token to contract
     *
     * @param _tokenId token index
     * @param _token address of IERC20 instance
     *
     */
    function addVestingToken(uint256 _tokenId, IERC20 _token) external override onlyOwner {
        vestingTokens[_tokenId] = address(_token);
        emit VestingTokenAdded(_tokenId, address(_token));
    }

    /**
     *
     * @dev distribute the token to the investors
     *
     * @param _tokenId vesting token index
     *
     * @return {bool} return status of distribution
     *
     */
    function claimDistribution(uint256 _tokenId) external override nonReentrant returns (bool) {
        WhitelistInfo storage wInfo = whitelists[_tokenId][msg.sender];

        require(wInfo.active, "User is not in whitelist");

        require(block.timestamp >= wInfo.nextReleaseTime, "NextReleaseTime is not reached");

        uint256 releaseAmount = calculateReleasableAmount(_tokenId, msg.sender);

        if (releaseAmount != 0) {
            IERC20(vestingTokens[_tokenId]).safeTransfer(msg.sender, releaseAmount);
            wInfo.distributedAmount = wInfo.distributedAmount + releaseAmount;
            wInfo.nextReleaseTime =
                uint256((block.timestamp - wInfo.start) / wInfo.step + 1) *
                wInfo.step +
                wInfo.start;
            return true;
        }

        return false;
    }

    /**
     *
     * @dev calculate releasable amount by subtracting distributed amount
     *
     * @param _tokenId vesting token index
     * @param _wallet investor wallet address
     *
     * @return {uint256} releasable amount of the whitelist
     *
     */
    function calculateReleasableAmount(uint256 _tokenId, address _wallet) public view returns (uint256) {
        return calculateVestAmount(_tokenId, _wallet) - whitelists[_tokenId][_wallet].distributedAmount;
    }

    /**
     *
     * @dev calculate the total vested amount by the time
     *
     * @param _tokenId vesting token index
     * @param _wallet user wallet address
     *
     * @return {uint256} return vested amount
     *
     */
    function calculateVestAmount(uint256 _tokenId, address _wallet) public view returns (uint256) {
        WhitelistInfo memory info = whitelists[_tokenId][_wallet];
        if (block.timestamp < info.cliff * 1 days + info.start) {
            return 0;
        } else if (block.timestamp >= info.start + (info.duration * 1 days)) {
            return info.tokenAmount;
        }

        return
            (info.tokenAmount * uint256((block.timestamp - info.start) / info.step) * info.step) /
            (info.duration * 1 days);
    }

    /**
     *
     * @dev Retrieve total amount of token from the contract
     *
     * @param {address} address of the token
     *
     * @return {uint256} total amount of token
     *
     */
    function getTotalToken(IERC20 _token) external view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function getWhitelist(uint256 _tokenId, address _user) public view returns (WhitelistInfo memory) {
        return whitelists[_tokenId][_user];
    }

    function withdrawToTreasury(uint256 _tokenId, uint256 _amount) public onlyOwner {
        IERC20(vestingTokens[_tokenId]).safeTransfer(TREASURY, _amount);
    }
}
