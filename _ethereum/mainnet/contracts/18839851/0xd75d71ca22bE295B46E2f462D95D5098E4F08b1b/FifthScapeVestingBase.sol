// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract FifthScapeVestingBase is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public start;
    uint256 public duration;
    uint256 public initialReleasePercentage;
    uint256 public endDate;

    mapping(address => uint256) private _allocatedTokens;
    mapping(address => uint256) private _claimedTokens;
    mapping(address => bool) private _managers;
    mapping(address => bool) private _blacklist;

    event TokensAllocated(address indexed beneficiary, uint256 value);
    event TokensClaimed(address indexed beneficiary, uint256 value);
    event StartUpdated(uint256 oldStart, uint256 newStart);
    event TokenUpdated(address oldToken, address newToken);
    event ManagerSetted(address manager, bool isManager);
    event Blacklisted(address account);
    event BlacklistRemoved(address account);
    event DurationUpdated(uint256 oldDuration, uint256 newDuration);
    event InitialReleasePercentageUpdated(
        uint256 oldInitialReleasePercentage,
        uint256 newInitialReleasePercentage
    );
    event EndDateUpdated(uint256 oldEndDate, uint256 newEndDate);

    modifier onlyManager() {
        require(
            _managers[msg.sender] == true,
            "FifthScapeVestingBase: not manager"
        );
        _;
    }

    constructor(
        address token_,
        uint256 start_,
        uint256 duration_,
        uint256 initialReleasePercentage_,
        address _owner
    ) Ownable(_owner) {
        token = IERC20(token_);
        start = start_;
        duration = duration_;
        initialReleasePercentage = initialReleasePercentage_;
        endDate = start + duration;
    }

    function claimTokens(
        address[] memory _beneficiaries
    ) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            uint256 claimableTokens = getClaimableTokens(_beneficiaries[i]);
            require(
                claimableTokens > 0,
                "FifthScapeVestingBase: no claimable tokens"
            );

            require(
                _blacklist[_beneficiaries[i]] == false,
                "FifthScapeVestingBaseL: beneficiary is blacklisted"
            );

            _claimedTokens[_beneficiaries[i]] += claimableTokens;
            token.safeTransfer(_beneficiaries[i], claimableTokens);

            emit TokensClaimed(_beneficiaries[i], claimableTokens);
        }
    }

    function getAllocatedTokens(
        address _beneficiary
    ) public view returns (uint256 amount) {
        return _allocatedTokens[_beneficiary];
    }

    function getClaimedTokens(
        address _beneficiary
    ) public view returns (uint256 amount) {
        return _claimedTokens[_beneficiary];
    }

    function getClaimableTokens(
        address _beneficiary
    ) public view returns (uint256 amount) {
        uint256 releasedTokens = getReleasedTokensAtTimestamp(
            _beneficiary,
            _currentTime()
        );
        return releasedTokens - _claimedTokens[_beneficiary];
    }

    function getReleasedTokensAtTimestamp(
        address _beneficiary,
        uint256 _timestamp
    ) public view returns (uint256 amount) {
        if (_timestamp < start) {
            return 0;
        }

        uint256 elapsedTime = _timestamp - start;

        if (elapsedTime >= duration) {
            return _allocatedTokens[_beneficiary];
        }

        uint256 initialRelease = (_allocatedTokens[_beneficiary] *
            initialReleasePercentage) / 100;
        uint256 remainingTokensAfterInitialRelease = _allocatedTokens[
            _beneficiary
        ] - initialRelease;
        uint256 subsequentRelease = (remainingTokensAfterInitialRelease *
            elapsedTime) / duration;
        uint256 totalReleasedTokens = initialRelease + subsequentRelease;

        return totalReleasedTokens;
    }

    function getBlacklist(
        address _account
    ) public view returns (bool isBlacklist) {
        return _blacklist[_account];
    }

    function getManager(address _account) public view returns (bool isManager) {
        isManager = _managers[_account];
    }

    function allocateTokensManager(
        address _benificiary,
        uint256 _amount
    ) external whenNotPaused nonReentrant onlyManager {
        address[] memory benificiary = new address[](1);
        benificiary[0] = _benificiary;
        uint256[] memory amount = new uint256[](1);
        amount[0] = _amount;

        _allocateTokens(benificiary, amount);
    }

    function allocateTokens(
        address[] memory _benificiaries,
        uint256[] memory _amounts
    ) external onlyOwner {
        _allocateTokens(_benificiaries, _amounts);
    }

    function updateStart(uint256 _start) external onlyOwner {
        uint256 oldStart = start;
        start = _start;

        emit StartUpdated(oldStart, _start);
    }

    function updateToken(address _token) external onlyOwner {
        address oldToken = address(token);
        token = IERC20(_token);

        emit TokenUpdated(oldToken, _token);
    }

    function updateDuration(uint256 _newDuration) external onlyOwner {
        uint256 oldDuration = duration;
        duration = _newDuration;

        emit DurationUpdated(oldDuration, _newDuration);
    }

    function updateInitialReleasePercentage(
        uint256 _newInitialReleasePercentage
    ) external onlyOwner {
        uint256 oldInitialReleasePercentage = initialReleasePercentage;
        initialReleasePercentage = _newInitialReleasePercentage;

        emit InitialReleasePercentageUpdated(
            oldInitialReleasePercentage,
            _newInitialReleasePercentage
        );
    }

    function updateEndDate(uint256 _newEndDate) external onlyOwner {
        uint256 oldEndDate = endDate;
        endDate = _newEndDate;

        emit EndDateUpdated(oldEndDate, _newEndDate);
    }

    function setManager(address _manager, bool _isManager) external onlyOwner {
        require(
            _manager != address(0),
            "FifthScapeVestingBase: manager is invalid"
        );
        _managers[_manager] = _isManager;

        emit ManagerSetted(_manager, _isManager);
    }

    function blacklist(address _beneficiary) external onlyOwner {
        require(
            _beneficiary != address(0),
            "FifthScapeVestingBase: beneficiary is invalid"
        );
        _allocatedTokens[_beneficiary] = 0;
        _claimedTokens[_beneficiary] = 0;
        _blacklist[_beneficiary] = true;

        emit Blacklisted(_beneficiary);
    }

    function removeBlacklist(address _beneficiary) external onlyOwner {
        require(
            _beneficiary != address(0),
            "FifthScapeVestingBase: beneficiary is invalid"
        );
        _blacklist[_beneficiary] = false;

        emit BlacklistRemoved(_beneficiary);
    }

    function _allocateTokens(
        address[] memory _beneficiaries,
        uint256[] memory _amounts
    ) internal {
        require(
            _beneficiaries.length == _amounts.length,
            "FifthScapeVestingBase: beneficiaries and amounts length mismatched"
        );

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            require(
                _beneficiaries[i] != address(0),
                "FifthScapeVestingBase: invalid beneficiary"
            );

            require(
                _blacklist[_beneficiaries[i]] == false,
                "FifthScapeVestingBaseL: beneficiary is blacklisted"
            );

            _allocatedTokens[_beneficiaries[i]] =
                _allocatedTokens[_beneficiaries[i]] +
                _amounts[i];

            emit TokensAllocated(_beneficiaries[i], _amounts[i]);
        }
    }

    function _currentTime() internal view returns (uint256 currentTime) {
        currentTime = block.timestamp;
    }

    function withdrawERC20(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        IERC20 currentToken = IERC20(_tokenAddress);
        currentToken.approve(address(this), _amount);
        currentToken.safeTransferFrom(address(this), owner(), _amount);
    }

    function withdrawNative(uint256 _amount) external onlyOwner {
        (bool hs, ) = payable(owner()).call{value: _amount}("");
        require(hs, "EnergiWanBridge:: Failed to withdraw native coins");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
