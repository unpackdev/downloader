// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Context.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";

/// @title ENS main interface to fetch the resolver for a name
interface IENS {
    function resolver(bytes32 node) external view returns (IResolver);
}

/// @title ENS resolver to address interface
interface IResolver {
    function addr(bytes32 node) external view returns (address);
}

/// @title Graveyard NFT Project's ENSOwnable implementation
/// @author 0xyamyam@gmail.com
/// Contract ownership is tied to an ens token, once set the resolved address of the ens name is the contract owner.
abstract contract Ownable is Context {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// Apply a fee to release funds sent to the contract
    /// A very small price to pay for being able to regain tokens incorrectly sent here
    uint256 private _releaseFee;

    /// Configure if this contract allows release
    bool private _releasesERC20;
    bool private _releasesERC721;

    /// Ownership is set to the contract creator until a nameHash is set
    address private _owner;

    /// The ENS namehash who controls the contracts
    bytes32 public _nameHash;

    /// @dev Initializes the contract setting the deployer as the initial owner
    constructor(uint256 releaseFee, bool releasesERC20, bool releasesERC721) {
        _owner = _msgSender();
        _releaseFee = releaseFee;
        _releasesERC20 = releasesERC20;
        _releasesERC721 = releasesERC721;
    }

    /// @dev Returns the address of the current owner
    function owner() public view virtual returns (address) {
        if (_nameHash == "") return _owner;
        bytes32 node = _nameHash;
        IENS ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        IResolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /// Set the ENS name as owner
    /// @param nameHash The bytes32 hash of the ens name
    function setNameHash(bytes32 nameHash) external onlyOwner {
        _nameHash = nameHash;
    }

    /// Return ERC20 tokens sent to the contract, an optional fee is automatically applied.
    /// @notice If your reading this you are very lucky, most tokens sent to contracts can never be recovered.
    /// @param token The ERC20 token address
    /// @param to The address to send funds to
    /// @param amount The amount of tokens to send (minus any fee)
    function releaseERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        require(_releasesERC20, "Not allowed");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");

        uint share = 100;
        if (_releaseFee > 0) token.safeTransfer(_msgSender(), amount.mul(_releaseFee).div(100));
        token.safeTransfer(to, amount.mul(share.sub(_releaseFee)).div(100));
    }

    /// Return ERC721 tokens sent to the contract, a fee may be required.
    /// @notice If your reading this you are very lucky, most tokens sent to contracts can never be recovered.
    /// @param tokenAddress The ERC721 token address
    /// @param to The address to the send the token to
    /// @param tokenId The ERC721 tokenId to send
    function releaseERC721(IERC721 tokenAddress, address to, uint256 tokenId) external onlyOwner {
        require(_releasesERC721, "Not allowed");
        require(tokenAddress.ownerOf(tokenId) == address(this), "Invalid tokenId");

        tokenAddress.safeTransferFrom(address(this), to, tokenId);
    }

    /// Withdraw eth from contract.
    /// @dev many contracts are guarded by default against this, but should a contract have receive/fallback methods
    /// a bug could be introduced that make this a great help.
    function withdraw() external virtual onlyOwner {
        payable(_msgSender()).call{value: address(this).balance}("");
    }
}
