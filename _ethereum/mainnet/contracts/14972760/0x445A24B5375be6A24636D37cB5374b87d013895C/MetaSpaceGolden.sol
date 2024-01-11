// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721A.sol";

contract MetaSpace is ERC721A, Ownable {
    enum Status {
        Ready,
        Pre1Sale,
        Pre2Sale,
        Pre3Sale,
        PubSale,
        MetaSale,
        SoldOut
    }
    Status public status;
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 10;
    uint256 public constant MAX_SUPPLY = 88;
    uint256 public constant OGPRICE = 0; // 0 ETH    00000000000000000
    uint256 public constant PRE1PRICE = 0.3 * 10**18; // 0.3 ETH    300000000000000000
    uint256 public constant PRE2PRICE = 0.4 * 10**18; // 0.4 ETH    400000000000000000
    uint256 public constant PRE3PRICE = 0.5 * 10**18; // 0.5 ETH    500000000000000000
    uint256 public constant PubPRICE = 0.5 * 10**18; // 0.5 ETH    500000000000000000
    uint256 public metaPrice = 0.5 * 10**18;

    address[] public ogList;
    address[] public wlList;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event MetaPriceChanged(uint256 price);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("MetaSpace Golden NFT", "MetaGolden") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(tx.origin == msg.sender, "no permission");
        require(status == Status.Pre1Sale || status == Status.Pre2Sale || status == Status.Pre3Sale || status == Status.PubSale || status == Status.MetaSale, "not start");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "sold out"
        );

        uint256 mintprice;
        if(status == Status.Pre1Sale) {
            mintprice = PRE1PRICE;
        }else if (status == Status.Pre2Sale) {
            mintprice = PRE2PRICE;
        }else if (status == Status.Pre3Sale) {
            mintprice = PRE3PRICE;
        }else if (status == Status.PubSale){
            mintprice = PubPRICE;
        }else {
            mintprice = metaPrice;
        }

        if (isOG(msg.sender) == true) {
            require(numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,"more than limit");
            if (numberMinted(msg.sender) == 0) {
                refundIfOver(OGPRICE + mintprice * (quantity-1));
            } else {
                refundIfOver(mintprice * quantity);
            }
            _safeMint(msg.sender, quantity);
            emit Minted(msg.sender, quantity);
        }else {
            require(numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,"more than limit");
            refundIfOver(mintprice * quantity);
            _safeMint(msg.sender, quantity);
            emit Minted(msg.sender, quantity);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "not enough eth");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isOG(address _user) public view returns (bool) {
        for (uint i = 0; i < ogList.length; i++) {
            if (ogList[i] == _user) {
            return true;
            }
        }
        return false;
    }

    function setOGList(address[] calldata _users) external onlyOwner {
        delete ogList;
        ogList = _users;
    }

    function isWL(address _user) public view returns (bool) {
        for (uint i = 0; i < wlList.length; i++) {
            if (wlList[i] == _user) {
            return true;
            }
        }
        return false;
    }

    function setWLList(address[] calldata _users) external onlyOwner {
        delete wlList;
        wlList = _users;
    }

    function setMetaPrice(uint256 price) external onlyOwner {
        metaPrice = price;
        emit MetaPriceChanged(price);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "withdrawal success");
    }
}
