// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TwoStageOwnable.sol";

contract Escrow is TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct ReleaseProps {
        uint256 timestamp;
        uint256 amount;
    }

    struct Release {
        uint256 index;
        ReleaseProps props;
    }

    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    bool public initialized = false;

    Release[] private _releases;
    IERC20 private _token;

    function releases(uint256 index) public view returns (Release memory) {
        return _getRelease(index);
    }

    function allReleases() public view returns (Release[] memory) {
        return _releases;
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    event Claimed(uint256 indexed releaseIndex, uint256 amount);
    event Initialized();
    event ReleaseAdded(uint256 indexed releaseIndex, uint256 timestamp, uint256 amount);

    constructor(IERC20 token_) public TwoStageOwnable(msg.sender) {
        _token = token_;
    }

    function addRelease(uint256 timestamp, uint256 amount)
        external
        onlyNotInitialized
        onlyOwner
        returns (uint256 releaseIndex)
    {
        releaseIndex = _releases.length;
        _addRelease(ReleaseProps(timestamp, amount));
        _token.safeTransferFrom(owner, address(this), amount);
    }

    function addReleases(ReleaseProps[] memory releases_)
        external
        onlyNotInitialized
        onlyOwner
        returns (uint256 startIndex)
    {
        uint256 releasesCount = releases_.length;
        require(releasesCount > 0, "No releases provided");
        startIndex = _releases.length;
        uint256 sumAmount = 0;
        for (uint256 releaseIndex = 0; releaseIndex < releasesCount; releaseIndex++) {
            ReleaseProps memory props = releases_[releaseIndex];
            _addRelease(props);
            sumAmount = sumAmount.add(props.amount);
        }
        _token.safeTransferFrom(owner, address(this), sumAmount);
    }

    function initialize() external onlyNotInitialized onlyOwner returns (bool success) {
        initialized = true;
        emit Initialized();
        return true;
    }

    function claim(uint256 releaseIndex, uint256 amount) external onlyOwner returns (bool success) {
        require(initialized, "Not initialized yet");
        require(amount > 0, "No amount to claim");
        Release storage release = _getRelease(releaseIndex);
        require(getTimestamp() >= release.props.timestamp, "Not released yet");
        require(release.props.amount >= amount, "Release pool is extinguished");
        release.props.amount -= amount;
        emit Claimed(releaseIndex, amount);
        _token.safeTransfer(owner, amount);
        return true;
    }

    function _addRelease(ReleaseProps memory props) private {
        require(props.amount > 0, "Release is empty");
        require(props.timestamp > getTimestamp(), "Already released");
        uint256 index = _releases.length;
        _releases.push(Release(index, props));
        emit ReleaseAdded(index, props.timestamp, props.amount);
    }

    function _getRelease(uint256 index) private view returns (Release storage) {
        require(index < _releases.length, "Index out of bounds");
        return _releases[index];
    }

    modifier onlyNotInitialized() {
        require(!initialized, "Already initialized");
        _;
    }
}
