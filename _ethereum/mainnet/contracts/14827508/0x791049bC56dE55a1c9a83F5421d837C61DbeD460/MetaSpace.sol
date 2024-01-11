// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721A.sol";

contract MetaSpace is ERC721A, Ownable {
    enum Status {
        Ready,
        PreSale,
        PubSale,
        SoldOut
    }
    Status public status;
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 2;
    uint256 public constant MAX_OG_MINT_PER_ADDR = 3;
    uint256 public constant MAX_SUPPLY = 888;
    uint256 public constant OGPRICE = 0; // 0 ETH    00000000000000000
    uint256 public constant WLPRICE = 0.04 * 10**18; // 0.04 ETH    10000000000000000
    uint256 public constant PubPRICE = 0.05 * 10**18; // 0.05 ETH    20000000000000000

    address[] public ogList;
    address[] public wlList;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("MetaSpace", "MSpace") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(tx.origin == msg.sender, "no permission");
        require(status == Status.PreSale || status == Status.PubSale , "not start");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "sold out"
        );

        if (status == Status.PreSale) {
            require(isOG(msg.sender) == true || isWL(msg.sender) == true , "not in ogList or wlList");
        }

        if (isOG(msg.sender) == true) {
            require(numberMinted(msg.sender) + quantity <= MAX_OG_MINT_PER_ADDR,"more than OG limit");
            if (numberMinted(msg.sender) == 0) {
                refundIfOver(OGPRICE + WLPRICE * (quantity-1));
            } else {
                refundIfOver(WLPRICE * quantity);
            }
            _safeMint(msg.sender, quantity);
            emit Minted(msg.sender, quantity);
        } else if (isWL(msg.sender) == true) {
            require(numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,"more than limit");
            refundIfOver(WLPRICE * quantity);
            _safeMint(msg.sender, quantity);
            emit Minted(msg.sender, quantity);
        } else {
            require(numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,"more than limit");
            refundIfOver(PubPRICE * quantity);
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
