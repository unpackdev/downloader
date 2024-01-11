//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract RockyInu is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string private baseURI;

    // withdraw addresses
    address t1 = 0x320ac5aC0d821Ec18417013caD8737537Fc98Ae5;
    address t2 = 0xD921ed7aEcC68353831f943893BaCe3380FeDF34;

    bool public revealed = false;
    uint64 public cost = 0.04 ether;
    uint64 public maxSupply = 5555;
    uint256 public maxMintWhitelisted = 100;
    uint256 public maxMintNormalSale = 100;
    bool public paused = false;

    bool public normalSaleIsActive = false;
    bool public whitelistSaleIsActive = false;

    mapping(address => uint256) private _isWhiteListed;

    //Constructor
    constructor(string memory _metadataURI) ERC721A("Rocky Inu", "ROCKY") {
        setBaseURI(_metadataURI);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function reserveNFT(uint256 _num) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _num <= maxSupply);
        _safeMint(msg.sender, _num);
    }

    function setWhiteList(
        address[] calldata addresses,
        uint256 _numAllowedToMint
    ) external onlyOwner {
        maxMintWhitelisted = _numAllowedToMint;
        for (uint256 i = 0; i < addresses.length; i++) {
            _isWhiteListed[addresses[i]] = _numAllowedToMint;
        }
    }

    function mintNFT(uint256 _mintNum) public payable {
        uint256 supply = totalSupply();
        require(
            whitelistSaleIsActive || normalSaleIsActive,
            "not ready for sale"
        );
        uint64 mintingcost = cost;
        require(!paused, "Another Transaction in Progress");
        require(supply + _mintNum <= maxSupply, "Supply Limit Reached");
        if (msg.sender != owner()) {
            //general public
            require(msg.value >= mintingcost * _mintNum, "Not Enough Tokens");
        } else {
            mintingcost = 0;
        }
        if (normalSaleIsActive) {
            require(
                balanceOf(msg.sender) + _mintNum <= maxMintNormalSale,
                "Mint limit reached \n You cannot mint anymore tokenss"
            );
            _safeMint(msg.sender, _mintNum);
        } else if (whitelistSaleIsActive) {
            require(
                _isWhiteListed[msg.sender] != 0,
                "User not allowed to mint tokens"
            );
            require(
                balanceOf(msg.sender) + _mintNum <= _isWhiteListed[msg.sender],
                "Mint limit reached \n You cannot mint anymore tokenss"
            );
            _safeMint(msg.sender, _mintNum);
        }

        transferEth();
    }

    function giveAway(address _user, uint256 _mintNum) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _mintNum <= maxSupply);
        _safeMint(_user, _mintNum);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non Existent Token");
        string memory currentBaseURI = _baseURI();
        if (revealed) {
            return (
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            tokenId.toString(),
                            ".json"
                        )
                    )
                    : ""
            );
        } else {
            return
                bytes(currentBaseURI).length > 0
                    ? string(abi.encodePacked(currentBaseURI, "Hidden.json"))
                    : "";
        }
    }

    function transferEth() public payable {
        uint256 _t1pay = ((address(this).balance) * 25) / 100;
        uint256 _t2pay = ((address(this).balance) * 75) / 100;
        (bool success1, ) = payable(t1).call{value: _t1pay}("");
        (bool success2, ) = payable(t2).call{value: _t2pay}("");
        require(success2, "Failed to Send Ether");
        require(success1, "Failed to Send Ether");
    }

    fallback() external payable {}

    receive() external payable {}

    //only owner

    function setcost(uint64 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxSupply(uint64 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setNormalSale(bool _state) public onlyOwner {
        normalSaleIsActive = _state;
    }

    function setWhiteListSale(bool _state) public onlyOwner {
        whitelistSaleIsActive = _state;
    }

    function setmaxMintWhitelisted(uint128 _num) public onlyOwner {
        maxMintWhitelisted = _num;
    }

    function setmaxNormalMint(uint128 _num) public onlyOwner {
        maxMintNormalSale = _num;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }
}
