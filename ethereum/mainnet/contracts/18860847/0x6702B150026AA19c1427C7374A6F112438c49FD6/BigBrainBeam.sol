// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./Counters.sol";

interface IBigBrainBeings is IERC721 {
    function totalSupply() external view returns (uint256);
}

/**
 * @title Big Brain Beam
 * @author 0xVersteckt
 */
contract BigBrainBeam is IERC721Receiver, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _beamCounter;
    IBigBrainBeings bigBrainBeings;
    uint256 private _seed = 2;

    struct Recipient {
        address addr;
        uint256 tokenId;
        uint256 beamedTokenId;
        uint256 ethAmount;
        address erc20Address;
        uint256 erc20Amount;
    }

    mapping(uint256 => Recipient) public recipients;

    constructor(address bigBrainBeingsAddress) {
        _beamCounter.increment();
        bigBrainBeings = IBigBrainBeings(bigBrainBeingsAddress);
    }

    modifier incrementBeamCounter() {
        _;
        _beamCounter.increment();
    }

    function beam(uint256 tokenId) public onlyOwner incrementBeamCounter {
        Recipient memory recipient = _getRandomRecipient();
        recipient.tokenId = tokenId;
        recipients[_beamCounter.current()] = recipient;
        bigBrainBeings.approve(recipient.addr, tokenId);
        bigBrainBeings.safeTransferFrom(address(this), recipient.addr, tokenId);
    }

    function beamEthereum(
        uint256 amount
    ) public onlyOwner incrementBeamCounter {
        Recipient memory recipient = _getRandomRecipient();
        recipient.ethAmount = amount;
        recipients[_beamCounter.current()] = recipient;
        (bool success, ) = address(recipient.addr).call{
            value: amount == 0 ? address(this).balance : amount
        }("");
        require(success, "F");
    }

    function beamERC20(
        address tokenAddr,
        uint256 amount
    ) public onlyOwner incrementBeamCounter {
        Recipient memory recipient = _getRandomRecipient();
        recipient.erc20Address = tokenAddr;
        recipient.erc20Amount = amount;
        recipients[_beamCounter.current()] = recipient;
        IERC20 token = IERC20(tokenAddr);
        token.approve(recipient.addr, token.balanceOf(address(this)));
        bool success = token.transfer(
            recipient.addr,
            amount == 0 ? token.balanceOf(address(this)) : amount
        );
        require(success, "F");
    }

    function _random() private returns (uint256) {
        _seed = _seed + 1;
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.prevrandao +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        (gasleft() / block.timestamp) +
                        (block.timestamp % _seed) +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );
        return rand;
    }

    function _getRandomRecipient() private returns (Recipient memory) {
        Recipient memory recipient;
        recipient.beamedTokenId =
            (_random() % bigBrainBeings.totalSupply()) +
            1;
        recipient.addr = bigBrainBeings.ownerOf(recipient.beamedTokenId);
        return recipient;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    fallback() external payable {}

    receive() external payable {}
}
