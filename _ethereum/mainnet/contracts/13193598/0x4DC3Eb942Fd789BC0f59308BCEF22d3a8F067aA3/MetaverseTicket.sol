// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Base64.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenURI(address walletAddress) external view returns (string memory tokenURI);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract MetaverseTicket is ERC721Enumerable, ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public constant MAX_CYBERPUNK_ITEMS = 2000;
    uint256 public constant MAX_PARTNER_ITEMS = 500;
    uint256 public constant MAX_PUBLIC_ITEMS = 5277;
    uint256 public constant MAX_TOTAL_ITEMS = MAX_CYBERPUNK_ITEMS + MAX_PARTNER_ITEMS + MAX_PUBLIC_ITEMS;
    uint256 public constant MINT_LIMIT = 25;
    uint256 public constant PRICE = 50000000000000000;
    Counters.Counter private _cyberpunkItemsTracker;
    Counters.Counter private _partnerItemsTracker;
    Counters.Counter private _allItemsTracker;

    //Loot Contract
    address public lootAddress;
    LootInterface lootContract;

    //Cyberpunk 
    address public cyberLootAddress;
    LootInterface cyberLootContract;

    //xLoot 
    address public xLootAddress;
    LootInterface xLootContract;

    //Dope wars 
    address public dopeWarsAddress;
    LootInterface dopeWarsContract;

    //Gear for Punks 
    address public gearAddress;
    LootInterface gearContract;

    //Characters for Punks
    address public charactersAddress;
    LootInterface charactersContract;

    address public multisigAddress;

    string public baseTokenURI;

    mapping(address => uint256) cyberDiscountsRedeemed;
    mapping(address => uint256) partnerDiscountsRedeemed;

    event CreateTicket(uint256 indexed id);
    event ErrorNotHandled(bytes reason);

    constructor(address loot, address cyber, address xLoot, address dopeWars, address gear, address characters, address multisig, string memory baseURI) ERC721("Loot (a Residence Card)", "RESIDENCE") {
        cyberLootAddress = cyber;
        lootAddress = loot;
        xLootAddress = xLoot;
        dopeWarsAddress = dopeWars;
        gearAddress = gear;
        charactersAddress = characters;
        gearContract = LootInterface(gearAddress);
        charactersContract = LootInterface(charactersAddress);
        dopeWarsContract = LootInterface(dopeWarsAddress);
        xLootContract = LootInterface(xLootAddress);
        cyberLootContract = LootInterface(cyber);
        lootContract = LootInterface(loot);
        setMultisig(multisig);
        setBaseURI(baseURI);
        pause(true);
    }
		
    modifier saleIsOpen {
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getPower(uint256 tokenId) public pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(toString(tokenId))));
        uint256 value = rand % 100;
        return value;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), toString(tokenId), "?power=", toString(getPower(tokenId))));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMultisig(address multisig) public onlyOwner {
        multisigAddress = multisig;
    }

    function _totalCyberpunkSupply() internal view returns (uint) {
        return _cyberpunkItemsTracker.current();
    }
    
    function totalCyberpunkSupply() public view returns (uint256) {
        return _totalCyberpunkSupply();
    } 

    function _totalPartnerSupply() internal view returns (uint) {
        return _partnerItemsTracker.current();
    }
    
    function totalPartnerSupply() public view returns (uint256) {
        return _totalPartnerSupply();
    } 
    
    function _totalItemsSupply() internal view returns (uint) {
        return _allItemsTracker.current();
    }
    
    function totalItemsSupply() public view returns (uint256) {
        return _totalItemsSupply();
    } 
    
    function prices(uint256 _count) public view returns (uint256, uint256, uint256, uint256) {
        uint256 cyberLootBalance = cyberLootContract.balanceOf(_msgSender()) - cyberDiscountsRedeemed[_msgSender()];
        uint256 totalPartnerBalance = gearContract.balanceOf(_msgSender()) + charactersContract.balanceOf(_msgSender()) + dopeWarsContract.balanceOf(_msgSender()) + xLootContract.balanceOf(_msgSender()) + lootContract.balanceOf(_msgSender()) - partnerDiscountsRedeemed[_msgSender()];
        uint256 numberOfAvailableCyberDiscounts = 0;
        uint256 numberOfAvailablePartnerDiscounts = 0;
        uint256 numberOfCyberDiscountsToRedeem = 0;
        uint256 numberOfPartnerDiscountsToRedeem = 0;
        if (cyberLootBalance > 0) {
            uint256 discountsLeft = MAX_CYBERPUNK_ITEMS - _cyberpunkItemsTracker.current();
            if (discountsLeft >= cyberLootBalance) {
                numberOfAvailableCyberDiscounts = cyberLootBalance;
            } else {
                numberOfAvailableCyberDiscounts = discountsLeft;
            }
            if (numberOfAvailableCyberDiscounts >= _count) {
                numberOfCyberDiscountsToRedeem = _count;
            } else {
                numberOfCyberDiscountsToRedeem = numberOfAvailableCyberDiscounts;
            }
        }
         if (totalPartnerBalance > 0) {
            uint256 discountsLeft = MAX_PARTNER_ITEMS - _partnerItemsTracker.current();
            if (discountsLeft >= totalPartnerBalance) {
                numberOfAvailablePartnerDiscounts = totalPartnerBalance;
            } else {
                numberOfAvailablePartnerDiscounts = discountsLeft;
            }
            if (numberOfAvailablePartnerDiscounts >= _count) {
                numberOfPartnerDiscountsToRedeem = _count;
            } else {
                numberOfPartnerDiscountsToRedeem = numberOfAvailablePartnerDiscounts;
            }
        }
        uint256 countToPay = _count;
        // prevent negative numbers
        if (countToPay > numberOfCyberDiscountsToRedeem) {
            countToPay -= numberOfCyberDiscountsToRedeem;
        }
        if (countToPay > numberOfPartnerDiscountsToRedeem) {
            countToPay -= numberOfPartnerDiscountsToRedeem;
        }

        uint256 priceToPay; 
        if (countToPay > 0) {
            priceToPay = (PRICE).mul(countToPay);
        } else {
            priceToPay = 0;
        }
        return (numberOfCyberDiscountsToRedeem, numberOfPartnerDiscountsToRedeem, countToPay, priceToPay);
    }
    
    function mint(uint256 _count) public payable nonReentrant saleIsOpen {
        uint total = _totalItemsSupply();
        require(total + _count <= MAX_TOTAL_ITEMS, "Max sale limit reached");
        require(total <= MAX_TOTAL_ITEMS, "Sale end");
        require(_count <= MINT_LIMIT, "Exceeds single transaction mint limit");
        (uint256 numberOfCyberDiscountsToRedeem, 
        uint256 numberOfPartnerDiscountsToRedeem, 
        uint256 countToPay,
        uint256 priceToPay) = prices(_count);
       
        if (_msgSender() != owner()) {
            require(msg.value >= priceToPay, "Value below required price");
        }

        for (uint256 i = 0; i < numberOfCyberDiscountsToRedeem; i++) {
            _cyberpunkItemsTracker.increment();
            _mintAnElement();
        }
        cyberDiscountsRedeemed[_msgSender()] += numberOfCyberDiscountsToRedeem;
        for (uint256 i = 0; i < numberOfPartnerDiscountsToRedeem; i++) {
            _partnerItemsTracker.increment();
            _mintAnElement();
        }
        partnerDiscountsRedeemed[_msgSender()] += numberOfPartnerDiscountsToRedeem;
        for (uint256 i = 0; i < countToPay; i++) {
            _mintAnElement();
        }
    }

    function _mintAnElement() private {
        uint id = _totalItemsSupply();
        _allItemsTracker.increment();
        _safeMint(_msgSender(), id);
        emit CreateTicket(id);
    }
    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(multisigAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function contains (string memory what, string memory where) internal pure returns (bool) {
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);

        bool found = false;
        for (uint i = 0; i < whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return found;
    }
 
}
