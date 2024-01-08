// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IStakingPool {

    event BondRegistered(address bond, string name);

    event FutureRegistered(address future, string name);

    event TokensClaimed(address token, uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account);

    event TokensConverted(address from, address to, address account, uint256 amount);

    event TokensBurned(address token, address account, bytes recipient, uint256 amount);

    function isClaimValid(address token, uint256 claimId, uint256 claimBeforeBlock, uint256 amount, address to, bytes memory signature) external view returns (bool);

    function isClaimUsed(uint256 claimId) external view returns (bool);

    function claimBonds(address bond, uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account, bytes memory signature) external;

    function claimFutures(address future, uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account, bytes memory signature) external;

    function burnBond(address bond, uint256 amount, bytes calldata recipient) external;

    function burnFuture(address future, uint256 tokenId, bytes memory polkadotRecipient) external;
}
