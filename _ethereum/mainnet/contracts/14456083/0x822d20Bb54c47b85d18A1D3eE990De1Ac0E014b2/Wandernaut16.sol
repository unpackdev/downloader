// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./MerkleProof.sol";

contract Wandernauts16 is Ownable, Pausable, IERC721Receiver {
    bytes32 public immutable root;
    IERC721 public immutable target;
    uint256 public immutable price;
    address payable public payoutAddress;

    constructor(
        bytes32 _root,
        address _target,
        uint256 _price,
        address payable _payoutAddress
    ) {
        root = _root;
        target = IERC721(_target);
        price = _price;
        payoutAddress = _payoutAddress;

        _pause();
    }

    /// Unpause the contract.
    function pause() public onlyOwner {
        _pause();
    }

    /// Pause the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// Set the payout address.
    /// @param _payoutAddress the new payout address
    function setPayoutAddress(address payable _payoutAddress)
        external
        onlyOwner
    {
        payoutAddress = _payoutAddress;
    }

    /// Claim the balance of the contract.
    function claimBalance() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /// Withdraw a token from the contract
    /// @param to address to withdraw to
    /// @param tokenId id of the token
    function withdraw(address to, uint256 tokenId) external onlyOwner {
        target.safeTransferFrom(address(this), to, tokenId);
    }

    /// Buy a token stored in the contract.
    /// @param to address to send token to
    /// @param tokenId id of the token
    /// @param proof merkle proof for the purchase
    function buy(
        address to,
        uint256 tokenId,
        bytes32[] calldata proof
    ) external payable whenNotPaused {
        require(msg.value >= price, "Insufficient funds sent");
        require(_verify(_leaf(to, tokenId), proof), "Bad merkle proof");

        target.safeTransferFrom(address(this), to, tokenId);
    }

    function _leaf(address account, uint256 tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, account));
    }

    function _verify(bytes32 leaf, bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    /// IERC721Receiver implementation; only tokens from `target` are accepted.
    /// The tokens inside this contract will need to be enumerated off-chain.
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external view override returns (bytes4) {
        require(msg.sender == address(target), "Token not from target");
        return IERC721Receiver.onERC721Received.selector;
    }
}
