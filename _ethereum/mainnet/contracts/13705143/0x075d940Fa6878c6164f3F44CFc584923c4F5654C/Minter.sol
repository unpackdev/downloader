// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";

import "./TransferHelper.sol";

import "./IFactory.sol";
import "./InstanceRegistry.sol";

import "./CrucibleFactory.sol";

import "./console.sol";

/// @title Minter
contract Minter is ERC721Holder, Ownable {

    // ether fee
    uint256 internal _mintFee;

    // address of the deployed crucible factory contract
    address internal immutable _factory;

    mapping(address => bool) private _paid;

    constructor(address factory, uint256 mintFee) Ownable() {
        _factory = factory;
        _mintFee = mintFee;
    }

    /// @notice pays a fee and creates a crucible 
    /// crucible factory mints a crucible to the caller (`address(this)`)
    /// so we transfer the new crucible to `msg.sender` afterwards.
    function createWithEther() external payable returns (address) {
        require(msg.value == _mintFee, "incorrect ether amount");

        // deploy new vault and mint crucible nft to this contract.
        address crucible = IFactory(_factory).create("");

        // transfer nft to caller, the real owner of the new vault.
        IERC721(_factory).safeTransferFrom(address(this), msg.sender, uint256(crucible));

        _paid[crucible] = true;

        return crucible;
    }

    /// @notice pays a fee and creates a crucible with a deterministic address
    /// crucible factory mints a crucible to the caller (`address(this)`)
    /// so we transfer the new crucible to `msg.sender` afterwards.
    /// @param salt bytes32 salt used by create2
    function create2WithEther(bytes32 salt) external payable returns (address) {
        require(msg.value == _mintFee, "incorrect ether amount");

        // deploy new crucible and mint crucible nft to this contract.
        address crucible = IFactory(_factory).create2("", salt);

        // transfer nft to caller, the real owner of the new vault.
        IERC721(_factory).safeTransferFrom(address(this), msg.sender, uint256(crucible));

        _paid[crucible] = true;

        return crucible;
    }

    /// @notice pays the fee for a given crucible.
    /// access control: only owner
    /// @param crucible address of the crucible
    function payFee(address crucible) external payable returns (bool) {
        // check amount sent
        require(msg.value == _mintFee, "incorrect ether amount");
        
        // check crucible ownership
        require(IERC721(_factory).ownerOf(uint256(crucible)) == msg.sender, "not crucible owner");
    
        require(_paid[crucible] == false, "fee already paid");

        _paid[crucible] = true;

        return true;
    }

    /* getter functions */

    function getFactory() external view returns (address) {
        return _factory;
    }

    function getMintFee() external view returns (uint256) {
        return _mintFee;
    }

    function setMintFee(uint256 fee) external onlyOwner {
        _mintFee = fee;
    }

    function isPaid(address crucible) external view returns (bool) {
        return _paid[crucible];
    }

    

    /// @notice withdraw ether from the contract
    /// access control: only owner
    /// @param to address of the recipient
    function withdraw(address to) external payable onlyOwner {
        require(to != address(0), "invalid address");
        // perform transfer
        TransferHelper.safeTransferETH(to, address(this).balance);
    }

}
