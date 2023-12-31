// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./OpenEditionMintBase.sol";
import "./IMinter.sol";

contract OpenEditionMint is OpenEditionMintBase {

    /// minterType for this minter
    string public constant minterType = "OpenEditionMint";
    
    ///@notice Contract to mint
    address public nft;
    uint256 public projectId;


    constructor(
        address nft_,
        uint256 price_,
        uint256 maxMint_,
        address pauser_,
        uint256 startTime_,
        uint256 duration_,
        uint256 projectId_,
        address beneficiary_
    ) OpenEditionMintBase(price_, pauser_, startTime_, duration_, maxMint_, beneficiary_) {
        require(nft_ != address(0), "Nft address must not be the zero address");

        nft = nft_;
        projectId = projectId_;
    }

    function setNft(address nft_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(nft_ != address(0), "invalid nft");
        nft = nft_;
    }

    function setProjectId(uint256 _projectId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        projectId = _projectId;
    }

    function mintEdition(address to) internal override returns (uint256) {
        return IMinter(nft).mint(to, projectId, to);
    }
}