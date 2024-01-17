// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./IBurnableERC721.sol";
import "./IGenesisNFT.sol";
import "./SafeOwnable.sol";
import "./Verifier.sol";

contract GenesisFreeMint is SafeOwnable, Verifier {
    
    event Draw(address user, IBurnableERC721 burnNFT, uint burnNftId, uint newNftId);

    IBurnableERC721 public immutable ticketNFT;
    IGenesisNFT public immutable genesisNFT;
    uint public immutable MAX_MINT_NUM;
    uint public immutable MAX_RESERVE_NUM;
    uint public totalMintNum;
    uint public immutable startAt;
    uint public immutable finishAt;

    constructor(
        IGenesisNFT _genesisNFT,
        address _verifier,
        uint _startAt,
        uint _finishAt
    ) Verifier(_verifier) {
        require(address(_genesisNFT) != address(0), "illegal genesisNft");
        genesisNFT = _genesisNFT;
        ticketNFT = IBurnableERC721(address(_genesisNFT.ticketNFT()));
        MAX_MINT_NUM = _genesisNFT.MAX_MINT_NUM();
        MAX_RESERVE_NUM = _genesisNFT.MAX_RESERVE_NUM();
        require(_startAt > block.timestamp && _finishAt > _startAt, "illegal time");
        startAt = _startAt;
        finishAt = _finishAt;
    }

    modifier AlreadyBegin() {
        require(block.timestamp >= startAt, "not begin");
        _;
    }
    
    modifier NotFinish() {
        require(block.timestamp <= finishAt, "already finish");
        _;
    }
    function draw(uint _luckyNftId, uint _totalNum, uint8 _v, bytes32 _r, bytes32 _s) external AlreadyBegin NotFinish {
        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(address(this), msg.sender, _luckyNftId, _totalNum)))), _v, _r, _s) == verifier,
            "verify failed"
        );
        if (genesisNFT.mintedNum() < MAX_MINT_NUM) {
            ticketNFT.transferFrom(msg.sender, address(this), _luckyNftId);
            ticketNFT.approve(address(genesisNFT), _luckyNftId);
            genesisNFT.draw(_luckyNftId, MAX_MINT_NUM, _v, _r, _s);
            genesisNFT.transferFrom(address(this), msg.sender, genesisNFT.totalSupply());
        } else if (genesisNFT.reservedNum() < MAX_RESERVE_NUM) {
            uint userNum = genesisNFT.userReserved(msg.sender);
            require(ticketNFT.ownerOf(_luckyNftId) == msg.sender, "illegal user");
            ticketNFT.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _luckyNftId);
            genesisNFT.reserve(msg.sender, userNum + 1, _v, _r, _s);

        } else {
            revert("already full");
        }
        totalMintNum += 1;
        emit Draw(msg.sender, ticketNFT, _luckyNftId, genesisNFT.totalSupply());
    }
}
