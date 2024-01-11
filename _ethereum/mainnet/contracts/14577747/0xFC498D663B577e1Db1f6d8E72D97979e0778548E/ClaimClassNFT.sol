// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./DeepSkyNetwork.sol";
import "./TheLostGlitches.sol";
import "./TLGStakingV1.sol";

contract ClaimClassNFT is Pausable, Ownable {
    address public trustedSigner;
    TheLostGlitches public tlg;
    DeepSkyNetwork public dsn;
    TLGStakingV1 public tlgStaking;
    mapping(uint256 => bool) public hasClaimed;

    constructor(
        address _tlg,
        address _tlgStaking,
        address _dsn,
        address _trustedSigner
    ) {
        tlg = TheLostGlitches(_tlg);
        dsn = DeepSkyNetwork(_dsn);
        tlgStaking = TLGStakingV1(_tlgStaking);
        trustedSigner = _trustedSigner;
    }

    function setTrustedSigner(address _trustedSigner) external onlyOwner {
      trustedSigner = _trustedSigner;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function claim(uint256 glitch, uint256 tokenId, bytes memory signature) external whenNotPaused {
      require(!hasClaimed[glitch], "Already claimed");
      require(_isAllowed(msg.sender, glitch), "Not allowed");

      bytes32 messageHash = keccak256(abi.encodePacked(address(this), glitch, tokenId));
      bytes32 ethMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

      require(SignatureChecker.isValidSignatureNow(trustedSigner, ethMessageHash, signature), "InvalidSignature");

      hasClaimed[glitch] = true;
      dsn.mint(msg.sender, tokenId, 1, "");
    }

    function _isAllowed(address operator, uint256 glitch) internal view virtual returns (bool) {
        require(tlg.exists(glitch), "ERC721: operator query for nonexistent token");
        address owner = tlg.ownerOf(glitch);
        address staker = tlgStaking.userStakedGlitch(glitch);
        return (operator == owner || operator == staker);
    }
}
