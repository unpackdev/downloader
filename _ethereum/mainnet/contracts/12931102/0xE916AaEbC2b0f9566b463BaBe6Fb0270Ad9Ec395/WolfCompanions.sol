pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./AccessControl.sol";

interface WolfGang is IERC721 {
    function tokensOfOwner(address _owner) external view returns(uint[] memory);
}

contract WolfPups is ERC721, AccessControl {
    using SafeMath for uint;

    uint public constant MAX_PUPS = 10000;

    uint public price;
    bool public hasSaleStarted = false;

    address firstAccountAddress;
    address secondAccountAddress;
    address[] _owners;

    WolfGang _wolfGangContract;
    mapping(uint => bool) _claimedWolves;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }

    constructor(string memory baseURI, address _firstAccountAddress, address _secondAccountAddress) ERC721("The WolfGang Pups", "WOLFPUP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setBaseURI(baseURI);
        _wolfGangContract = WolfGang(0x88c2b948749b13aBC1e0AE4B50ebeb2131D283C1);
        price = 0.03 ether;
        firstAccountAddress = _firstAccountAddress;
        secondAccountAddress = _secondAccountAddress;
    }

    function mint(uint quantity) public payable {
        mint(quantity, msg.sender);
    }
    
    function mint(uint quantity, address receiver) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX_PUPS, "sold out");
        require(msg.value >= price.mul(quantity) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ether value sent is below the price");
        
        if (msg.value > 0) {
            payable(firstAccountAddress).transfer(msg.value.mul(40).div(100));
            payable(secondAccountAddress).transfer(msg.value.mul(60).div(100));
        }
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(receiver, totalSupply());
        }
    }

    function claim() public {
        claim(msg.sender);
    }

    function claim(address owner) public {
        uint quantity = _totalUnclaimedPupsOfOwner(owner);
        require(quantity > 0, "owner does not have unclaimed pups");

        for (uint i = 0; i < quantity; i++) {
            _safeMint(owner, totalSupply());
        }
    }

    function _totalUnclaimedPupsOfOwner(address owner) internal returns (uint) {
        uint[] memory wolvesOfOwner = _wolfGangContract.tokensOfOwner(owner);
        uint totalWolvesOfOwner = _wolfGangContract.balanceOf(owner);

        uint unclaimedWolves = 0;
        uint index;
        for(index = 0; index < totalWolvesOfOwner; index++) {
            if (wolvesOfOwner[index] < 4000 && _claimedWolves[wolvesOfOwner[index]] == false) {
                unclaimedWolves++;
                _claimedWolves[wolvesOfOwner[index]] = true;
            }
        }

        return unclaimedWolves == 0 ? 0 : (unclaimedWolves / 5) + 2;
    }

    function totalUnclaimedPupsOfOwner(address owner) public view returns (uint) {
        uint[] memory wolvesOfOwner = _wolfGangContract.tokensOfOwner(owner);
        uint totalWolvesOfOwner = _wolfGangContract.balanceOf(owner);

        uint unclaimedWolves = 0;
        uint index;
        for(index = 0; index < totalWolvesOfOwner; index++) {
            if (wolvesOfOwner[index] < 4000 && _claimedWolves[wolvesOfOwner[index]] == false) {
                unclaimedWolves++;
            }
        }

        return unclaimedWolves == 0 ? 0 : (unclaimedWolves / 5) + 2;
    }
    
    function tokensOfOwner(address _owner) public view returns(uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _setBaseURI(baseURI);
    }
    
    function setPrice(uint _price) public onlyAdmin {
        price = _price;
    }
    
    function startSale() public onlyAdmin {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyAdmin {
        hasSaleStarted = false;
    }

    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeAdmin(address account) public virtual onlyAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, account);
    }
}