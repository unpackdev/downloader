// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Counters.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./ERC721.sol";
import "./ERC721Burnable.sol";

contract WrapLp is ERC721Burnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    struct NFTDetails {
        address erc20address; //Address of LP token contract
        uint256 amount; // amount lp tokens staked
        uint256 block; //block the nft was minted at
    }

    mapping(uint256 => NFTDetails) private nftDetails;

    // total staked per token address
    mapping(address => uint256) public totalStaked;

    constructor(string memory baseURI_) public ERC721("WRAPLP", "WRAPLP") {
        _setBaseURI(baseURI_);
    }

    function getNFTInfo(uint256 _nftId)
        public
        view
        returns (
            address _erc20address,
            uint256 _amount,
            uint256 _block
        )
    {
        NFTDetails storage nft = nftDetails[_nftId];
        _erc20address = nft.erc20address;
        _amount = nft.amount;
        _block = nft.block;
    }

    // deposit LP tokens and get NFT representation
    function deposit(address erc20address, uint256 amount) external {
        // deposit lp tokens into contract
        IERC20(erc20address).safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );

        nftDetails[_tokenIdTracker.current()] = NFTDetails(
            erc20address,
            amount,
            block.number
        );

        totalStaked[erc20address] = totalStaked[erc20address].add(amount);

        _mint(msg.sender, _tokenIdTracker.current());

        _tokenIdTracker.increment();
    }

    // instead of a withdraw() func we're overriding the burn function from NFTs.
    // This is to avoid people executing the burn function and making the LP tokens stuck in the contract.
    function burn(uint256 tokenId) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );

        NFTDetails storage nft = nftDetails[tokenId];

        totalStaked[nft.erc20address] = totalStaked[nft.erc20address].sub(
            nft.amount
        );

        // Send lp tokens to user
        IERC20(nft.erc20address).transfer(msg.sender, nft.amount);

        // delete data
        delete nftDetails[tokenId];
        _burn(tokenId);
    }
}
