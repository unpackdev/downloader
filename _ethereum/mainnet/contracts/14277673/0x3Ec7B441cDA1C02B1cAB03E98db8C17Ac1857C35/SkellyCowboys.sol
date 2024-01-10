// SPDX-License-Identifier: UNLICENSED

/*

                                                                                                  
 ,---.  ,--.          ,--.,--.              ,-----.                  ,--.                         
'   .-' |  |,-. ,---. |  ||  |,--. ,--.    '  .--./ ,---. ,--.   ,--.|  |-.  ,---.,--. ,--.,---.  
`.  `-. |     /| .-. :|  ||  | \  '  /     |  |    | .-. ||  |.'.|  || .-. '| .-. |\  '  /(  .-'  
.-'    ||  \  \\   --.|  ||  |  \   '      '  '--'\' '-' '|   .'.   || `-' |' '-' ' \   ' .-'  `) 
`-----' `--'`--'`----'`--'`--'.-'  /        `-----' `---' '--'   '--' `---'  `---'.-'  /  `----'  
                              `---'                                               `---'           

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SkellyCowboys is ERC721A, Ownable {

    bool public saleEnabled;
    bool public presaleEnabled;

    uint256 public price;
    string public metadataBaseURL;
    string public PROVENANCE;

    uint256 public constant PRIVATE_SUPPLY= 100;
    uint256 public constant PRESALE_SUPPLY = 400;
    uint256 public constant PUBLIC_SUPPLY = 500;
    uint256 public constant MAX_SUPPLY = PRESALE_SUPPLY + PUBLIC_SUPPLY + PRIVATE_SUPPLY;

    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    uint256 public constant PRESALE_PURCHASE_LIMIT = 5;

    constructor() ERC721A("Skelly Cowboys", "SLCB",1000) {
        saleEnabled = false;
        price = 0.08 ether;
    }

    // Pre-Sale Functions
    function presalePurchasedCount(address addr) public view returns (uint256) {
        return presalerListPurchases[addr];
    }

    function isPresaler(address addr) public view returns (bool) {
        return presalerList[addr];
    }

    function togglePresaleStatus() public onlyOwner {
        presaleEnabled = !(presaleEnabled);
    }

    function addToPresaleList(address[] calldata entries) public onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }   
    }
    
    function removeFromPresaleList(address[] calldata entries) public onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
            presalerList[entry] = false;
        }
    }

    function presaleMint(uint256 numOfTokens) external payable {
        require(!saleEnabled && presaleEnabled, "Presale is Closed.");
        require(presalerList[msg.sender], "Not on the presale list.");
        require(presalerListPurchases[msg.sender] + numOfTokens <= PRESALE_PURCHASE_LIMIT, "Exceeded allocated amount.");
        require(totalSupply() + numOfTokens <= PRESALE_SUPPLY, "Exceed max supply");
        require(numOfTokens > 0, "Must mint at least 1 token");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );
        presalerListPurchases[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }


    // Other funcions

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
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
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, numOfTokens);
    }
}
