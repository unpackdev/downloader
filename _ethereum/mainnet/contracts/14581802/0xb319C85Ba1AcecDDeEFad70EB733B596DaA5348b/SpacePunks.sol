// SPDX-License-Identifier: UNLICENSED

/*


 ______     ______   __  __     __   __     __  __     ______    
/\  ___\   /\  == \ /\ \/\ \   /\ "-.\ \   /\ \/ /    /\  ___\   
\ \___  \  \ \  _-/ \ \ \_\ \  \ \ \-.  \  \ \  _"-.  \ \___  \  
 \/\_____\  \ \_\    \ \_____\  \ \_\\"\_\  \ \_\ \_\  \/\_____\ 
  \/_____/   \/_/     \/_____/   \/_/ \/_/   \/_/\/_/   \/_____/ 
                                                                                                                                                                          

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SpacePunks is ERC721A, Ownable {
    bool public saleEnabled;
    string public metadataBaseURL;

    uint256 public MAX_TXN = 1;
    uint256 public constant MAX_SUPPLY = 1111;

    mapping(address => uint256) public purchaseList;

    constructor(string memory metadataBaseURL_) ERC721A("SpacePunks", "SPunks", MAX_SUPPLY) {
        metadataBaseURL = metadataBaseURL_;
        saleEnabled = false;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
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
        require(purchaseList[msg.sender]+numOfTokens <= 3, "3 per wallet limit.");
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(numOfTokens > 0, "Must mint at least 1 token");
        require(numOfTokens <= MAX_TXN, "Cant mint more than 1");

        purchaseList[msg.sender] = purchaseList[msg.sender]+numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }

}