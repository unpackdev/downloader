// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Counters.sol";

//             ____
//      _,-ddd888888bbb-._
//    d88888888888888888888b
//  d888888888888888888888888b      $$$$$$\   $$$$$$\   $$$$$$\
// 6888888888888888888888888889    $$  __$$\ $$  __$$\ $$  __$$\
// 68888b8""8q8888888p8""8d88889   $$ /  \__|$$ /  \__|$$ /  \__|
// `d8887     p88888q     4888b'   $$ |      $$ |      \$$$$$$\
//  `d8887    p88888q    4888b'    $$ |      $$ |       \____$$\
//    `d887   p88888q   488b'      $$ |  $$\ $$ |  $$\ $$\   $$ |
//      `d8bod8888888dob8b'        \$$$$$$  |\$$$$$$  |\$$$$$$  |
//        `d88888888888d'           \______/  \______/  \______/
//          `d8888888b' hjw
//            `d8888b' `97
//              `bd'

contract CCSNFTMint is IERC721Receiver, Ownable {
    using Counters for Counters.Counter;

    NFTContract _nftContract;
    address _nftContractAddy;
    Counters.Counter private _tokenIdCounter;

    constructor(address initNftContract) {
        setNftContract(initNftContract);
        _nftContractAddy = initNftContract;
        for (uint256 i = 1; i <= 635; i++) {
            _tokenIdCounter.increment();
        }
    }

    function setNftContract(address contractAddress) public onlyOwner {
        _nftContract = NFTContract(contractAddress);
        _nftContractAddy = contractAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function executeMint(uint256 numberOfMints) internal {
        for (uint256 l = 1; l <= numberOfMints; l++) {
            for (uint256 i = _tokenIdCounter.current(); i <= 4000; i++) {
                if (ERC721(_nftContractAddy).ownerOf(i) == address(this)) {
                    ERC721(_nftContractAddy).safeTransferFrom(
                        address(this),
                        msg.sender,
                        i
                    );
                    _tokenIdCounter.increment();
                    break;
                } else {
                    _tokenIdCounter.increment();
                }
            }
        }
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO_BALANCE");
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawAllNfts() external onlyOwner {
        for (uint256 i = _tokenIdCounter.current(); i <= 4000; i++) {
            if (ERC721(_nftContractAddy).ownerOf(i) == address(this)) {
                ERC721(_nftContractAddy).safeTransferFrom(
                    address(this),
                    msg.sender,
                    i
                );
            } else {
                break;
            }
        }
    }

    receive() external payable {
        require(_nftContract.totalSupply() < 4000, "SOLD_OUT");
        require(msg.value >= .01 ether, "INSUFFICIENT_FUNDS");
        executeMint(msg.value / .01 ether);
    }
}

interface NFTContract {
    function totalSupply() external view returns (uint256);
}
