//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

/*

 ▄▄▄       ██▓     ██▓▓█████  ███▄    █     ██▓███   █    ██  ███▄    █  ██ ▄█▀
▒████▄    ▓██▒    ▓██▒▓█   ▀  ██ ▀█   █    ▓██░  ██▒ ██  ▓██▒ ██ ▀█   █  ██▄█▒ 
▒██  ▀█▄  ▒██░    ▒██▒▒███   ▓██  ▀█ ██▒   ▓██░ ██▓▒▓██  ▒██░▓██  ▀█ ██▒▓███▄░ 
░██▄▄▄▄██ ▒██░    ░██░▒▓█  ▄ ▓██▒  ▐▌██▒   ▒██▄█▓▒ ▒▓▓█  ░██░▓██▒  ▐▌██▒▓██ █▄ 
 ▓█   ▓██▒░██████▒░██░░▒████▒▒██░   ▓██░   ▒██▒ ░  ░▒▒█████▓ ▒██░   ▓██░▒██▒ █▄
 ▒▒   ▓▒█░░ ▒░▓  ░░▓  ░░ ▒░ ░░ ▒░   ▒ ▒    ▒▓▒░ ░  ░░▒▓▒ ▒ ▒ ░ ▒░   ▒ ▒ ▒ ▒▒ ▓▒
  ▒   ▒▒ ░░ ░ ▒  ░ ▒ ░ ░ ░  ░░ ░░   ░ ▒░   ░▒ ░     ░░▒░ ░ ░ ░ ░░   ░ ▒░░ ░▒ ▒░
  ░   ▒     ░ ░    ▒ ░   ░      ░   ░ ░    ░░        ░░░ ░ ░    ░   ░ ░ ░ ░░ ░ 
      ░  ░    ░  ░ ░     ░  ░         ░                ░              ░ ░  ░   
                                                                               

                  ██████  ▄▄▄       ██▓      ██████  ▄▄▄      
                ▒██    ▒ ▒████▄    ▓██▒    ▒██    ▒ ▒████▄    
                ░ ▓██▄   ▒██  ▀█▄  ▒██░    ░ ▓██▄   ▒██  ▀█▄  
                  ▒   ██▒░██▄▄▄▄██ ▒██░      ▒   ██▒░██▄▄▄▄██ 
                ▒██████▒▒ ▓█   ▓██▒░██████▒▒██████▒▒ ▓█   ▓██▒
                ▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░░ ▒░▓  ░▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░
                ░ ░▒  ░ ░  ▒   ▒▒ ░░ ░ ▒  ░░ ░▒  ░ ░  ▒   ▒▒ ░
                ░  ░  ░    ░   ▒     ░ ░   ░  ░  ░    ░   ▒   
                      ░        ░  ░    ░  ░      ░        ░  ░


This is an Alien Punk Things $DROOL collab with artist Lost Salsa and programmer Computer.
It pays hommage to the amazing Alien Punk Things collection created by Greeni and Computer.

Lost Salsa: https://twitter.com/Lost_Salsa
Greeni: https://twitter.com/olioctopus1
Computer: https://twitter.com/ComputerCrypto

*/

abstract contract AlienPunkThings {
    function ownerOf(uint256 tokenId) public virtual returns (address);
}

abstract contract DROOL {
    function balanceOf(address account) public view virtual returns (uint256);
    function burnFrom(address _from, uint256 _amount) external virtual;
}

abstract contract DroolRewards {
    mapping(uint256 => address) public stakedAssets;
}

contract AlienPunkSalsa is ERC721A, Ownable, PaymentSplitter {

    DroolRewards private immutable droolRewards;
    AlienPunkThings private immutable apt;
    DROOL private immutable drool;

    bool public randomIsActive = false;
    bool public salsafyIsActive = false;
    string public contractURI = "";

    uint256 private _salsafiedPrice = 303 ether; // DROOL
    uint256 private _randomizedPrice = 0.01 ether;
    uint256 private _txnLimit = 11 + 1;
    uint256 private _collectionSize = 3333 + 1;
    string public baseURI = "";

    mapping(uint => bool) public salsafied;

    event Salsafied(uint256 id, uint aptId);
    event MultipleSalsafied(uint256 startId, uint[] aptIds);
    event Randomized(uint256 startId, uint quantity);

    address[] private addressList = [
        0x0cFb73E9d86129Ec7a5C202c0c0E6f1026b85ddc,
        0xB0F546C91A7D2545e3755af99E06A6C9aBe03bCf
    ];
    
    uint[] private shareList = [
        50,
        50
    ];

    constructor(address _apt, address _drool, address _droolRewards) 
        ERC721A("AlienPunkSalsa", "SALSA")
        PaymentSplitter(addressList, shareList) {
        apt = AlienPunkThings(_apt);
        drool = DROOL(_drool);
        droolRewards = DroolRewards(_droolRewards);
    }

    function mintRandomized(uint256 quantity) external payable {
        uint256 totalMinted = _totalMinted();
        require(randomIsActive, "Sale is not active");
        require(quantity > 0, "Must be more than 0");
        require(quantity < _txnLimit, "Over transaction limit");
        require(totalMinted + quantity < _collectionSize, "Over collection limit");
        require(_randomizedPrice * quantity == msg.value, "Incorrect ETH Amount");

        _safeMint(msg.sender, quantity);

        emit Randomized(totalMinted, quantity);
    }

    function mintMultipleSalsafied(uint256[] calldata aptIds) external {
        uint256 quantity = aptIds.length;
        uint256 totalMinted = _totalMinted();
        require(salsafyIsActive, "Salsafy is not active");
        require(totalMinted + quantity < _collectionSize, "Over collection limit");
        require(quantity < _txnLimit, "Over transaction limit");
        require(quantity > 0, "Invalid quantity");
        
        for(uint x; x < aptIds.length; x++) {
            uint aptId = aptIds[x];
            require(!salsafied[aptId], "Already Salsafied");
            require(apt.ownerOf(aptId) == msg.sender || droolRewards.stakedAssets(aptId) == msg.sender, "You do not own this Alien Punk Thing");
            salsafied[aptId] = true;
        }

        if(_salsafiedPrice > 0) {
            drool.burnFrom(msg.sender, quantity * _salsafiedPrice);
        }
        
        _safeMint(msg.sender, quantity);

        emit MultipleSalsafied(totalMinted, aptIds);
    }

    function mintSalsafied(uint256 aptId, bool staked) external {
        uint256 totalMinted = _totalMinted();
        require(salsafyIsActive, "Salsafy is not active");
        require(totalMinted + 1 < _collectionSize, "Over collection limit");
        if(staked) {
            require(droolRewards.stakedAssets(aptId) == msg.sender, "You do not own this Alien Punk Thing");
        } else {
            require(apt.ownerOf(aptId) == msg.sender, "You do not own this Alien Punk Thing");
        }
        require(!salsafied[aptId], "This Alien Punk Thing is already salsafied");
        salsafied[aptId] = true;

        if(_salsafiedPrice > 0) {
            drool.burnFrom(msg.sender, _salsafiedPrice);
        }
        
        _safeMint(msg.sender, 1);

        emit Salsafied(totalMinted, aptId);
    }

    function giftRandomized(address addr, uint256 quantity) external onlyOwner {
        uint256 totalMinted = _totalMinted();
        require(quantity > 0, "Must be more than 0");
        require(totalMinted + quantity < _collectionSize, "Over collection limit");

        _safeMint(addr, quantity);

        emit Randomized(totalMinted, quantity);
    }

    function setRandomizedPrice(uint256 price) external onlyOwner {
        _randomizedPrice = price;
    }

    function setSalsafiedPrice(uint256 price) external onlyOwner {
        _salsafiedPrice = price;
    }

    function setTransactionLimit(uint256 limit) external onlyOwner {
        _txnLimit = limit;
    }

    function flipSaleState() external onlyOwner {
        randomIsActive = !randomIsActive;
    }

    function flipSalsafyState() external onlyOwner {
        salsafyIsActive = !salsafyIsActive;
    }

    function setBaseUri(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        ) : "";
    }
}