// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ISmartWalletWhitelist.sol";
import "./ROOT.sol";

/// @title ROOT Vesting Contract
/// @notice This contract is used for vesting ROOT tokens for the team and other stakeholders
/// @author 0xGrayMan

contract ROOTVesting is Ownable, ReentrancyGuard {
    ROOT public root;

    uint256 public tge;

    uint256 public cliff;

    uint256 public duration;

    uint256 public bpUpfrontPostCliff;

    uint256 public withdrawnTokens;

    uint256 public totalTokens;

    address public smartWalletChecker;

    mapping(address => uint256) public beneficiaryTokens;

    mapping(address => uint256) public withdrawnTokensByBeneficiary;

    event TokensReleased(address beneficiary, uint256 amount);

    constructor(
        address _root,
        uint256 _cliff,
        uint256 _duration,
        uint256 _bpUpfrontPostCliff,
        address _smartWalletChecker
    ) {
        root = ROOT(_root);
        cliff = _cliff;
        duration = _duration;
        bpUpfrontPostCliff = _bpUpfrontPostCliff;
        smartWalletChecker = _smartWalletChecker;
    }

    modifier onlyWhitelisted() {
        if (tx.origin != msg.sender) {
            require(
                address(smartWalletChecker) != address(0),
                "Not whitelisted"
            );
            require(
                ISmartWalletWhitelist(smartWalletChecker).check(msg.sender),
                "Not whitelisted"
            );
        }
        _;
    }

    function setTGE(uint256 _tge) external onlyOwner {
        require(tge == 0, "ROOTVesting : TGE has already been set");
        require(
            _tge > block.timestamp,
            "ROOTVesting : TGE should be in the future"
        );
        tge = _tge;
    }

    /// @notice Set beneficiary tokens
    /// @param _beneficiary Beneficiary address
    /// @param _amount Amount of tokens
    function _setBeneficiaryTokens(
        address _beneficiary,
        uint256 _amount
    ) internal {
        require(
            _beneficiary != address(0),
            "ROOTVesting : Beneficiary address cannot be 0"
        );
        require(_amount > 0, "ROOTVesting : Amount should be greater than 0");
        beneficiaryTokens[_beneficiary] = _amount;
        totalTokens += _amount;
    }

    /// @notice Set beneficiary tokens
    /// @param _beneficiaries Beneficiary addresses
    /// @param _amounts Amounts of tokens
    function setBeneficiaryTokens(
        address[] calldata _beneficiaries,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(
            tge == 0 || block.timestamp < tge,
            "ROOTVesting : TGE has already passed"
        );
        require(
            _beneficiaries.length == _amounts.length,
            "ROOTVesting : Invalid input data"
        );
        for (uint256 i; i < _beneficiaries.length; i++) {
            _setBeneficiaryTokens(_beneficiaries[i], _amounts[i]);
        }
    }

    /// @notice Release tokens for beneficiary
    /// @param _beneficiary Beneficiary address
    function releaseTokens(
        address _beneficiary
    ) external nonReentrant onlyWhitelisted {
        require(
            msg.sender == _beneficiary || msg.sender == owner(),
            "ROOTVesting : Only beneficiary or owner can release tokens"
        );
        uint256 totalClaimable = _totalClaimable(_beneficiary);
        uint256 toClaim = totalClaimable -
            withdrawnTokensByBeneficiary[_beneficiary];
        require(toClaim > 0, "ROOTVesting : No tokens are due");
        withdrawnTokens += toClaim;
        withdrawnTokensByBeneficiary[_beneficiary] = totalClaimable;
        root.mint(_beneficiary, toClaim);
        emit TokensReleased(_beneficiary, toClaim);
    }

    /// @notice Total claimable tokens for beneficiary
    /// @param _beneficiary Beneficiary address
    /// @return Total claimable tokens
    function _totalClaimable(
        address _beneficiary
    ) internal view returns (uint256) {
        if (block.timestamp < tge + cliff) {
            return 0;
        } else if (block.timestamp > tge + cliff + duration) {
            return beneficiaryTokens[_beneficiary];
        } else {
            return
                ((beneficiaryTokens[_beneficiary] * bpUpfrontPostCliff) /
                    10000) +
                ((beneficiaryTokens[_beneficiary] *
                    (block.timestamp - tge - cliff) *
                    (10000 - bpUpfrontPostCliff)) / (duration * 10000));
        }
    }

    /// @notice Total claimable tokens for beneficiary
    /// @param _beneficiary Beneficiary address
    /// @return Total claimable tokens
    function getTotalClaimable(
        address _beneficiary
    ) external view returns (uint256) {
        return _totalClaimable(_beneficiary);
    }

    function _totalClaimableForAll() internal view returns (uint256) {
        if (block.timestamp < tge + cliff) {
            return 0;
        } else if (block.timestamp > tge + cliff + duration) {
            return totalTokens;
        } else {
            return
                ((totalTokens * bpUpfrontPostCliff) / 10000) +
                ((totalTokens *
                    (block.timestamp - tge - cliff) *
                    (10000 - bpUpfrontPostCliff)) / (duration * 10000));
        }
    }

    function totalClaimableForAll() external view returns (uint256) {
        return _totalClaimableForAll();
    }

    function totalClaimableUnclaimed(
        address _beneficiary
    ) external view returns (uint256) {
        return
            _totalClaimable(_beneficiary) -
            withdrawnTokensByBeneficiary[_beneficiary];
    }

    function totalClaimableUnclaimedForAll() external view returns (uint256) {
        return _totalClaimableForAll() - withdrawnTokens;
    }
}
