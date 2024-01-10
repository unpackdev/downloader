//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// PLEASE READ - https://medium.com/@kreamcheezbot/the-self-destruct-experiment-an-erc-721a-tale
// THIS NFT WILL SELF DESTRUCT WHEN BOOM IS CALLED.
// TO CALL BOOM, YOU MUST PASS 19.98 ETH, THE PRICE OF ALL NFTS.
// YOU WILL LOSE ALL OF YOUR NFTS. MINT AT YOUR OWN RISK.

// ========================================================= //
//            ██████╗░░█████╗░░█████╗░███╗░░░███╗            //
//            ██╔══██╗██╔══██╗██╔══██╗████╗░████║            //
//            ██████╦╝██║░░██║██║░░██║██╔████╔██║            //
//            ██╔══██╗██║░░██║██║░░██║██║╚██╔╝██║            //
//            ██████╦╝╚█████╔╝╚█████╔╝██║░╚═╝░██║            //
//            ╚═════╝░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝            //
// ========================================================= //

// @author https://twitter.com/kreamcheez

import "./console.sol";

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Boomers is ERC721A, ReentrancyGuard, Ownable {
    uint256 public immutable maxPerAddressDuringMint = 3;
    string private _baseTokenURI;
    address private _deployer;
    uint256 private _boomCost = 19.98 ether;
    uint public startAt;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A("Boomers", "Boomers", maxBatchSize_, collectionSize_) Ownable() {
        startAt = block.number;
    }

     
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier notNull(uint256 quantity) {
        require(quantity > 0, "You can't mint 0 dummy.");
        _;
    }


    function freeMint(uint256 quantity) public nonReentrant callerIsUser notNull(quantity) {
        require(
            totalSupply() + quantity <= 500,
            "Aight we minted out the free shit. Chill."
        );
        require(
            quantity <= maxBatchSize,
            "Stop minting too many, greedy fuck."
        );
        _safeMint(_msgSender(), quantity);
    }

    function mint(uint256 quantity) public nonReentrant callerIsUser payable notNull(quantity) {
        require(
            msg.value >= ( quantity * .02 ether ),
            "Send more ETH bruh."
        );
        require(
            totalSupply() + quantity <= 1499,
            "Aight we minted out. Chill."
        );
        require(
            quantity <= maxBatchSize,
            "Stop minting too many, greedy fuck."
        );
        _safeMint(_msgSender(), quantity);
    }

    function getPrice() public view returns (uint) {
        uint blocksPassed = block.number - startAt;
        uint additionalPrice = blocksPassed / 5760;
        uint priceToEther = additionalPrice * 1000000000000000000;
        return _boomCost + priceToEther;
    }

    function boom() external callerIsUser payable {
        require(totalSupply() >= 1499, "We aint ready to explode yet!");
        require(msg.value >= getPrice(), "You aint send me enough money you poor fuck");
        selfdestruct(payable(owner()));
    }
    
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}

// PLEASE READ - https://medium.com/@kreamcheezbot/the-self-destruct-experiment-an-erc-721a-tale
// THIS NFT WILL SELF DESTRUCT WHEN BOOM IS CALLED.
// TO CALL BOOM, YOU MUST PASS 19.98 ETH, THE PRICE OF ALL NFTS.
// YOU WILL LOSE ALL OF YOUR NFTS. MINT AT YOUR OWN RISK.