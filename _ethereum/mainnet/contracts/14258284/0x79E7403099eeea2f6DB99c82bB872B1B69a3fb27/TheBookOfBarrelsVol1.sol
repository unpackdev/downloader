// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

//
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░▒▒▒▓▒▒▒▒░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░▒▒▒▒▒▓▓▒▒▒▒▒▓▒▒▒▒░░░░░░░░░░░░░▒▒▒░░▒▒▒▒░░░▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒░▒▒▒░░░░▒▒░░▒▒▒▒▒▒▒░░▒▒▒▒▓▓▓▒░░▒▒▒▒▒▒▒░░░░░▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒░░▒▒▒▒▓▓▓░░▒▒▒▒░░░░░▒▒▒▓▓▓▒▒░░░░
//░░▒▓▓▓▓▓▓▓▓▓▓▒▓▓▒▒▒▒▒▒░░░░░░░░░░▓▓▓▓▒░▒▓▓▓░░▒▓▓▓▓▓░░▓▓▓▓▓▓▓▓▓░▓▓▓▒░░▒▓▓▒▒▓▓▒▒▒▓▓▓░▒▓▓▒▒▒▒░░▒▓▓▒▒▒▓▓▓░░░░▓▓▓▓▓▒░░░▒▓▓▒▒▒▓▓▓░▓▓▓▒▒▒▓▓▒░▓▓▓▒▒▒▒░░▓▓▓▒░░░░▒▓▓▓▒▒▒▒░░░░░
//░░░░░░░▒▒░▒▓▓▓▓▒▒▒▒▒░▒▒░░░░░░░░░▓▓▓▓▓▒▒▓▓▒░░▓▓▓▒▓▓▓░░░▒▓▓▒░░░░▓▓▓▒░░░▓▓▒▒▓▓▒░▒▓▓▓░▒▓▓▓▒▒▒░░▒▓▓▒▒▒▓▓▒░░░▒▓▓▒▓▓▓▒░░▒▓▓░░▒▓▓▒░▓▓▒░░▒▓▓▒░▓▓▓▒▒▒░░░▓▓▓▒░░░░▒▓▓▓▓▒▒▒▒▒░░░
//░░░░░░░░░░░░▒▓▓▓▓▒▒▒▒▒▓░░░░░░░░░▓▓▓▒▓▓▓▓▓▒░▒▓▓▒▒▒▓▓▒░░▒▓▓▒░░░░▓▓▓▒░░▒▓▓▒▒▓▓▓▓▓▓▒░░░▓▓▓▒▒▒░░▒▓▓▓▒▒▓▓▓▒░░▓▓▓▒▒▓▓▓░░▒▓▓▓▓▓▓▒░░▓▓▓▓▓▓▓▒░░▓▓▓▒▒▒░░░▒▓▓▒░░░░░░░▒▒▒▒▓▓▓▒░░
//░░░░░░░░░░░░▒▓▓▓▓▓▓▒▒░░░░░░░░░░░▓▓▓▒░▒▓▓▓▒░▓▓▓▒▒▒▓▓▓▒░▒▓▓▒░░░░▒▓▓▓▓▒▓▓▒░▒▓▓▓▒▒▓▓▒░░▓▓▓▒▒▒▒░▒▓▓▓░▒▒▓▓▓▒▒▓▓▓▒▒▓▓▓▒░▒▓▓▒▒▓▓▓▒░▓▓▓▒▒▓▓▓▒░▒▓▓▒▒▒▒▒░▒▓▓▒▒▒▒░░▒▒▒▒▒▒▓▓▓▒░░
//░░░░░░░░░░░░░▒░░▒█▓▓░░░░░░░░░░░░▒▓▓▒░░▒▓▓░▒▓▓▒░░░▒▓▓▓░▒▓▓▒░░░░░▒▓▓▓▓▓▒░░░▓▓▓░░▒▓▓▒░▓▓▓▓▓▓▓▒░▓▓▓▓▓▓▒▒░░▓▓▓░░░░▓▓▓▒▒▓▓▒░░▓▓▒░▒▓▓▒░▒▓▓▒░▒▓▓▓▓▓▓▒░▒▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▒▒░░░
//░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░S░░░░░░░░░░░I░░░░░░░░░░░░░G░░░░░░░░░░░░░N░░░░░░░░░░░░░O░░░░░░░░░░░░░R░░░░░░░░░░░░░░C░░░░░░░░░░░░░R░░░░░░░░░░░░░Y░░░░░░░░░░░░░P░░░░░░░░░░░░░T░░░░░░░░░░░░░O░░░░

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TheBookOfBarrelsVol1 is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Smart contract status
    enum MintStatus {
        CLOSED,
        PUBLIC
    }

    MintStatus public status = MintStatus.CLOSED;

    // ERC721 params
    string private _name = "TheBookOfBarrelsVol1";
    string private _symbol = "BoB1";
    string private _baseTokenURI =
        "https://barrels.naturebarrels.com/api/metadata/";

    uint256 public available = 0;

    // Collection params
    uint256 public TOTAL_SUPPLY = 50;
    uint256 public PRICE = 0.12 ether;
    uint256[2] public MAX_PER_STATUS = [0, 2];
    uint256 public _tokenId = 0;

    // Event declaration
    event MintEvent(uint256 indexed id, address mintAddress);
    event ChangedStatusEvent(uint256 newStatus);
    event ChangedAvailable(uint256 available);
    event ChangedBaseURIEvent(string newURI);

    // Modifier to check claiming requirements
    modifier qtyValidation(uint256 _qty) {
        uint256 total = totalSupply();

        require(status != MintStatus.CLOSED, "Minting is closed");
        require(_qty > 0, "NFTs amount must be greater than zero");
        require(
            _qty <= MAX_PER_STATUS[uint256(status)],
            "Exceeded the max amount of mintable NFTs"
        );
        require(total < TOTAL_SUPPLY, "Collection is sold out");
        require(
            (_qty <= available) && (total + _qty <= TOTAL_SUPPLY),
            "Not enough NFTs available"
        );
        require(msg.value == PRICE * _qty, "Ether sent is not correct");
        _;
    }

    // Constructor
    constructor() ERC721(_name, _symbol) {}

    function publicMint(uint256 _qty)
        external
        payable
        nonReentrant
        qtyValidation(_qty)
    {
        available -= _qty;

        for (uint256 i = 1; i <= _qty; i++) {
            _tokenId++;
            _safeMint(msg.sender, _tokenId);
            emit MintEvent(_tokenId, msg.sender);
        }
    }

    // Getters
    function tokenExists(uint256 _id) public view returns (bool) {
        return _exists(_id);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getStatus()
        external
        view
        returns (
            string memory status_,
            uint256 qty_,
            uint256 price_,
            string memory msg_,
            uint256 available_,
            uint256 batchAvailable_
        )
    {
        uint256 total_supply = totalSupply();
        uint256 public_supply = TOTAL_SUPPLY - total_supply;
        uint256 max_mintable = MAX_PER_STATUS[uint256(status)];

        if (available < max_mintable) {
            max_mintable = available;
        }

        if (public_supply <= 0) {
            return ("SOLD OUT", 0, PRICE, "Sold out", 0, 0);
        }

        if (status == MintStatus.CLOSED) {
            return (
                "CLOSED",
                MAX_PER_STATUS[uint256(status)],
                PRICE,
                "Minting is closed",
                public_supply,
                available
            );
        } else if (available == 0) {
            return (
                "SOLD OUT",
                0,
                PRICE,
                "Weekly barrels sold out",
                public_supply,
                available
            );
        } else {
            return (
                "PUBLIC",
                max_mintable,
                PRICE,
                "Public sale",
                public_supply,
                available
            );
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Setters
    function setStatus(uint8 _status) external onlyOwner {
        // _status -> 0: CLOSED, 1:  PUBLIC
        require(
            _status >= 0 && _status <= 1,
            "Mint status must be between 0 and 1"
        );
        status = MintStatus(_status);
        emit ChangedStatusEvent(_status);
    }

    function setAvailable(uint256 _available) external onlyOwner {
        uint256 total_supply = totalSupply();
        uint256 public_supply = TOTAL_SUPPLY - total_supply;

        _available = available + _available;

        require(
            _available <= public_supply,
            "Cannot set available greater than max supply"
        );

        available = _available;
        emit ChangedAvailable(_available);
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        _baseTokenURI = _URI;
        emit ChangedBaseURIEvent(_URI);
    }

    // Withdraw function
    function withdrawAll(address payable withdraw_address)
        external
        payable
        nonReentrant
        onlyOwner
    {
        require(
            withdraw_address != address(0),
            "Withdraw address cannot be zero"
        );
        require(address(this).balance != 0, "Balance is zero");
        payable(withdraw_address).transfer(address(this).balance);
    }
}

//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒░▒▒▒▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒░░▒▒▒▒░░░░░░░▒▒▒▒▒░░░░░░░░░░
//░░░░░░░░░░░░░░░░▒▒▒▒░░░▒▒▒▒░░░░░▒▒▒▒▒▒░░░░░▒▒▒░░▒▒▒▒▒░▒▒▒▒░░▒▒▒▒▒░▒▒▒▒▒▒▒▒▒░▒▒▒▒░░░░░░░░░░░░░░▒▒▒▒░░▒▒▒▒░░░░░▒▒▒▒▒▒▒░░░░▒▒▒▒░▒▒▒▒▒▒░▒▒▒░░▒▒▒▒▒░▒▒▒▒▒▒▒▒▒░░▒▒▒▒░░░░░░░▒▒▒▒▒░░░░░░░░░░
//░░░░░░░░░░░░░░░░▒▒▒▒░░▒▒▒▒░░░░░▒▒▒▒▒▒▒▒░░░░▒▒▒░░░▒▒▒▒░▒▒▒▒░░░▒▒▒▒░▒▒▒░░░░░░░▒▒▒▒░░░░░░░░░░░░░░▒▒▒▒░▒▒▒▒░░░░░░▒▒▒▒▒▒▒░░░░▒▒▒░░░▒▒▒▒▒░▒▒▒░░░▒▒▒▒░░▒▒▒░░░░░░░▒▒▒▒░░░░░░░▒▒▒▒░░░░░░░░░░░
//░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒░░▒▒▒▒░░░▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒░░░▒▒▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒░▒▒▒▒░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒░░░▒▒▒▒░░░░░░░▒▒▒▒░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░▒▒▒▒░░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒░░░▒▒▒▒░▒▒▒▒░░░▒▒▒▒░░░░░░░▒▒▒░░░░░░░░░░░░░░▒▒▒▒░░░▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒░▒▒▒░░░░▒▒▒▒▒▒▒▒░░░░▒▒▒░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒░░▒▒▒▒░░▒▒▒▒░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒░░▒▒▒░░░▒▒▒▒░░▒▒▒░░░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒░▒▒▒▒░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒░░░░░▒▒▒▒░░░░░▒▒▒░░▒▒▒░░░▒▒▒░░░▒▒▒░░░▒▒▒░░░▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒░░░░░░░░░░▒▒▒▒▒▒░░░░░░▒▒▒░░░░░▒▒▒░░▒▒▒▒░░░▒▒▒░░▒▒▒░░░░▒▒▒░░▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒░░▒▒▒░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░S░░░░░░░░░░░I░░░░░░░░░░░░░G░░░░░░░░░░░░░N░░░░░░░░░░░░░O░░░░░░░░░░░░░R░░░░░░░░░░░░░░C░░░░░░░░░░░░░R░░░░░░░░░░░░░Y░░░░░░░░░░░░░P░░░░░░░░░░░░░T░░░░░░░░░░░░░O░░░░░░░░░░░░░░
