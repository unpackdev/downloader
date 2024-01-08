// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Bounty.sol";

contract ManualRedeemer is IBountyRedeemer, ReentrancyGuard {
    address bounty;

    function manuallyRedeem(
        address _bounty,
        address _nftContract,
        uint256 _tokenID,
        uint256 _amount
    ) external {
        require(
            bounty == address(0),
            "ManualRedeemer::manuallyRedeem: bounty already set"
        );
        bounty = _bounty;
        bytes memory _callData = abi.encode(msg.sender, _nftContract, _tokenID);
        IBounty(_bounty).redeemBounty(this, _amount, _callData);
        delete bounty;
    }

    function onRedeemBounty(address _initiator, bytes calldata _data)
        external
        payable
        override
        nonReentrant
        returns (bytes32)
    {
        require(
            msg.sender == bounty,
            "ManualRedeemer::onRedeemBounty: received call from untrusted bounty"
        );
        require(
            _initiator == address(this),
            "ManualRedeemer::onRedeemBounty: only ManualRedeem can originate a redemption"
        );

        address _nftOwner;
        address _nftContract;
        uint256 _tokenID;
        (_nftOwner, _nftContract, _tokenID) = abi.decode(
            _data,
            (address, address, uint256)
        );

        IERC721(_nftContract).safeTransferFrom(_nftOwner, msg.sender, _tokenID);
        payable(_nftOwner).transfer(msg.value);

        return keccak256("IBountyRedeemer.onRedeemBounty");
    }
}
