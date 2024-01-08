// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ERC20Pausable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IFiat24Account.sol";

contract F24 is ERC20, ERC20Permit, ERC20Votes, ERC20Pausable, AccessControl {
    using SafeMath for uint256;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public maxSupply;
    uint256 public airdropEndTime; // Timestamp
    uint256 public airdropMaxClaim;
    uint256 public airdropInviteeClaim;
    uint256 public airdropLiveClaim;

    mapping(uint256 => uint256) public claim;
    IFiat24Account fiat24account;

    constructor(address fiat24accountProxyAddress,
                uint256 maxSupply_,
                uint256 airdropTotal_,
                uint256 airdropEndTime_,
                uint256 airdropInviteeClaim_,
                uint256 airdropLiveClaim_) ERC20("Fiat24", "F24") ERC20Permit("Fiat24") {
        require(airdropTotal_ <= maxSupply_, "F24: Airdrop higher than max supply - free supply");
        maxSupply = maxSupply_;
        _mint(msg.sender, maxSupply_ - airdropTotal_);
        _mint(address(this), airdropTotal_);

        airdropEndTime = airdropEndTime_;
        airdropInviteeClaim = airdropInviteeClaim_;
        airdropLiveClaim = airdropLiveClaim_;
        airdropMaxClaim = airdropLiveClaim + airdropInviteeClaim;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);

        fiat24account = IFiat24Account(fiat24accountProxyAddress);
    }

    function claimToken(uint256 tokenId) external {
        require(block.timestamp <= airdropEndTime, "F24: Airdrop expired");
        require(fiat24account.ownerOf(tokenId) == msg.sender ||
                fiat24account.historicOwnership(msg.sender) == tokenId, "F24: Not owner of token");
        require(fiat24account.status(tokenId) == IFiat24Account.Status.Live ||
                fiat24account.status(tokenId) == IFiat24Account.Status.Invitee,"F24: Not Live or Invitee");

        uint256 amount = eligibleClaimAmount(tokenId);
        if(amount > 0) {
            claim[tokenId] += amount;
            _transfer(address(this), msg.sender, amount);
        }
    }

    function eligibleClaimAmount(uint256 tokenId) public view returns(uint256) {
        require(block.timestamp <= airdropEndTime, "F24: Airdrop expired");
        uint256 amount = 0;
        bool success = true;
        if(tokenExists(tokenId)) {
            if(fiat24account.status(tokenId) == IFiat24Account.Status.Live) {
                (success, amount) = airdropMaxClaim.trySub(claim[tokenId]);
            } else if(fiat24account.status(tokenId) == IFiat24Account.Status.Invitee) {
                (success, amount) = airdropInviteeClaim.trySub(claim[tokenId]);
            }
        } else {   
            success = false;
        }
        return success ? amount : 0;
    }

    function sweep(address dest) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "F24: Not an operator");
        require(block.timestamp > airdropEndTime, "F24: Claim period not yet ended");
        _transfer(address(this), dest, balanceOf(address(this)));
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function tokenExists(uint256 tokenId) internal view returns(bool){
        try fiat24account.ownerOf(tokenId) returns(address) {
            return true;
        } catch Error(string memory) {
            return false;
        } catch (bytes memory) {
            return false;
        }
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
       super._beforeTokenTransfer(from, to, amount);

    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }
}