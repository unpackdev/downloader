// SPDX-License-Identifier: MIT

/*
           )              
        ( /(           )  
        )\())       ( /(  
  (    ((_)\    (   )\()) 
  )\ )   ((_)   )\ ((_)\  
 _(_/(  / _ \  ((_)| |(_) 
| ' \))| (_) |/ _ \| '_ \ 
|_||_|  \___/ \___/|_.__/ 
                           
website: https://gmverse.studio/nOob                        
*/

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract nOob is ERC721A, Ownable, ReentrancyGuard {
    uint256 public immutable amountForTeam;
    uint256 public immutable totalMintable;

    uint256 public startTime;
    uint256 public endTime;

    uint64 public immutable unitPrice = 0.05 ether;

    string private _baseTokenURI;

    modifier isCallerAUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isPublicMint() {
        assert(block.timestamp >= startTime && block.timestamp < endTime);
        _;
    }

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForTeam_
    ) ERC721A("nOob", "nOob", maxBatchSize_, collectionSize_) {
        totalMintable = collectionSize_;
        amountForTeam = amountForTeam_;
    }

    function setPublicMintTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    function publicMint(uint256 quantity)
        external
        payable
        isCallerAUser
        isPublicMint
    {
        require(
            totalSupply() + quantity <= totalMintable,
            "All tokens are minted."
        );
        require(msg.value >= unitPrice * quantity, "Need to send more ETH.");
        _safeMint(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // owners only

    function airdrop(address[] memory addresses) external onlyOwner {
        require(
            totalSupply() + addresses.length <= totalMintable,
            "All tokens are minted."
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function teamMint(address[] memory addresses, uint256[] memory amount)
        external
        onlyOwner
    {
        require(
            addresses.length == amount.length,
            "addresses does not match amount length"
        );

        uint256 totalToMint = 0;
        for (uint256 i = 0; i < amount.length; i++) {
            totalToMint += amount[i];
        }

        require(
            totalSupply() + totalToMint <= totalMintable,
            "All tokens are minted."
        );

        require(totalToMint <= amountForTeam, "Quantity to mint is too high.");

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amount[i]);
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function withdrawEth() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
