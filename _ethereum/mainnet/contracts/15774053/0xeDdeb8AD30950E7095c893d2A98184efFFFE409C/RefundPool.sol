// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControlEnumerable.sol";
import "./IERC721Receiver.sol";
import "./IVoteProposal.sol";
import "./PlayerOne.sol";
import "./ReentrancyGuard.sol";


contract RefundPool is ReentrancyGuard,AccessControlEnumerable,IERC721Receiver {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct RefundInfo {
        uint256 _amount;
        uint256 _refundStartTime;
    }

    // tokenId -> RefundInfo
    mapping(uint256 => RefundInfo) public refundableTokens;

    PlayerOne public playerOneContract;

    IVoteProposal public proposal;

    event Buyback(address indexed operator, address indexed from, uint256 indexed tokenId, bytes data);

    event ProposalChanged(IVoteProposal indexed previousProposal, IVoteProposal indexed newProposal);

    event Withdraw(address indexed operator,address indexed to,uint256 indexed amount);

    constructor(PlayerOne playerOneContract_){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        playerOneContract = playerOneContract_;
    }

    //Administrators of DAO
    function setProposal(IVoteProposal proposal_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IVoteProposal oldProposal = proposal;
        proposal = proposal_;
        emit ProposalChanged(oldProposal,proposal_);
    }


    //Administrators of DAO
    function withdraw(address to,uint256 amount) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        bool withdrawable = proposal.withdrawAble();
        require(withdrawable, "PlayerOne: withdrawal proposal not approved");
        //send ether
        (bool success,) = to.call{value: amount}("");
        require(success, "PlayerOne: failed to send Ether");
        emit Withdraw(msg.sender,to,amount);
    }



    function mintPlayerOne(address to, uint256 quantity,uint256 refundStartTime) external onlyRole(MINTER_ROLE) payable {
        uint256 val = msg.value / quantity;
        for (uint256 i = 1; i <= quantity; i++) {
            uint256 tokenId = playerOneContract.mint(to);
            refundableTokens[tokenId] = RefundInfo({_amount: val, _refundStartTime: refundStartTime});
        }
    }

    function transferPlayerOne(address to, uint256 quantity,uint256 refundStartTime) external onlyRole(MINTER_ROLE) payable {
        uint256 val = msg.value / quantity;
        for (uint256 i = 1; i <= quantity; i++) {
            uint256 tokenId = playerOneContract.tokenOfOwnerByIndex(address(this), 0);
            playerOneContract.safeTransferFrom(address(this), to, tokenId);
            refundableTokens[tokenId] = RefundInfo({_amount: val, _refundStartTime: refundStartTime});
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual nonReentrant override returns (bytes4)  {
        require(_msgSender() == address(playerOneContract), "PlayerOne: sender must equals playerOneContract");

        RefundInfo memory info = refundableTokens[tokenId];

        uint256 amount = info._amount;
        require(amount > 0, "PlayerOne: cannot be recycled");
        require(info._refundStartTime < block.timestamp, "PlayerOne: refund not started");

        delete refundableTokens[tokenId];

        //send ether
        (bool success,) = from.call{value: amount}("");
        require(success, "PlayerOne: failed to send Ether");

        emit  Buyback(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }



}
