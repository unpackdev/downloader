// SPDX-License-Identifier: UNLICENSED

/*

   ___             __                    ____    _                    __ __                  __  _______     __ 
  / _ | ___  ___ _/ /____  __ _  __ __  / __/___(_)__ ___  _______   / //_/__ ___  ___  ___ / / / ___/ /_ __/ / 
 / __ |/ _ \/ _ `/ __/ _ \/  ' \/ // / _\ \/ __/ / -_) _ \/ __/ -_) / ,< / -_) _ \/ _ \/ -_) / / /__/ / // / _ \
/_/ |_/_//_/\_,_/\__/\___/_/_/_/\_, / /___/\__/_/\__/_//_/\__/\__/ /_/|_|\__/_//_/_//_/\__/_/  \___/_/\_,_/_.__/
                               /___/                                                                                                                                                                                     

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract AnatomyScienceKennelClub is ERC721A, Ownable {
    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;
    string public PROVENANCE;

    uint256 public MAX_TXN = 20;
    uint256 public MAX_TXN_FREE = 3;
    uint256 public constant FREE_SUPPLY = 1000;
    uint256 public constant PAID_SUPPLY = 5000;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY+PAID_SUPPLY;

    constructor() ERC721A("Anatomy Science Kennel Club", "ASKC", MAX_TXN) {
        saleEnabled = false;
        price = 0.022 ether;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        MAX_TXN = _maxTxn;
    }
    function setMaxTxnFree(uint256 _maxTxnFree) external onlyOwner {
        MAX_TXN_FREE = _maxTxnFree;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(numOfTokens > 0, "Must mint at least 1 token");
        require(numOfTokens <= MAX_TXN, "Cant mint more than 20");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, numOfTokens);
    }

    function freeMint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= FREE_SUPPLY, "Exceed max supply");
        require(numOfTokens <= MAX_TXN_FREE, "Cant mint more than 3");
        require(numOfTokens > 0, "Must mint at least 1 token");

        _safeMint(msg.sender, numOfTokens);
    }
}