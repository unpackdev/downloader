// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ISmartWalletWhitelist.sol";
import "./ROOT.sol";
import "./RNFTV2.sol";
import "./console.sol";

/// @title ROOT Vesting Contract
/// @notice This contract is used for vesting ROOT tokens for the team and other stakeholders
/// @author 0xGrayMan

contract RNFTVesting is Ownable, ReentrancyGuard {
    ROOT public root;

    uint256 public tge;

    uint256 public cliff;

    uint256 public duration;

    uint256 public bpUpfrontPostCliff;

    uint256 public withdrawnTokens;

    address public smartWalletChecker;

    RNFTV2 public rnftv2;

    uint256 public beneficiaryTokens = 2000000000000000000000;

    mapping(uint256 => uint256) public withdrawnTokensByBeneficiary;

    event TokensReleased(uint256 tokenId, uint256 amount);

    constructor(
        address _root,
        uint256 _cliff,
        uint256 _duration,
        uint256 _bpUpfrontPostCliff,
        address _smartWalletChecker,
        address _rnftv2
    ) {
        root = ROOT(_root);
        cliff = _cliff;
        duration = _duration;
        bpUpfrontPostCliff = _bpUpfrontPostCliff;
        smartWalletChecker = _smartWalletChecker;
        rnftv2 = RNFTV2(_rnftv2);
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

    function setBeneficiaryTokens(
        uint256 _beneficiaryTokens
    ) external onlyOwner {
        beneficiaryTokens = _beneficiaryTokens;
    }

    function releaseTokens(
        uint256 _tokenId
    ) external nonReentrant onlyWhitelisted {
        require(
            msg.sender == rnftv2.ownerOf(_tokenId) || msg.sender == owner(),
            "ROOTVesting : Only nft holder or owner can release tokens"
        );
        _releaseTokens(_tokenId);
    }

    function _releaseTokens(uint256 _tokenId) internal {
        require(
            msg.sender == rnftv2.ownerOf(_tokenId) || msg.sender == owner(),
            "ROOTVesting : Only nft holder or owner can release tokens"
        );
        uint256 totalClaimable = _totalClaimable();
        uint256 toClaim = totalClaimable -
            withdrawnTokensByBeneficiary[_tokenId];
        require(toClaim > 0, "ROOTVesting : No tokens are due");
        withdrawnTokens += toClaim;
        withdrawnTokensByBeneficiary[_tokenId] = totalClaimable;
        root.mint(msg.sender, toClaim);
        emit TokensReleased(_tokenId, toClaim);
    }

    function releaseTokensForUser() external nonReentrant onlyWhitelisted {
        uint256[] memory tokens = rnftv2.getUserTokens(msg.sender);
        uint256 i = 0;
        for (i = 0; i < tokens.length; i++) {
            _releaseTokens(tokens[i]);
        }
    }

    function _totalClaimable() internal view returns (uint256) {
        if (block.timestamp < tge + cliff) {
            return 0;
        } else if (block.timestamp > tge + cliff + duration) {
            return beneficiaryTokens;
        } else {
            return
                ((beneficiaryTokens * bpUpfrontPostCliff) / 10000) +
                ((beneficiaryTokens *
                    (block.timestamp - tge - cliff) *
                    (10000 - bpUpfrontPostCliff)) / (duration * 10000));
        }
    }

    function getTotalClaimable() external view returns (uint256) {
        return _totalClaimable();
    }

    function totalClaimableUnclaimed(
        uint256 _tokenId
    ) external view returns (uint256) {
        return _totalClaimable() - withdrawnTokensByBeneficiary[_tokenId];
    }

    function totalClaimableUnclaimedForUser(
        address _holder
    ) external view returns (uint256 _total) {
        uint256[] memory tokens = rnftv2.getUserTokens(_holder);
        uint256 i = 0;
        for (i = 0; i < tokens.length; i++) {
            _total += (_totalClaimable() -
                withdrawnTokensByBeneficiary[tokens[i]]);
        }
    }

    function withdrawnTokensByUser(
        address _holder
    ) external view returns (uint256 _total) {
        uint256[] memory tokens = rnftv2.getUserTokens(_holder);
        uint256 i = 0;
        for (i = 0; i < tokens.length; i++) {
            _total += withdrawnTokensByBeneficiary[tokens[i]];
        }
    }
}
