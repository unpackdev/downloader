// Creative Lab
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Bifi is ERC721A, Ownable, ReentrancyGuard {
    uint public constant MAX_SUPPLY = 3000;
    uint public constant MAX_PER_WALLET = 2;
    bool public live = false;
    //team reserve
    uint public constant amountForDevs = 30;
    string public baseURI = "ipfs://QmahwwiixZX2ftBduZXuBD3KXRysVrRuhaG8njYuturRV9/";

    struct tokenSpec {
        uint tokenId;
    }

    constructor() ERC721A("Build it Fix it", "BIFI") {
        _mint(msg.sender, 1);
    }

    function getTokenList(address user)
        external
        view
        returns (tokenSpec[] memory)
    {
        uint counter;
        uint balance = balanceOf(user);
        tokenSpec[] memory nftList = new tokenSpec[](balance);

        for (uint i = _startTokenId(); i < _startTokenId() + _totalMinted(); ++i) {
            address _owner = _ownershipOf(i).addr;
            if (_owner == user) {
                tokenSpec memory tk = nftList[counter];
                tk.tokenId = i;
                counter++;
            }
        }

        return nftList;
    }

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    function mint(uint amt) external nonReentrant {
        require(live, "Sale is closed!");
        require(tx.origin == msg.sender, "no bot");
        require(MAX_SUPPLY >= _totalMinted() + amt, "Exceeds max supply");
        require(amt > 0 ,"Cant be 0");
        require(_numberMinted(msg.sender) + amt <= MAX_PER_WALLET,"Not more than 2!");
        _mint(msg.sender, amt);
    }

    // For marketing etc.
    function devMint(uint quantity) external onlyOwner {
        require(MAX_SUPPLY >= _totalMinted() + quantity, "Exceeds max supply"); 
        require(_numberMinted(msg.sender) + quantity <= amountForDevs, "Reached dev mint supply.");
        uint batchMintAmount = quantity > 10 ? 10 : quantity;
        uint numChunks = quantity / batchMintAmount;
        for (uint i = 0; i < numChunks; ++i) {
            _mint(msg.sender, batchMintAmount);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "failed");
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setLive(bool _live) external onlyOwner {
        live = _live;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "token not exist");
        return string(abi.encodePacked(baseURI,_toString(_tokenId),".json"));
    }
}