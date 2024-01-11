// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NFTFTF is ERC721A, Ownable {
    /* ========== VARIABLES ========== */

    string public baseURI = "";
    string public contractURI_ = "";
    string public constant fuckingExtension = ".json";

    uint256 public constant MAX_PER_FUCKING_TX = 5;
    uint256 public constant MAX_FUCKING_SUPPLY = 6969;

    uint256 public fuckingPrice = 0 ether;

    bool public crettt = true;
    bool public wheresTheFuckingART = true;

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory baseURI_) ERC721A("For The F*cker", "NFTFTF") {
        baseURI = baseURI_;
        _safeMint(msg.sender, 1);
    }

    /* ========== OWNER FUNCTIONS ========== */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send");
    }

    function cumCrettt() external onlyOwner {
        crettt = !crettt;
    }

    function revealTheFuckingARTTT() external onlyOwner {
        wheresTheFuckingART = !wheresTheFuckingART;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI_ = _contractURI;
    }

    function setFuckingPrice(uint256 price_) external onlyOwner {
        fuckingPrice = price_;
    }

    /* ========== PUBLIC READ FUNCTIONS ========== */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Whatcchuuu tryna do???");
        return
            wheresTheFuckingART ? baseURI : bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        _toString(tokenId),
                        fuckingExtension
                    )
                )
                : "";
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    /* ========== PUBLIC MUTATIVE FUNCTIONS ========== */

    function mint(uint256 amount) external payable {
        address caller_ = msg.sender;
        require(!crettt, "Staphhhhh");
        require(amount > 0, "Whatchhuu trynna do???");

        require(totalSupply() + amount <= MAX_FUCKING_SUPPLY, "meh");

        require(amount <= MAX_PER_FUCKING_TX, "Holdd your sleeveee");
        require(msg.value >= amount * fuckingPrice);

        _safeMint(caller_, amount);
    }
}
